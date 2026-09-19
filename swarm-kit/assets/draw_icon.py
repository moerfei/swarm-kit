# -*- coding: utf-8 -*-
"""swarm-kit icon: honeycomb hexagon + three caste-colored swarm dots (scout/worker/judge)."""
import math, os
from PIL import Image, ImageDraw

OUT = os.path.dirname(os.path.abspath(__file__))

CYAN = (56, 189, 248, 255)    # scout
GREEN = (74, 222, 128, 255)   # worker
RED = (248, 113, 113, 255)    # judge

def hex_pts(cx, cy, r):
    return [(cx + r * math.sin(math.radians(a)), cy - r * math.cos(math.radians(a)))
            for a in range(0, 360, 60)]

def draw(size, bg, hex_stroke, hex_fill, accent):
    S = 2
    W = size * S
    img = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    d.rounded_rectangle([0, 0, W - 1, W - 1], radius=int(W * 0.225), fill=bg)

    cx = cy = W * 0.485                       # leave room top-right for the departing bee
    R = int(W * 0.325)
    stroke = int(W * 0.05)
    cos30 = math.cos(math.radians(30))
    R_in = (R * cos30 - stroke) / cos30       # uniform edge stroke via concentric hexagons
    d.polygon(hex_pts(cx, cy, R), fill=hex_stroke)
    d.polygon(hex_pts(cx, cy, R_in), fill=hex_fill)

    Rd = R * 0.52
    dotR = int(W * 0.105)
    for ang, col in ((-90, CYAN), (150, GREEN), (30, RED)):
        px = cx + Rd * math.cos(math.radians(ang))
        py = cy + Rd * math.sin(math.radians(ang))
        d.ellipse([px - dotR, py - dotR, px + dotR, py + dotR], fill=col)

    # departing scout: small amber bee leaving the hive, top-right
    bx, by = W * 0.845, W * 0.135
    br = int(W * 0.045)
    for k in range(3):                        # fading wake behind it
        wx, wy = W * (0.795 - k * 0.035), W * (0.185 + k * 0.032)
        wr = int(br * (0.42 - k * 0.09))
        d.ellipse([wx - wr, wy - wr, wx + wr, wy + wr], fill=accent[:3] + (150 - k * 45,))
    d.ellipse([bx - br, by - br, bx + br, by + br], fill=accent)

    return img.resize((size, size), Image.LANCZOS)

draw(512, (22, 24, 29, 255), (245, 166, 35, 255), (54, 43, 22, 255), (245, 166, 35, 255)).save(os.path.join(OUT, "icon.png"))
draw(1024, (253, 243, 220, 255), (180, 83, 9, 255), (250, 233, 195, 255), (180, 83, 9, 255)).save(os.path.join(OUT, "logo.png"))
draw(1024, (11, 12, 15, 255), (245, 166, 35, 255), (54, 43, 22, 255), (245, 166, 35, 255)).save(os.path.join(OUT, "logo-dark.png"))
print("saved:", sorted(os.listdir(OUT)))
