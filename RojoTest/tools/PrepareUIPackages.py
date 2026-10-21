"""Resolve Ripple's Luau string aliases to Roblox Instance requires after wally install."""
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1] / 'Packages/_Index/littensy_ripple@0.10.2/ripple/src'
for path in root.rglob('*.luau'):
    source = path.read_text(encoding='utf-8')
    def rewrite(match):
        value = match.group(1)
        if value.startswith('@self/'):
            target = root / value[6:]
        elif value.startswith('.'):
            target = (path.parent / value).resolve()
        else:
            return match.group(0)
        parts = target.relative_to(root.resolve()).parts
        depth = len(path.relative_to(root).parts) - 1
        base = 'script' + '.Parent' * (depth + (path.stem != 'init'))
        return 'require(' + base + ''.join('["' + p + '"]' for p in parts) + ')'
    updated = re.sub(r'require\("([^"\n]+)"\)', rewrite, source)
    if updated != source:
        path.write_text(updated, encoding='utf-8')
