"""Smart selection for kitty, like iTerm2 Smart Selection: mark text by regex and open it as a URL.

Used by `map ctrl+shift+p>o kitten hints --customize-processing smart_hints.py` (kitty.conf), on macOS and on Omarchy.
Press the key, then the hint letter shown next to the match. Add your own rules to RULES.
"""
import re

# (regex, function that turns the match into a URL)
RULES = [
    # git@github.com:owner/repo.git -> https://github.com/owner/repo
    (re.compile(r'git@([\w.-]+):([\w.-]+/[\w.-]+?)(?:\.git)?(?=[\s"\'<>)\]]|$)'),
     lambda m: f'https://{m.group(1)}/{m.group(2)}'),
    # ssh://git@host[:port]/owner/repo.git -> https://host/owner/repo
    (re.compile(r'ssh://git@([\w.-]+)(?::\d+)?/([\w.-]+/[\w.-]+?)(?:\.git)?(?=[\s"\'<>)\]]|$)'),
     lambda m: f'https://{m.group(1)}/{m.group(2)}'),
    # owner/repo#123 -> the GitHub issue or pull request (GitHub redirects /issues/N to the pull request)
    (re.compile(r'(?<![\w./-])([A-Za-z0-9](?:[A-Za-z0-9-]*[A-Za-z0-9])?/[\w.-]+)#(\d+)\b'),
     lambda m: f'https://github.com/{m.group(1)}/issues/{m.group(2)}'),
]


def mark(text, args, Mark, extra_cli_args, *a):
    idx = 0
    for pattern, to_url in RULES:
        for m in pattern.finditer(text):
            start, end = m.span()
            yield Mark(idx, start, end, m.group(0), {'url': to_url(m)})
            idx += 1


def handle_result(args, data, target_window_id, boss, extra_cli_args, *a):
    for match, groupdict in zip(data['match'], data['groupdicts']):
        if match and groupdict.get('url'):
            boss.open_url(groupdict['url'])
