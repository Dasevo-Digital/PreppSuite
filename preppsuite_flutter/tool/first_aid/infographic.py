#!/usr/bin/env python3
"""Puts one picture chart beside a first aid guide.

    python3 tool/first_aid/infographic.py <guide-id> <picture.png> [<language>]

Run from preppsuite_flutter/, like the generator beside it.

A chart is one picture with the guide's steps drawn in, made outside this
repository. It carries words, so it belongs to one language (German unless
named), and is written to
`assets/first_aid/<language>/<guide-id>.webp` at its own size, as WebP. The guide then needs `- image: true` in
`content/first_aid/<language>.md`, and `dart run tool/first_aid/generate.dart`.

A chart is a second telling of the guide, and the guide is what was checked
against the guidelines. So before one goes in, every instruction drawn into
it is read against the guide's text: a chart that says anything the text
does not -- a different time, a different position, a "never" the text
allows -- stays out until it is redrawn. Leaving something out is allowed;
the steps are right underneath.

Needs Pillow (`python3 -m pip install --user pillow`).
"""

from pathlib import Path
import re
import sys

from PIL import Image

APP = Path(__file__).resolve().parents[2]
QUALITY = 82


def main():
    if len(sys.argv) not in (3, 4):
        sys.exit(__doc__)
    guide, source = sys.argv[1], Path(sys.argv[2])
    language = sys.argv[3] if len(sys.argv) == 4 else "de"
    content = (APP / "content" / "first_aid" / f"{language}.md").read_text()
    if not re.search(rf"^## {re.escape(guide)}$", content, flags=re.M):
        sys.exit(f"{language}.md has no guide {guide}")
    target = APP / "assets" / "first_aid" / language / f"{guide}.webp"
    target.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(source) as picture:
        picture.convert("RGB").save(target, "WEBP", quality=QUALITY, method=6)
    with Image.open(target) as written:
        print(f"{target.relative_to(APP)}  {written.width}x{written.height}  "
              f"{target.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
