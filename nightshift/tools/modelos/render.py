"""Vista previa de los modelos (rasterizado simple con PIL, sin Godot)."""
import math
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from mlib import collect_triangles
import monsters as MS


def shade(mat, normal, view_dir):
    base = np.array(mat["color"][:3], dtype=float)
    key = np.array([-0.45, 0.65, 0.62]); key /= np.linalg.norm(key)
    rim = np.array([0.7, 0.2, -0.7]); rim /= np.linalg.norm(rim)
    n = normal / (np.linalg.norm(normal) + 1e-9)
    if np.dot(n, view_dir) < 0:
        n = -n
    diff = max(np.dot(n, key), 0.0)
    rimv = max(np.dot(n, rim), 0.0) ** 2 * 0.35
    h = key + view_dir; h /= np.linalg.norm(h)
    spec = (max(np.dot(n, h), 0.0) ** (8 + 60 * (1 - mat.get("rough", 0.7)))) * (1 - mat.get("rough", 0.7)) * 0.9
    metal = mat.get("metal", 0.0)
    c = base * (0.16 + 0.95 * diff) + rimv * np.array([0.55, 0.6, 0.8]) + spec * (base * metal + (1 - metal))
    if "emission" in mat:
        c = c + np.array(mat["emission"][:3]) * min(mat.get("energy", 1) / 2.5, 1.0)
    return tuple(int(255 * min(max(v, 0.0), 1.0) ** (1 / 1.15)) for v in c)


def render(root, mats, yaw_deg, size=(380, 620), height=2.45, ground=True, scale_override=None):
    W, H = size
    S = 3
    img = Image.new("RGB", (W * S, H * S), (16, 15, 20))
    d = ImageDraw.Draw(img)
    yaw = math.radians(yaw_deg)
    R = np.array([[math.cos(yaw), 0, math.sin(yaw)], [0, 1, 0], [-math.sin(yaw), 0, math.cos(yaw)]])
    view = np.array([0, 0.05, 1.0]); view /= np.linalg.norm(view)
    tris = collect_triangles(root)
    pts_all = np.concatenate([t for t, _ in tris]) @ R.T
    top = pts_all[:, 1].max()
    h = scale_override or height
    px = H * S * 0.9 / h
    cx, cy = W * S / 2, H * S * 0.95
    if ground:
        for i in range(40):
            rr = (1 - i / 40)
            d.ellipse([cx - 120 * S * rr, cy - 14 * S * rr, cx + 120 * S * rr, cy + 14 * S * rr],
                      fill=(int(16 + 14 * (1 - rr)), int(15 + 12 * (1 - rr)), int(20 + 14 * (1 - rr))))
    zbuf = np.full((H * S, W * S), -1e9)
    cbuf = np.array(img, dtype=np.uint8)
    for pts, m in tris:
        p = pts @ R.T
        nrm = np.cross(p[1] - p[0], p[2] - p[0])
        if np.linalg.norm(nrm) < 1e-12:
            continue
        col = np.array(shade(mats[m], nrm, view), dtype=np.uint8)
        xs = cx + p[:, 0] * px
        ys = cy - p[:, 1] * px
        x0, x1 = int(max(np.floor(xs.min()), 0)), int(min(np.ceil(xs.max()), W * S - 1))
        y0, y1 = int(max(np.floor(ys.min()), 0)), int(min(np.ceil(ys.max()), H * S - 1))
        if x1 < x0 or y1 < y0:
            continue
        gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
        (ax, bx, cx2), (ay, by, cy2) = xs, ys
        den = (by - cy2) * (ax - cx2) + (cx2 - bx) * (ay - cy2)
        if abs(den) < 1e-9:
            continue
        w0 = ((by - cy2) * (gx - cx2) + (cx2 - bx) * (gy - cy2)) / den
        w1 = ((cy2 - ay) * (gx - cx2) + (ax - cx2) * (gy - cy2)) / den
        w2 = 1 - w0 - w1
        inside = (w0 >= -1e-6) & (w1 >= -1e-6) & (w2 >= -1e-6)
        if not inside.any():
            continue
        z = w0 * p[0, 2] + w1 * p[1, 2] + w2 * p[2, 2]
        sub = zbuf[y0:y1 + 1, x0:x1 + 1]
        upd = inside & (z > sub)
        sub[upd] = z[upd]
        cbuf[y0:y1 + 1, x0:x1 + 1][upd] = col
    img = Image.fromarray(cbuf)
    img = img.resize((W, H), Image.LANCZOS)
    # bloom de ojos
    return img


def sheet(out_path):
    keys = ["botones", "chef", "mucama", "cornelius", "bailarina"]
    names = {"botones": "El Botones", "chef": "El Chef", "mucama": "La Mucama", "cornelius": "Cornelius",
             "bailarina": "La Bailarina"}
    tiles = []
    for k in keys:
        root, mats, _ = MS.ALL[k]()
        hgt = 2.45 if k != "bailarina" else 1.15
        a = render(root, mats, 0, height=hgt)
        b = render(root, mats, 38, height=hgt)
        tiles.append((names[k], a, b))
    W, H = 380, 620
    sheet = Image.new("RGB", (W * 5, H * 2 + 60), (10, 10, 13))
    dr = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf", 26)
    except Exception:
        font = ImageFont.load_default()
    for i, (n, a, b) in enumerate(tiles):
        sheet.paste(a, (i * W, 60))
        sheet.paste(b, (i * W, 60 + H))
        tw = dr.textlength(n, font=font)
        dr.text((i * W + (W - tw) / 2, 16), n, fill=(212, 170, 60), font=font)
    sheet.save(out_path)
    return out_path


if __name__ == "__main__":
    print(sheet(sys.argv[1] if len(sys.argv) > 1 else "preview.png"))
