#!/usr/bin/env python3
"""Renders the drawings of the Mila und Nuss comic into the app's assets.

The comic is drawn once, in `mila_und_nuss.html` beside this script: one
set of SVG symbols for the cast and the props, and one `<svg>` per panel,
each marked with `data-panel="<id>"`. That file is also the web edition.
The app shows the same drawings as PNGs, because it has no SVG renderer
and the article reader on Linux and Windows has no browser engine to lend
one; the words are set by Flutter, so they follow the text size and the
language.

macOS only: it renders through Quick Look (`qlmanage`), which uses WebKit,
and crops with `sips`. Both ship with the system, so nothing needs
installing. Quick Look scales a thumbnail to its own idea of the aspect
ratio, so every panel is placed in the middle of a square canvas, rendered
square, and cut back to its own height. In the middle because `sips`
crops around the centre whatever offset it is given.

Usage:
    tool/comic/render_panels.py            # all panels
    tool/comic/render_panels.py strom-2    # only these
"""
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
SOURCE = HERE / "mila_und_nuss.html"
OUT = HERE.parent.parent / "preppsuite_flutter" / "assets" / "comic"

# Pixels per drawing unit. A standard panel is 300 units wide, so 900
# pixels: sharp on a phone at three times density across its full width.
SCALE = 3


def panels(html):
    for match in re.finditer(
        r'<svg data-panel="([^"]+)" viewBox="([^"]+)"[^>]*>(.*?)</svg>|'
        r'<figure class="panel(?: wide)?" data-panel="([^"]+)">\s*'
        r'<svg viewBox="([^"]+)"[^>]*>(.*?)</svg>',
        html,
        re.S,
    ):
        if match.group(1):
            yield match.group(1), match.group(2), match.group(3)
        else:
            yield match.group(4), match.group(5), match.group(6)


def main(wanted):
    html = SOURCE.read_text(encoding="utf-8")
    defs = re.search(r"<defs>(.*?)</defs>", html, re.S).group(1)
    OUT.mkdir(parents=True, exist_ok=True)
    done = 0
    with tempfile.TemporaryDirectory() as work:
        work = Path(work)
        for panel_id, view_box, body in panels(html):
            if wanted and panel_id not in wanted:
                continue
            _, _, width, height = (float(v) for v in view_box.split())
            side = max(width, height)
            pixels = int(side * SCALE)
            svg = (
                '<svg xmlns="http://www.w3.org/2000/svg" '
                'xmlns:xlink="http://www.w3.org/1999/xlink" '
                f'viewBox="0 0 {side:g} {side:g}" '
                f'width="{pixels}" height="{pixels}">'
                f"<defs>{defs}</defs>"
                f'<g transform="translate({(side - width) / 2:g} {(side - height) / 2:g})">'
                f"{body}</g></svg>"
            )
            source = work / f"{panel_id}.svg"
            source.write_text(svg, encoding="utf-8")
            subprocess.run(
                ["qlmanage", "-t", "-s", str(pixels), "-o", str(work), str(source)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            rendered = work / f"{panel_id}.svg.png"
            target = OUT / f"{panel_id}.png"
            shutil.move(rendered, target)
            subprocess.run(
                [
                    "sips",
                    "-c", str(int(height * SCALE)), str(int(width * SCALE)),
                    str(target),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
            )
            done += 1
            print(f"{target.relative_to(HERE.parent.parent)}")
    if wanted and done != len(wanted):
        sys.exit(f"FEHLER: {len(wanted) - done} der genannten Bilder gibt es nicht")
    print(f"{done} Bilder")


if __name__ == "__main__":
    main(set(sys.argv[1:]))
