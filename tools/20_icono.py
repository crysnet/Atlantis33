"""Genera el icono de la app (Android + web + favicon). Uso: python3 tools/20_icono.py"""
import math, os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "app")
S = 2048  # lienzo maestro (supersampling)
BG0, BG1 = (30, 25, 22), (10, 8, 7)
ORANGE_L, ORANGE_D = (244, 144, 84), (170, 62, 24)
CREAM, CYAN, DARK = (236, 231, 225), (0, 229, 255), (14, 12, 11)


def bez(p0, p1, p2, p3, n=240):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        pts.append((u**3*p0[0]+3*u*u*t*p1[0]+3*u*t*t*p2[0]+t**3*p3[0],
                    u**3*p0[1]+3*u*u*t*p1[1]+3*u*t*t*p2[1]+t**3*p3[1]))
    return pts


def lerp(a, b, t):
    return tuple(int(a[i]+(b[i]-a[i])*t) for i in range(3))


def master():
    im = Image.new("RGB", (S, S))
    px = im.load()
    # fondo: degradado radial oscuro
    cx = cy = S/2
    for y in range(S):
        for x in range(S):
            d = min(1.0, math.hypot(x-cx, y-cy)/(S*0.72))
            px[x, y] = lerp(BG0, BG1, d)
    im = im.convert("RGBA")
    k = S/1024
    # disco de Marte con degradado diagonal
    r = 300*k
    disc = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    grad = Image.new("RGB", (S, S))
    gp = grad.load()
    for y in range(S):
        for x in range(S):
            t = max(0, min(1, ((x-(cx-r))+(y-(cy-r)))/(4*r)))
            gp[x, y] = lerp(ORANGE_L, ORANGE_D, t)
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).ellipse([cx-r, cy-r, cx+r, cy+r], fill=255)
    disc.paste(grad, (0, 0), mask)
    # bandas de polvo oscuras, recortadas al disco
    bands = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bands)
    for (bx, by, w, h, a) in [(430, 760, 520, 90, 46), (600, 690, 420, 60, 34), (420, 340, 330, 50, 30)]:
        bd.ellipse([(bx-w/2)*k, (by-h/2)*k, (bx+w/2)*k, (by+h/2)*k], fill=(90, 30, 10, a))
    bands = bands.filter(ImageFilter.GaussianBlur(14*k))
    clipped = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    clipped.paste(bands, (0, 0), mask)
    disc.alpha_composite(clipped)
    # halo
    glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse([cx-r-10*k, cy-r-10*k, cx+r+10*k, cy+r+10*k], fill=(226, 98, 43, 70))
    im.alpha_composite(glow.filter(ImageFilter.GaussianBlur(40*k)))
    im.alpha_composite(disc)

    # ruta en S
    pts = [(x*k, y*k) for x, y in bez((300, 690), (300, 470), (730, 600), (730, 340))]
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    def stroke(width, col):
        for (x, y) in pts:
            ld.ellipse([x-width/2, y-width/2, x+width/2, y+width/2], fill=col)
    stroke(74*k, DARK+(110,))
    im.alpha_composite(layer.filter(ImageFilter.GaussianBlur(3*k)))
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0)); ld = ImageDraw.Draw(layer)
    stroke(44*k, CREAM+(255,))
    im.alpha_composite(layer)
    d = ImageDraw.Draw(im)
    # inicio: punto crema con aro oscuro
    sx, sy = pts[0]
    d.ellipse([sx-40*k, sy-40*k, sx+40*k, sy+40*k], fill=DARK+(255,))
    d.ellipse([sx-26*k, sy-26*k, sx+26*k, sy+26*k], fill=CREAM+(255,))
    # destino: baliza cian
    ex, ey = pts[-1]
    halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(halo).ellipse([ex-80*k, ey-80*k, ex+80*k, ey+80*k], fill=CYAN+(120,))
    im.alpha_composite(halo.filter(ImageFilter.GaussianBlur(26*k)))
    d = ImageDraw.Draw(im)
    d.ellipse([ex-52*k, ey-52*k, ex+52*k, ey+52*k], fill=DARK+(255,))
    d.ellipse([ex-38*k, ey-38*k, ex+38*k, ey+38*k], fill=CYAN+(255,))
    d.ellipse([ex-14*k, ey-14*k, ex+14*k, ey+14*k], fill=DARK+(255,))
    return im


def rounded(im, frac=0.22):
    m = Image.new("L", im.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, im.size[0]-1, im.size[1]-1], radius=int(im.size[0]*frac), fill=255)
    out = im.copy(); out.putalpha(m); return out


def save(im, rel, size):
    p = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(p), exist_ok=True)
    im.resize((size, size), Image.LANCZOS).save(p)
    print(rel, size)


m = master()
sq = m.convert("RGB")
rd = rounded(m)
for d, s in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    save(rd, f"android/app/src/main/res/mipmap-{d}/ic_launcher.png", s)
save(rd, "web/icons/Icon-192.png", 192)
save(rd, "web/icons/Icon-512.png", 512)
save(sq, "web/icons/Icon-maskable-192.png", 192)
save(sq, "web/icons/Icon-maskable-512.png", 512)
save(rd, "web/favicon.png", 64)
rd.resize((256, 256), Image.LANCZOS).save(os.path.join(ROOT, "web/favicon.ico"), sizes=[(16, 16), (32, 32), (48, 48), (64, 64)])
sq.resize((1024, 1024), Image.LANCZOS).save(os.path.join(ROOT, "../tools/icono_1024.png"))
print("ok")
