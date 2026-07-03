#!/usr/bin/env python3
"""Generate CTF desktop wallpaper. Run once: python3 tools/gen-wallpaper.py"""
import struct, zlib, math

W, H = 1920, 1080

def make_png(pixels_fn):
    rows = []
    for y in range(H):
        row = b''
        for x in range(W):
            row += bytes(pixels_fn(x, y))
        rows.append(b'\x00' + row)
    raw = zlib.compress(b''.join(rows), 9)

    def chunk(ct, d):
        c = ct + d
        return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

    data  = b'\x89PNG\r\n\x1a\n'
    data += chunk(b'IHDR', struct.pack('>IIBBBBB', W, H, 8, 2, 0, 0, 0))
    data += chunk(b'IDAT', raw)
    data += chunk(b'IEND', b'')
    return data

def pixel(x, y):
    BG   = (12, 12, 12)
    GRID = (0, 55, 22)
    DOT  = (0, 100, 40)
    GS = 60
    gx, gy = x % GS == 0, y % GS == 0
    # Fade grid near edges for a vignette effect
    ex = min(x, W - x) / (W * 0.15)
    ey = min(y, H - y) / (H * 0.15)
    fade = min(1.0, ex) * min(1.0, ey)
    if gx and gy:
        c = DOT
    elif gx or gy:
        c = GRID
    else:
        c = BG
    return tuple(int(v * fade) for v in c)

data = make_png(pixel)
out = 'wallpaper.png'
with open(out, 'wb') as f:
    f.write(data)
print(f"Generated {out} ({len(data)//1024} KB)")
