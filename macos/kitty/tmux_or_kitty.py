"""Keys shared by kitty and tmux.

When the pane runs a local tmux client, the key acts on that tmux session. Otherwise it runs the kitty action.
Mapped in iterm2-keys.conf through the `tmux_or` alias:

    map cmd+1 tmux_or window:1 goto_tab 1

The first argument is the tmux operation (see TMUX_OPS). The rest is the kitty action, which can be a combine.
tmux inside ssh is not detected, so there the kitty action runs.
"""
import os
import shutil
import subprocess

from kittens.tui.handler import result_handler

HOME = os.path.expanduser('~')


def main(args: list[str]) -> str:
    return ''


class Client:
    """The tmux client in a kitty pane: how to reach its server, and its session and active pane."""

    def __init__(self, exe: str, socket_args: list[str], session: str, pane: str):
        self.exe, self.socket_args, self.session, self.pane = exe, socket_args, session, pane

    def run(self, *cmd: str) -> str:
        r = subprocess.run([self.exe, *self.socket_args, *cmd], capture_output=True, text=True, timeout=3)
        return r.stdout


def _socket_args(cmdline: list[str]) -> list[str]:
    out, it = [], iter(cmdline[1:])
    for arg in it:
        for flag in ('-L', '-S'):
            if arg == flag:
                out += [flag, next(it, '')]
            elif arg.startswith(flag) and len(arg) > 2:
                out += [flag, arg[2:]]
    return out


def _find_client(window) -> Client | None:
    for proc in window.child.foreground_processes:
        cmdline = proc.get('cmdline') or []
        if not cmdline or os.path.basename(cmdline[0]) != 'tmux':
            continue
        pid = str(proc['pid'])
        ps = subprocess.run(['/bin/ps', '-o', 'tty=,comm=', '-p', pid], capture_output=True, text=True).stdout.split(None, 1)
        if len(ps) != 2:
            continue
        tty, exe = '/dev/' + ps[0].strip(), ps[1].strip()
        if not os.path.isabs(exe):
            exe = shutil.which('tmux', path='/opt/homebrew/bin:/usr/local/bin:/usr/bin') or 'tmux'
        client = Client(exe, _socket_args(cmdline), '', '')
        for line in client.run('list-clients', '-F', '#{client_tty}\t#{session_id}\t#{pane_id}').splitlines():
            fields = line.split('\t')
            if len(fields) == 3 and fields[0] == tty:
                client.session, client.pane = fields[1], fields[2]
                return client
    return None


def _select_window(c: Client, n: str) -> None:
    ids = c.run('list-windows', '-t', c.session, '-F', '#{window_id}').split()
    if n.isdigit() and 1 <= int(n) <= len(ids):
        c.run('select-window', '-t', ids[int(n) - 1])


def _split(c: Client, direction: str) -> None:
    c.run('split-window', direction, '-t', c.pane, '-c', HOME)
    # Spread the panes evenly after a split, like the kitty and iTerm2 behavior.
    c.run('select-layout', '-E', '-t', c.session)


TMUX_OPS = {
    'new_window': lambda c, _: c.run('new-window', '-t', c.session, '-c', HOME),
    'vsplit': lambda c, _: _split(c, '-h'),
    'hsplit': lambda c, _: _split(c, '-v'),
    'zoom': lambda c, _: c.run('resize-pane', '-Z', '-t', c.pane),
    'next_pane': lambda c, _: c.run('select-pane', '-t', f'{c.session}:.+'),
    'prev_pane': lambda c, _: c.run('select-pane', '-t', f'{c.session}:.-'),
    'pane': lambda c, d: c.run('select-pane', {'left': '-L', 'right': '-R', 'up': '-U', 'down': '-D'}[d], '-t', c.pane),
    'next_window': lambda c, _: c.run('next-window', '-t', c.session),
    'prev_window': lambda c, _: c.run('previous-window', '-t', c.session),
    'window': _select_window,
}


@result_handler(no_ui=True)
def handle_result(args: list[str], answer: str, target_window_id: int, boss) -> None:
    op, _, op_arg = args[1].partition(':')
    kitty_action = ' '.join(args[2:])
    window = boss.window_id_map.get(target_window_id) or boss.active_window
    client = _find_client(window) if window is not None else None
    if client is not None and op in TMUX_OPS:
        TMUX_OPS[op](client, op_arg)
    elif kitty_action:
        boss.combine(kitty_action, window)
