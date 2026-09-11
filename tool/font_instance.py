#!/usr/bin/env python3
"""Turns the variable NotoSans into the single static cut the PDFs use.

`assets/fonts/NotoSans-Regular.ttf` exists for exactly two things: the
emergency-plan PDF and the missing-equipment PDF. Both build their theme
with `pw.ThemeData.withFont(base: font, bold: font)` -- the same face for
both roles -- so no weight is ever interpolated, and the variable-font
machinery is carried on every platform for nothing.

Measured on the file this replaces:

    gvar  1 245 578 bytes   the glyph variation data
    glyf    326 949
    GPOS    243 810
    ...
    total 2 049 096  ->  646 160 after instancing   (-68.5 %)

and 1 192 794 -> 293 374 bytes once gzipped, which is what a download
actually costs -- about 0.9 MB off each of the five shipped artefacts.

It is lossless for a fixed weight: instancing at the font's own defaults
(wght 400, wdth 100) keeps all 4515 glyphs and all 3094 codepoints and
drops only fvar, gvar, avar, HVAR and MVAR. Checked, not assumed -- see
the assertions below and `font_asset_test.dart`.

Do not "update" the asset by dropping a fresh variable NotoSans in its
place. Run this over it instead.

Usage:
    python3 -m venv /tmp/ft && /tmp/ft/bin/pip install fonttools
    /tmp/ft/bin/python tool/font_instance.py <variable.ttf>
"""

import os
import shutil
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

TARGET = "preppsuite_flutter/assets/fonts/NotoSans-Regular.ttf"

# The axes' own defaults. Named rather than passed in: the PDFs use one
# cut, and a script that can produce a light or condensed asset invites
# producing one by accident.
AXES = {"wght": 400, "wdth": 100}


def main(source: str) -> int:
    variable = TTFont(source)
    if "fvar" not in variable:
        print(f"{source} is already static -- nothing to instance.")
        return 1

    before = {
        "codepoints": set(variable.getBestCmap()),
        "glyphs": variable["maxp"].numGlyphs,
    }

    static = instantiateVariableFont(variable, AXES, updateFontNames=False)

    after = {
        "codepoints": set(static.getBestCmap()),
        "glyphs": static["maxp"].numGlyphs,
    }

    # The whole claim of this script, checked before anything is written.
    lost = before["codepoints"] - after["codepoints"]
    assert not lost, f"instancing lost {len(lost)} codepoints: {sorted(lost)[:20]}"
    assert before["glyphs"] == after["glyphs"], "instancing lost glyphs"

    temporary = TARGET + ".new"
    static.save(temporary)
    shutil.move(temporary, TARGET)

    print(
        f"{os.path.getsize(source)} -> {os.path.getsize(TARGET)} bytes, "
        f"{after['glyphs']} glyphs and {len(after['codepoints'])} codepoints kept"
    )
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        raise SystemExit(2)
    raise SystemExit(main(sys.argv[1]))
