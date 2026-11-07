"""Saved SSH entries and a keyboard checkbox picker."""
import curses
import os
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
CONFIG = ROOT / 'ssh.conf'


def load_entries(path=CONFIG):
    entries, current = [], None
    for number, raw in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        if not raw.strip() or raw.lstrip().startswith('#'):
            continue
        match = re.fullmatch(r'\s*(Alias|Hostname|User|Pass)(?:\s*[:=]\s*|\s+)?(.*?)\s*', raw, re.I)
        if not match:
            raise ValueError(f'Linha {number}: use Alias, Hostname, User ou Pass.')
        key, value = match.group(1).lower(), match.group(2)
        if key == 'alias':
            current = {'alias': value, 'hostname': '', 'user': '', 'pass': ''}
            entries.append(current)
        elif current is None:
            raise ValueError(f'Linha {number}: comece o bloco com Alias.')
        else:
            current[key] = value
    active, seen = [], set()
    for entry in entries:
        if not any(entry.values()):
            continue
        alias = entry['alias']
        if not alias or any(ord(char) < 32 or ord(char) == 127 for char in alias):
            raise ValueError('Preencha um Alias válido em cada bloco utilizado.')
        if alias in seen:
            raise ValueError('Há aliases repetidos no arquivo.')
        if not re.fullmatch(r'[A-Za-z0-9_.:%\[\]-]+', entry['hostname']) or entry['hostname'].startswith('-'):
            raise ValueError(f'Hostname inválido no bloco {alias}.')
        if not re.fullmatch(r'[A-Za-z0-9_.-]+', entry['user']):
            raise ValueError(f'User inválido no bloco {alias}.')
        seen.add(alias)
        active.append(entry)
    return active


def choose(screen, entries):
    curses.curs_set(0)
    screen.keypad(True)
    cursor, selected = 0, set()
    names = ['todas'] + [entry['alias'] for entry in entries] + ['temporário']
    fixed = set(range(len(entries)))
    message = ''
    while True:
        screen.erase()
        height, width = screen.getmaxyx()

        def text(y, value, attr=0):
            if 0 <= y < height - 1:
                screen.addnstr(y, 2, value, max(0, width - 4), attr)

        text(1, 'SSH', curses.A_BOLD)
        text(3, '↑ ↓ navegar · Espaço marcar · Enter abrir · q cancelar')
        visible = max(1, height - 10)
        start = max(0, cursor - visible + 1)
        y = 5
        for index in range(start, min(len(names), start + visible)):
            if index == len(entries) + 1:
                text(y, '─' * max(0, width - 6))
                y += 1
            checked = bool(fixed) and fixed <= selected if index == 0 else index - 1 in selected
            marker = '(x)' if checked else '( )'
            text(y, f'{marker} {names[index]}', curses.A_REVERSE if cursor == index else 0)
            y += 1
        text(height - 3, message or f'{len(selected)} selecionado(s)')
        screen.refresh()
        key = screen.getch()
        if key in (ord('q'), 27):
            return None
        if key in (curses.KEY_DOWN, ord('j')):
            cursor = (cursor + 1) % len(names)
        elif key in (curses.KEY_UP, ord('k')):
            cursor = (cursor - 1) % len(names)
        elif key == ord(' '):
            if cursor == 0:
                if fixed <= selected:
                    selected.difference_update(fixed)
                else:
                    selected.update(fixed)
            else:
                selected.symmetric_difference_update({cursor - 1})
            message = ''
        elif key in (10, 13, curses.KEY_ENTER):
            if selected:
                return sorted(selected)
            message = 'Marque pelo menos uma opção com Espaço.'


def select_connections():
    entries = load_entries()
    selected = curses.wrapper(choose, entries)
    if selected is None:
        return [], None
    # Request the temporary destination before opening any selected connection.
    temporary = None
    if len(entries) in selected:
        temporary = input('SSH temporário (alias ou usuario@host; Enter cancela): ').strip() or None
    return [entries[index]['alias'] for index in selected if index < len(entries)], temporary


def run_saved(alias):
    entry = next((item for item in load_entries() if item['alias'] == alias), None)
    if entry is None:
        raise ValueError('Alias não encontrado. Confira o arquivo de SSHs.')
    env = os.environ.copy()
    if entry['pass']:
        env.update(SSH_ASKPASS=str(ROOT / 'ssh-askpass'), SSH_ASKPASS_REQUIRE='force',
                   DISPLAY=env.get('DISPLAY') or ':0', SSH_HUB_ALIAS=alias)
    return subprocess.call(['ssh', '-l', entry['user'], '--', entry['hostname']], env=env)


def askpass():
    prompt = ' '.join(sys.argv[2:]).lower()
    if 'password' not in prompt and 'senha' not in prompt:
        # Keep host-key confirmation, key passphrases and OTP prompts interactive.
        # A TTY cannot seek: use separate read/write streams instead of r+.
        with open('/dev/tty', 'w') as output:
            output.write(' '.join(sys.argv[2:]) + ' ')
            output.flush()
        with open('/dev/tty', 'r') as terminal:
            print(terminal.readline().strip())
        return 0
    alias = os.environ.get('SSH_HUB_ALIAS')
    entry = next((item for item in load_entries() if item['alias'] == alias), None)
    if entry is None:
        return 1
    print(entry['pass'])
    return 0


if __name__ == '__main__':
    try:
        if sys.argv[1] == 'askpass':
            sys.exit(askpass())
        sys.exit(run_saved(sys.argv[2]))
    except (ValueError, OSError) as error:
        print(f'SSH: {error}', file=sys.stderr)
        sys.exit(1)
