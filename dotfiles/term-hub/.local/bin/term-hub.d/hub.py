#!/usr/bin/env python3
"""Dedicated tmux workspace; moving panes preserves shells and SSH sessions."""
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
from connections import select_connections

SOCKET = os.environ.get('TERM_HUB_SOCKET', 'term-hub')
SESSION = 'term-hub'
PARKED = 'term-hub-parked'
ROOT = Path(__file__).resolve().parent


def tmux(*args, check=True):
    result = subprocess.run(['tmux', '-L', SOCKET, *args], text=True,
                            stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and result.returncode:
        raise RuntimeError(result.stderr.strip())
    # Empty pane metadata is represented by trailing tabs; keep those fields.
    return result.stdout.rstrip('\r\n')


def panes():
    rows = tmux('list-panes', '-t', SESSION, '-F',
                '#{pane_id}\t#{window_id}\t#{@ssh_label}\t#{@ssh_order}').splitlines()
    rows = [row.split('\t') for row in rows]
    next_order = max(int(row[3] or 0) for row in rows) + 1
    for row in rows:
        if not row[3]:
            row[2], row[3] = f'term-{next_order}', str(next_order)
            label(row[0], row[2], next_order)
            next_order += 1
    return sorted(rows,
                  key=lambda row: int(row[3] or 9999))


def restore_parked(window):
    if subprocess.run(
            ['tmux', '-L', SOCKET, 'has-session', '-t', PARKED],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        return
    rows = tmux('list-panes', '-s', '-t', PARKED, '-F',
                '#{pane_id}\t#{@term_hub_home}', check=False).splitlines()
    for row in rows:
        pane, _, home = row.partition('\t')
        if home == window:
            tmux('join-pane', '-d', '-s', pane, '-t', window)
            tmux('set-option', '-pu', '-t', pane, '@term_hub_home', check=False)


def park_extra(window, rows):
    if len(rows) <= 2:
        return
    if subprocess.run(['tmux', '-L', SOCKET, 'has-session', '-t', PARKED],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        tmux('new-session', '-d', '-s', PARKED, '-n', 'storage', 'sleep 2147483647')
    for pane, _, _, _ in rows[2:]:
        tmux('set-option', '-p', '-t', pane, '@term_hub_home', window)
        tmux('join-pane', '-d', '-s', pane, '-t', f'{PARKED}:1')


def label(pane, name, order):
    tmux('set-option', '-p', '-t', pane, '@ssh_label', name)
    tmux('set-option', '-p', '-t', pane, '@ssh_order', str(order))
    tmux('select-pane', '-t', pane, '-T', name)


def layout():
    first = panes()[0][0]
    tmux('set-window-option', '-t', first, 'main-pane-width', '55%')
    tmux('select-layout', '-t', first, 'main-vertical')


def parse_panel_selection(value, count):
    selected = set()
    for part in value.split(','):
        match = re.fullmatch(r'\s*(\d+)\s*(?:-\s*(\d+)\s*)?', part)
        if not match:
            raise ValueError('Use números separados por vírgula ou intervalo: 2,4 ou 2-4.')
        first = int(match[1])
        last = int(match[2]) if match[2] else first
        if not 1 <= first <= last <= count:
            raise ValueError(f'Escolha números de 1 a {count}, em ordem crescente no intervalo.')
        selected.update(range(first, last + 1))
    return sorted(selected)


def close_many():
    current = panes()
    print('FECHAR PAINÉIS\n')
    for number, row in enumerate(current, 1):
        print(f'  {number} · {row[2]}')
    value = input('\nNúmeros ou intervalo (2,4 / 2-4 / Enter cancela): ').strip()
    if not value:
        return
    selected = parse_panel_selection(value, len(current))
    print('\nFechar: ' + ', '.join(f'{number} · {current[number - 1][2]}' for number in selected))
    if input('Os processos desses painéis serão encerrados. Confirmar (y/n)? ').strip().lower() != 'y':
        return
    # Use the stable IDs from the displayed list, not shifting pane numbers.
    for number in selected:
        tmux('kill-pane', '-t', current[number - 1][0], check=False)


def rename_panel(pane):
    current = next((row for row in panes() if row[0] == pane), None)
    if current is None:
        raise ValueError('O painel não está mais aberto.')
    print(f'Nome atual: {current[2]}')
    name = input('Novo nome (Enter cancela): ').strip()
    if not name:
        return
    if len(name) > 64 or any(ord(char) < 32 or ord(char) == 127 for char in name):
        raise ValueError('Use um nome de até 64 caracteres, sem controles.')
    label(pane, name, current[3])
    if tmux('display-message', '-p', '-t', pane, '#{window_panes}') == '1':
        tmux('rename-window', '-t', pane, name)


def move(direction):
    current = panes()
    active = tmux('display-message', '-p', '-t', SESSION, '#{pane_id}')
    index = next(i for i, row in enumerate(current) if row[0] == active)
    destination = index + direction
    if not 0 <= destination < len(current):
        tmux('display-message', 'Este terminal já está no início ou no fim da ordem.')
        return
    other = current[destination]
    command = 'swap-pane' if current[index][1] == other[1] else 'swap-window'
    tmux(command, '-s', active, '-t', other[0])
    tmux('set-option', '-p', '-t', active, '@ssh_order', other[3])
    tmux('set-option', '-p', '-t', other[0], '@ssh_order', current[index][3])
    tmux('select-window', '-t', active)
    tmux('select-pane', '-t', active)


def mode(wanted):
    if wanted not in ('Tab', 'Multi', 'Tiling', '1:2'):
        raise ValueError('Modo inválido')
    active = tmux('display-message', '-p', '-t', SESSION, '#{pane_id}')
    window = tmux('display-message', '-p', '-t', active, '#{window_id}')
    if tmux('display-message', '-p', '-t', window, '#{window_zoomed_flag}') == '1':
        tmux('resize-pane', '-Z', '-t', window)
    restore_parked(window)
    current = panes()
    if wanted == '1:2':
        if active not in [row[0] for row in current[:2]]:
            active = current[0][0]
        park_extra(window, current)
        tmux('select-layout', '-t', window, 'even-horizontal')
    elif wanted == 'Tiling':
        tmux('select-layout', '-t', window, 'tiled')
    elif wanted == 'Multi':
        layout()
    elif len(current) > 1:
        tmux('resize-pane', '-Z', '-t', active)
    tmux('set-option', '-w', '-t', window, '@term_hub_mode', wanted)
    tmux('select-window', '-t', active)
    tmux('select-pane', '-t', active)
    tmux('refresh-client', '-S', check=False)


def new_terminal(target=None, saved_alias=None):
    if target and (target.startswith('-') or not re.fullmatch(r'[A-Za-z0-9_.@:%\[\]-]+', target)):
        raise ValueError('Informe um alias SSH ou usuario@host, sem opções adicionais.')
    window = tmux('display-message', '-p', '-t', SESSION, '#{window_id}')
    wanted = tmux('show-options', '-w', '-v', '-t', window, '@term_hub_mode', check=False) or 'Multi'
    if tmux('display-message', '-p', '-t', window, '#{window_zoomed_flag}') == '1':
        tmux('resize-pane', '-Z', '-t', window)
    restore_parked(window)
    current = panes()
    order = max(int(row[3] or 0) for row in current) + 1
    name = saved_alias or target or f'term-{order}'
    args = ['split-window', '-d', '-P', '-F', '#{pane_id}', '-t', window]
    if saved_alias:
        command = shlex.join(['python3', str(ROOT / 'connections.py'), 'open', saved_alias])
        args += [f'{command}; exec "$SHELL" -l']
    elif target:
        args += [f'ssh -- {shlex.quote(target)}; exec "$SHELL" -l']
    pane = tmux(*args)
    label(pane, name, order)
    tmux('select-pane', '-t', pane)
    mode(wanted)
    return pane


def new_group(select=True):
    pane = tmux('new-window', '-d', '-P', '-F', '#{pane_id}', '-t', SESSION,
                '-n', 'Terminais', '-c', str(Path.home()))
    label(pane, 'term-1', 1)
    tmux('set-option', '-w', '-t', pane, '@term_hub_mode', 'Multi')
    if select:
        tmux('select-window', '-t', pane)
    return pane


GENERAL_LOGS = ('install', 'scripts', 'downloads')


def distro_logs():
    excluded = {f'ff-{name}.log' for name in GENERAL_LOGS}
    return sorted(path for path in Path('/tmp').glob('ff-*.log')
                  if path.is_file() and path.name not in excluded)


def monitor_sessions():
    # The hub uses a private socket; ff and ffd must use tmux's default server.
    env = os.environ.copy()
    env.pop('TMUX', None)

    def default_tmux(*args, check=True):
        result = subprocess.run(['tmux', *args], env=env, text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if check and result.returncode:
            raise RuntimeError(result.stderr.strip())
        return result

    def ensure_session(name, first_name, first_command):
        if default_tmux('has-session', '-t', f'={name}', check=False).returncode:
            default_tmux('new-session', '-d', '-s', name, '-n', first_name, first_command)
            return True
        return False

    general = [Path('/tmp') / f'ff-{name}.log' for name in GENERAL_LOGS]
    for path in general:
        if not path.exists():
            path.touch()
    ensure_session('ff', 'install', shlex.join(['tail', '-f', str(general[0])]))
    existing = set(default_tmux('list-windows', '-t', '=ff', '-F', '#{window_name}').stdout.splitlines())
    for name, path in zip(GENERAL_LOGS[1:], general[1:]):
        if name not in existing:
            default_tmux('new-window', '-d', '-t', 'ff:', '-n', name,
                         shlex.join(['tail', '-f', str(path)]))

    logs = distro_logs()
    if logs:
        first = logs[0]
        ensure_session('ffd', first.stem[3:], shlex.join(['tail', '-f', str(first)]))
    else:
        if ensure_session('ffd', 'aguardando',
                          "printf 'Nenhum /tmp/ff-DISTRO.log encontrado.\\n'; exec tail -f /dev/null"):
            default_tmux('set-window-option', '-t', 'ffd:aguardando', '@ff_hub_waiting', '1')
    existing = set(default_tmux('list-windows', '-t', '=ffd', '-F', '#{window_name}').stdout.splitlines())
    for path in logs:
        name = path.stem[3:]
        if name not in existing:
            default_tmux('new-window', '-d', '-t', 'ffd:', '-n', name,
                         shlex.join(['tail', '-f', str(path)]))
    if logs and 'aguardando' in existing:
        waiting = default_tmux('display-message', '-p', '-t', 'ffd:aguardando',
                               '#{@ff_hub_waiting}\t#{pane_current_command}', check=False).stdout.strip()
        if waiting == '1\ttail':
            default_tmux('kill-window', '-t', 'ffd:aguardando')


def follow_logs(per_distro=False):
    paths = distro_logs() if per_distro else [Path('/tmp') / f'ff-{name}.log' for name in GENERAL_LOGS]
    if not paths:
        raise ValueError('Nenhum log /tmp/ff-DISTRO.log encontrado. Crie um para cada instalação.')
    mode('Tiling')
    current = panes()
    shells = {'bash', 'zsh', 'fish', 'sh', 'dash'}
    selected = [row for row in current
                if tmux('display-message', '-p', '-t', row[0], '#{pane_current_command}') in shells]
    while len(selected) < len(paths):
        pane = new_terminal()
        selected.append(next(row for row in panes() if row[0] == pane))
    monitor_sessions()
    for (pane, _, _, order), path in zip(selected, paths):
        if not path.exists():
            path.touch()
        name = path.stem[3:]
        label(pane, name, order)
        if tmux('display-message', '-p', '-t', pane, '#{window_panes}') == '1':
            tmux('rename-window', '-t', pane, name)
        tmux('send-keys', '-t', pane, shlex.join(['tail', '-f', str(path)]), 'Enter')


def choose_logs():
    from log_picker import select_logs
    paths = select_logs()
    if not paths:
        return
    mode('Tiling')
    for path in paths:
        pane = new_terminal()
        current = next(row for row in panes() if row[0] == pane)
        label(pane, path.stem[3:], current[3])
        tmux('send-keys', '-t', pane, shlex.join(['tail', '-f', str(path)]), 'Enter')


def start(follow=False):
    if subprocess.run(['tmux', '-L', SOCKET, 'has-session', '-t', SESSION],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
        tmux('-f', str(ROOT / 'tmux.conf'), 'new-session', '-d', '-s', SESSION,
             '-n', 'Terminais', '-x', '160', '-y', '42', '-c', str(Path.home()))
        pane = tmux('display-message', '-p', '-t', SESSION, '#{pane_id}')
        label(pane, 'term-1', 1)
        tmux('set-option', '-w', '-t', pane, '@term_hub_mode', 'Multi')
        new_terminal()
        new_terminal()
        new_group(select=False)
        new_group(select=False)
        tmux('select-window', '-t', pane)
        tmux('select-pane', '-t', pane)
    else:
        tmux('source-file', str(ROOT / 'tmux.conf'))
        for row in tmux('list-windows', '-t', SESSION,
                        '-F', '#{window_id}\t#{window_name}').splitlines():
            window, name = row.split('\t', 1)
            if name.lower() == 'servidores':
                tmux('rename-window', '-t', window, 'Terminais')
    if follow:
        follow_logs()
    if sys.stdout.isatty():
        os.execvp('tmux', ['tmux', '-L', SOCKET, 'attach-session', '-t', SESSION])
    print('Sessão pronta. Abra com: term-hub')


if __name__ == '__main__':
    try:
        command = sys.argv[1] if len(sys.argv) > 1 else 'start'
        if command in ('top', 'status'):
            from monitor import main
            main(command)
        elif command in ('start', '--ff', '-ff'):
            start(follow=command in ('--ff', '-ff'))
        elif command == 'follow-logs':
            follow_logs()
        elif command == 'follow-distro-logs':
            follow_logs(per_distro=True)
        elif command == 'choose-logs':
            choose_logs()
        elif command == 'mode':
            mode(sys.argv[2])
        elif command == 'close-many':
            close_many()
        elif command == 'rename':
            rename_panel(sys.argv[2])
        elif command == 'move':
            direction = {'left': -1, 'right': 1}[sys.argv[2]]
            move(direction)
        elif command == 'new':
            new_terminal(sys.argv[2] if len(sys.argv) > 2 else None)
        elif command == 'new-group':
            new_group()
        elif command == 'connect':
            aliases, temporary = select_connections()
            for alias in aliases:
                new_terminal(saved_alias=alias)
            if temporary:
                new_terminal(temporary)
        elif command == 'temporary':
            target = input('SSH temporário (alias ou usuario@host): ').strip()
            if target:
                new_terminal(target)
        else:
            raise ValueError('Comando inválido')
    except (RuntimeError, ValueError, IndexError) as error:
        print(f'term-hub: {error}', file=sys.stderr)
        if sys.stdin.isatty():
            input('Enter para voltar...')
        sys.exit(1)
