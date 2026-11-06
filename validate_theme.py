#!/usr/bin/env python3
"""Sanity-check a GRUB theme folder before installing it.

Catches the mistakes that make GRUB silently drop a theme:
  * pixmap patterns without ".png" (e.g. "select_*" instead of "select_*.png")
  * decimal / non-numeric position values (e.g. "31.5%")
  * missing image files or fonts that theme.txt refers to
  * PNGs GRUB cannot load (not 8-bit RGB/RGBA, or interlaced)
Usage: validate_theme.py THEME_DIR
"""
import glob, os, re, struct, sys

NUMERIC = {'left', 'top', 'width', 'height', 'terminal-left', 'terminal-top', 'terminal-width',
           'terminal-height', 'terminal-border', 'item_height', 'item_padding', 'item_spacing',
           'item_icon_space', 'icon_width', 'icon_height', 'scrollbar_width'}
PATTERN = {'terminal-box', 'menu_pixmap_style', 'item_pixmap_style', 'selected_item_pixmap_style',
           'scrollbar_frame', 'scrollbar_thumb'}
FONTKEYS = {'terminal-font', 'item_font', 'selected_item_font', 'font'}


def read_pf2(path):
    d = open(path, 'rb').read()
    if d[0:4] != b'FILE' or d[8:12] != b'PFF2':
        raise ValueError('not a PFF2 font')
    pos, info = 12, {}
    while True:
        name = d[pos:pos + 4]
        ln = struct.unpack('>I', d[pos + 4:pos + 8])[0]
        pos += 8
        if name == b'DATA':
            break
        info[name] = d[pos:pos + ln]
        pos += ln
        if pos >= len(d):
            raise ValueError('no DATA section')
    chix = info[b'CHIX']
    cps, glyphs = [], {}
    for i in range(len(chix) // 9):
        cp, _, off = struct.unpack('>IBI', chix[i * 9:i * 9 + 9])
        cps.append(cp)
        w, h, xo, yo, dw = struct.unpack('>HHhhh', d[off:off + 10])
        glyphs[cp] = (w, h, xo, yo, dw, d[off + 10:off + 10 + (w * h + 7) // 8])
    if cps != sorted(cps) or len(set(cps)) != len(cps):
        raise ValueError('character index not sorted/unique')
    return dict(name=info[b'NAME'].rstrip(b'\0').decode(), ascent=struct.unpack('>H', info[b'ASCE'])[0],
                descent=struct.unpack('>H', info[b'DESC'])[0], glyphs=glyphs)


def validate(root):
    errs = []
    tpath = os.path.join(root, 'theme.txt')
    if not os.path.isfile(tpath):
        return ['theme.txt not found in ' + root]

    names = {}
    for f in glob.glob(root + '/*.pf2'):
        try:
            names[read_pf2(f)['name']] = f
        except Exception as ex:
            errs.append(f'{os.path.basename(f)}: bad font ({ex})')

    for f in glob.glob(root + '/**/*.png', recursive=True):
        h = open(f, 'rb').read(32)
        ok = h[:8] == b'\x89PNG\r\n\x1a\n'
        if ok:
            _, _, bd, ct, _, _, il = struct.unpack('>IIBBBBB', h[16:29])
            ok = bd == 8 and ct in (2, 6) and il == 0
        if not ok:
            errs.append(f'{os.path.relpath(f, root)}: PNG must be 8-bit RGB/RGBA, non-interlaced')

    depth = 0
    for no, raw in enumerate(open(tpath, encoding='utf-8'), 1):
        line = raw.strip()
        if not line or line.startswith('#'):
            continue
        depth += line.count('{') - line.count('}')
        m = re.match(r'^([A-Za-z_\-]+)\s*[:=]\s*(.*?)\s*$', line)
        if not m:
            continue
        key, val = m.group(1), m.group(2)
        s = val[1:-1] if len(val) >= 2 and val[0] == '"' and val[-1] == '"' else val
        if key in NUMERIC and not re.fullmatch(r'\d+%?', s):
            errs.append(f'theme.txt:{no}: {key} = {val}  (use whole numbers only, e.g. 31% or 44)')
        if key in ('desktop-image', 'file') and not os.path.isfile(os.path.join(root, s)):
            errs.append(f'theme.txt:{no}: missing file {s}')
        if key in PATTERN:
            if '*' not in s or not s.endswith('.png'):
                errs.append(f'theme.txt:{no}: {key} = {val}  (pattern must look like "name_*.png")')
            elif not os.path.isfile(os.path.join(root, s.replace('*', 'c'))):
                errs.append(f'theme.txt:{no}: missing {s.replace("*", "c")}')
        if key in FONTKEYS and s not in names:
            errs.append(f'theme.txt:{no}: font "{s}" not found in any .pf2 (have: {", ".join(sorted(names)) or "none"})')
    if depth != 0:
        errs.append('theme.txt: unbalanced { }')
    return errs


if __name__ == '__main__':
    problems = validate(sys.argv[1])
    for p in problems:
        print('  PROBLEM:', p)
    print('theme OK' if not problems else f'{len(problems)} problem(s) found')
    sys.exit(1 if problems else 0)
