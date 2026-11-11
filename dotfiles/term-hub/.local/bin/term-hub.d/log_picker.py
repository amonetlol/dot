"""Interactive picker for the installation and distro logs."""
import curses
from pathlib import Path


def choose(screen, paths):
    curses.curs_set(0)
    screen.keypad(True)
    cursor = 0
    selected = set()
    while True:
        screen.erase()
        height, width = screen.getmaxyx()
        names = ['Todos'] + [path.name for path in paths]
        screen.addnstr(1, 2, 'Logs disponíveis', max(0, width - 4), curses.A_BOLD)
        screen.addnstr(3, 2, '↑ ↓ navegar · Espaço marcar · Enter abrir · q cancelar', max(0, width - 4))
        visible = max(1, height - 8)
        start = max(0, cursor - visible + 1)
        for y, index in enumerate(range(start, min(len(names), start + visible)), 5):
            checked = len(selected) == len(paths) if index == 0 else index - 1 in selected
            screen.addnstr(y, 2, f"({'x' if checked else ' '}) {names[index]}",
                           max(0, width - 4), curses.A_REVERSE if cursor == index else 0)
        screen.refresh()
        key = screen.getch()
        if key in (ord('q'), 27):
            return []
        if key in (curses.KEY_DOWN, ord('j')):
            cursor = (cursor + 1) % len(names)
        elif key in (curses.KEY_UP, ord('k')):
            cursor = (cursor - 1) % len(names)
        elif key == ord(' '):
            if cursor == 0:
                selected = set() if len(selected) == len(paths) else set(range(len(paths)))
            else:
                selected.symmetric_difference_update({cursor - 1})
        elif key in (10, 13, curses.KEY_ENTER) and selected:
            return [paths[index] for index in sorted(selected)]


def select_logs():
    paths = sorted(path for path in Path('/tmp').glob('ff-*.log') if path.is_file())
    if not paths:
        raise ValueError('Nenhum log /tmp/ff-*.log disponível.')
    return curses.wrapper(choose, paths)
