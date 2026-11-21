"""Draws the Combined Addon Menus logo: a riveted metal plate with a beveled frame, a glowing inner
panel, and a gradient capital M. One logo per skin, in that skin's colors.

Writes addon/CombinedAddonMenus/media/Logo_<skin>.tga (128x128, 32-bit, uncompressed, which the
game reads) and Icon.tga (a copy of the Classic logo, used by the .toc IconTexture).
Run: python tools/make_icon.py [--preview out.png]
"""
import pathlib
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

MEDIA = pathlib.Path(__file__).resolve().parent.parent / "addon" / "CombinedAddonMenus" / "media"
S = 512          # drawn large, then shrunk for smooth edges
OUT = 128        # the game needs power-of-two sizes
FONTS = ["C:/Windows/Fonts/BOD_BLAR.TTF", "C:/Windows/Fonts/georgiab.ttf", "C:/Windows/Fonts/arialbd.ttf"]

# frame light/dark, panel center/edge, M top/bottom, M outline, glow (or None)
SKINS = {
    "classic":   dict(frame=((255, 214, 110), (120, 72, 14)), panel=((120, 22, 14), (28, 4, 4)),
                      m=((255, 240, 170), (214, 140, 24)), outline=(46, 20, 4), glow=None),
    "gnomish":   dict(frame=((236, 186, 96), (104, 66, 24)), panel=((22, 120, 126), (6, 28, 32)),
                      m=((255, 232, 160), (200, 136, 52)), outline=(20, 30, 32), glow=None),
    "midnight":  dict(frame=((200, 182, 255), (58, 36, 120)), panel=((52, 34, 96), (6, 5, 14)),
                      m=((250, 246, 255), (166, 134, 255)), outline=(14, 8, 30), glow=(150, 110, 255)),
    "parchment": dict(frame=((150, 104, 58), (58, 34, 14)), panel=((250, 238, 206), (204, 178, 130)),
                      m=((126, 52, 18), (52, 20, 4)), outline=(250, 236, 200), glow=None),
    "fel":       dict(frame=((140, 255, 120), (16, 96, 16)), panel=((10, 60, 10), (0, 6, 0)),
                      m=((214, 255, 190), (50, 210, 50)), outline=(0, 22, 0), glow=(60, 255, 60)),
    "frost":     dict(frame=((246, 252, 255), (104, 164, 214)), panel=((100, 164, 222), (22, 52, 96)),
                      m=((255, 255, 255), (176, 222, 255)), outline=(18, 46, 86), glow=(190, 235, 255)),
}


def vgrad(size, top, bottom):
    """A vertical gradient image, top color to bottom color."""
    w, h = size
    col = Image.new("RGBA", (1, h))
    for y in range(h):
        t = y / max(1, h - 1)
        col.putpixel((0, y), tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,))
    return col.resize((w, h))


def rgrad(size, center, edge):
    """A round gradient, center color to edge color."""
    w, h = size
    small = Image.new("RGBA", (64, 64))
    for y in range(64):
        for x in range(64):
            d = min(1.0, (((x - 31.5) ** 2 + (y - 26) ** 2) ** 0.5) / 44)
            small.putpixel((x, y), tuple(int(center[i] + (edge[i] - center[i]) * d) for i in range(3)) + (255,))
    return small.resize((w, h), Image.BICUBIC)


def rrect_mask(box, radius):
    m = Image.new("L", (S, S), 0)
    ImageDraw.Draw(m).rounded_rectangle(box, radius=radius, fill=255)
    return m


def paste(base, layer, mask):
    base.paste(layer, (0, 0), mask)


def font():
    for f in FONTS:
        try:
            return ImageFont.truetype(f, 360)
        except OSError:
            pass
    return ImageFont.load_default()


def logo(c):
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    light, dark = c["frame"]

    # Metal frame: light at the top, dark at the bottom.
    outer = rrect_mask([6, 6, S - 7, S - 7], 76)
    paste(img, vgrad((S, S), light, dark), outer)
    # Thin dark edge around the outside.
    edge = ImageChops.subtract(outer, rrect_mask([14, 14, S - 15, S - 15], 70))
    paste(img, Image.new("RGBA", (S, S), c["outline"] + (255,)), edge.point(lambda v: v * 0.6))
    # Bevel: the reversed gradient makes the panel look set into the frame.
    paste(img, vgrad((S, S), dark, light), rrect_mask([42, 42, S - 43, S - 43], 50))
    # Inner panel with a soft glow in the middle.
    panel = rrect_mask([54, 54, S - 55, S - 55], 42)
    paste(img, rgrad((S, S), *c["panel"]), panel)

    # Rivets in the four corners.
    d = ImageDraw.Draw(img)
    for x, y in [(30, 30), (S - 31, 30), (30, S - 31), (S - 31, S - 31)]:
        d.ellipse([x - 11, y - 11, x + 11, y + 11], fill=dark + (255,))
        d.ellipse([x - 8, y - 9, x + 6, y + 5], fill=light + (255,))
        d.ellipse([x - 5, y - 6, x - 1, y - 2], fill=(255, 255, 255, 200))

    # The M: shadow, optional glow, outline, then the gradient letter.
    f = font()
    box = d.textbbox((0, 0), "M", font=f)
    w, h = box[2] - box[0], box[3] - box[1]
    pos = ((S - w) / 2 - box[0], (S - h) / 2 - box[1] + 6)

    def letter_mask(stroke=0, offset=(0, 0)):
        m = Image.new("L", (S, S), 0)
        ImageDraw.Draw(m).text((pos[0] + offset[0], pos[1] + offset[1]), "M", font=f, fill=255,
                               stroke_width=stroke, stroke_fill=255)
        return m

    shadow = letter_mask(14, (0, 12)).filter(ImageFilter.GaussianBlur(10))
    paste(img, Image.new("RGBA", (S, S), (0, 0, 0, 255)), ImageChops.multiply(shadow, panel).point(lambda v: v * 0.7))
    if c["glow"]:
        glow = letter_mask(22).filter(ImageFilter.GaussianBlur(18))
        paste(img, Image.new("RGBA", (S, S), c["glow"] + (255,)), ImageChops.multiply(glow, panel))
    paste(img, Image.new("RGBA", (S, S), c["outline"] + (255,)), letter_mask(12))
    top, bottom = c["m"]
    paste(img, vgrad((S, S), top, bottom), letter_mask())

    # Gloss: a faint white sheen over the top half of the panel.
    gloss = Image.new("L", (S, S), 0)
    ImageDraw.Draw(gloss).ellipse([20, -S // 2 + 40, S - 20, S // 2 - 10], fill=46)
    paste(img, Image.new("RGBA", (S, S), (255, 255, 255, 255)), ImageChops.multiply(gloss, panel))

    return img.resize((OUT, OUT), Image.LANCZOS)


def main():
    MEDIA.mkdir(parents=True, exist_ok=True)
    made = {}
    for name, colors in SKINS.items():
        im = logo(colors)
        im.save(MEDIA / f"Logo_{name}.tga", compression=None)
        made[name] = im
    made["classic"].save(MEDIA / "Icon.tga", compression=None)
    print("wrote", len(made), "logos and Icon.tga to", MEDIA)
    if "--preview" in sys.argv:
        out = sys.argv[sys.argv.index("--preview") + 1]
        sheet = Image.new("RGBA", (OUT * 6 + 70, OUT + 80), (60, 60, 60, 255))
        for i, im in enumerate(made.values()):
            sheet.paste(im, (10 + i * (OUT + 10), 10), im)
            small = im.resize((28, 28), Image.LANCZOS)   # the in-game button size
            sheet.paste(small, (10 + i * (OUT + 10) + 50, OUT + 30), small)
        sheet.save(out)
        print("preview", out)


if __name__ == "__main__":
    main()
