#!/usr/bin/env python3
"""Linux mini-top using procfs only; no extra Python dependencies."""
import curses
import os
from pathlib import Path
import shutil
import socket
import sys
import time
from collections import deque


def snapshot(processes=False):
    cpus = {}
    for line in Path('/proc/stat').read_text().splitlines():
        fields = line.split()
        if fields[0].startswith('cpu'):
            values = list(map(int, fields[1:9]))  # guest time is already in user/nice
            cpus[fields[0]] = (sum(values), values[3] + values[4])
    mem = {}
    for line in Path('/proc/meminfo').read_text().splitlines():
        key, value = line.split(':', 1)
        mem[key] = int(value.split()[0]) * 1024
    net = {}
    for line in Path('/proc/net/dev').read_text().splitlines()[2:]:
        name, counters = line.split(':', 1)
        name = name.strip()
        # Include physical links and VPNs; exclude loopback and virtual bridges.
        if name.startswith(('lo', 'veth', 'docker', 'br-', 'virbr')):
            continue
        fields = counters.split()
        net[name] = (int(fields[0]), int(fields[8]))
    procs = {}
    if processes:
        for path in Path('/proc').glob('[0-9]*/stat'):
            try:
                raw = path.read_text()
                end = raw.rindex(')')
                fields = raw[end + 2:].split()
                procs[int(path.parent.name)] = (
                    raw[raw.index('(') + 1:end], int(fields[11]) + int(fields[12]),
                    int(fields[21]) * os.sysconf('SC_PAGE_SIZE'), fields[19])
            except (OSError, ValueError, IndexError):
                continue  # Process exited or is inaccessible.
    return dict(time=time.monotonic(), cpu=cpus, mem=mem, net=net, procs=procs)


def percent(used, total):
    return max(0, min(100, 100 * used / total)) if total else 0


def metrics(before, now):
    elapsed = max(.001, now['time'] - before['time'])
    cpu = {}
    for name, (total, idle) in now['cpu'].items():
        old_total, old_idle = before['cpu'].get(name, (total, idle))
        cpu[name] = percent(total - old_total - idle + old_idle, total - old_total)
    rates = [sum(max(0, counters[i] - before['net'].get(name, counters)[i])
                 for name, counters in now['net'].items()) / elapsed for i in (0, 1)]
    mem = now['mem']
    used = mem['MemTotal'] - mem.get('MemAvailable', mem.get('MemFree', 0))
    swap = mem['SwapTotal'] - mem['SwapFree']
    disk = shutil.disk_usage('/')
    return dict(cpu=cpu, used=used, ram=percent(used, mem['MemTotal']),
                swap=percent(swap, mem['SwapTotal']), swap_used=swap,
                disk=percent(disk.used, disk.total), disk_free=disk.free, rates=rates)


def size(value):
    for unit in ('B', 'KiB', 'MiB', 'GiB', 'TiB'):
        if abs(value) < 1024 or unit == 'TiB':
            return f'{value:.1f}{unit}'
        value /= 1024


def uptime():
    minutes = int(float(Path('/proc/uptime').read_text().split()[0])) // 60
    days, minutes = divmod(minutes, 1440)
    hours, minutes = divmod(minutes, 60)
    return f'{days}d {hours:02}:{minutes:02}'


def status():
    before = snapshot()
    time.sleep(.2)
    now = snapshot()
    m = metrics(before, now)

    def field(label, value):
        color = '#e78284' if value >= 85 else '#e5c890' if value >= 65 else '#a6d189'
        return f'{label} #[fg={color}]{value:.0f}%#[fg=#a5adce]'

    print(' | '.join((field('CPU', m['cpu']['cpu']), field('RAM', m['ram']),
                       field('SWP', m['swap']), field('/', m['disk']),
                       f"↓{size(m['rates'][0])}/s ↑{size(m['rates'][1])}/s",
                       f'load {os.getloadavg()[0]:.2f}', f'up {uptime()}')))


def dashboard(screen):
    try:
        curses.curs_set(0)
    except curses.error:
        pass
    if curses.has_colors():
        curses.start_color()
        curses.use_default_colors()
        for i, color in enumerate((curses.COLOR_CYAN, curses.COLOR_YELLOW, curses.COLOR_RED), 1):
            curses.init_pair(i, color, -1)
    screen.timeout(100)
    before = snapshot(True)
    history = deque(maxlen=48)
    sort_memory = False
    deadline = time.monotonic() + .3
    while True:
        key = screen.getch()
        if key in (ord('q'), 27):
            return
        if key == ord('m'):
            sort_memory = not sort_memory
            deadline = 0
        if time.monotonic() < deadline:
            continue
        now = snapshot(True)
        m = metrics(before, now)
        history.append(m['cpu']['cpu'])
        screen.erase()
        height, width = screen.getmaxyx()

        def text(y, value, attr=0):
            if 0 <= y < height - 1 and width > 2:
                screen.addnstr(y, 1, value, width - 2, attr)

        def bar(y, label, value, suffix=''):
            count = max(4, min(24, width - 36))
            filled = round(value * count / 100)
            color = 3 if value >= 85 else 2 if value >= 65 else 1
            attr = curses.color_pair(color) if curses.has_colors() else 0
            text(y, f'{label:5} [{"|" * filled}{"." * (count - filled)}] {value:5.1f}% {suffix}', attr)

        text(0, f'TERM HUB / {socket.gethostname()} / monitor local', curses.A_BOLD)
        text(1, f'Up {uptime()}   Load ' + ' / '.join(f'{v:.2f}' for v in os.getloadavg()))
        bar(3, 'CPU', m['cpu']['cpu'])
        bar(4, 'RAM', m['ram'], f"{size(m['used'])}/{size(now['mem']['MemTotal'])}")
        bar(5, 'SWAP', m['swap'], f"{size(m['swap_used'])}/{size(now['mem']['SwapTotal'])}")
        bar(6, '/', m['disk'], f"livre {size(m['disk_free'])}")
        text(8, f"REDE ↓ {size(m['rates'][0])}/s   ↑ {size(m['rates'][1])}/s")
        text(9, 'Interfaces: ' + ', '.join(now['net']))
        text(11, 'CPU histórico: ' + ''.join(' .:-=+*#%@'[min(9, int(v / 10))] for v in history))
        cores = [f'{k[3:]}:{v:.0f}%' for k, v in m['cpu'].items() if k != 'cpu']
        text(12, 'Núcleos ' + ' '.join(cores))
        text(14, '    PID    CPU%       RAM  PROCESSO  (m alterna CPU/RAM)', curses.A_BOLD)
        elapsed = max(.001, now['time'] - before['time'])
        ticks = os.sysconf('SC_CLK_TCK')
        rows = []
        for pid, (name, total, rss, started) in now['procs'].items():
            old = before['procs'].get(pid)
            usage = max(0, total - old[1]) / ticks / elapsed * 100 if old and old[3] == started else 0
            name = ''.join(c if c.isprintable() else '?' for c in name)
            rows.append((usage, rss, pid, name))
        rows.sort(key=lambda row: row[1] if sort_memory else row[0], reverse=True)
        for y, (usage, rss, pid, name) in enumerate(rows[:max(0, height - 18)], 15):
            text(y, f'{pid:7} {usage:7.1f} {size(rss):>9}  {name}')
        text(height - 2, 'q/Esc fechar | m ordenar | atualização 1s | CPU de processo: 100% = 1 núcleo')
        screen.refresh()
        before = now
        deadline = time.monotonic() + 1


def main(command='top'):
    if command == 'status':
        status()
    else:
        try:
            curses.wrapper(dashboard)
        except KeyboardInterrupt:
            pass


if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else 'top')
