"""Crop the house+books symbol out of the full logo (drop the STUDY CENTER
text block) and produce a square, transparent-background icon source
suitable for flutter_launcher_icons (adaptive icon foreground)."""
from PIL import Image

SRC = "logo-source.png"
img = Image.open(SRC).convert("RGBA")
w, h = img.size
print("source size", w, h)

px = img.load()

# The green text banner is a big solid rectangle near the bottom. Find it by
# scanning rows bottom-up for the first row that is mostly the banner green
# (a wide horizontal band of near-identical color, not the thin roof lines).
def row_is_solid_band(y, min_run=int(w * 0.5)):
    run = 0
    best = 0
    prev = None
    for x in range(0, w, 4):
        r, g, b, a = px[x, y]
        opaque = a > 10
        if opaque:
            run += 4
            best = max(best, run)
        else:
            run = 0
    return best >= min_run

# scan from bottom to find the top edge of the green banner block
banner_top = None
for y in range(h - 1, 0, -1):
    if row_is_solid_band(y):
        banner_top = y
    elif banner_top is not None:
        break

print("banner_top (top edge of STUDY CENTER green box) =", banner_top)

# crop everything above the banner (the house+books symbol), then find the
# tight bounding box of non-transparent pixels within that region for a
# clean square crop with even padding.
symbol_region = img.crop((0, 0, w, banner_top))
bbox = symbol_region.getbbox()
print("symbol bbox within region:", bbox)

sx0, sy0, sx1, sy1 = bbox
sym = symbol_region.crop((sx0, sy0, sx1, sy1))
sw, sh = sym.size
print("tight symbol size:", sw, sh)

# pad to square with ~12% margin on all sides (safe zone for adaptive icons)
side = max(sw, sh)
pad = int(side * 0.28)
canvas_size = side + pad * 2
canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
off_x = (canvas_size - sw) // 2
off_y = (canvas_size - sh) // 2
canvas.paste(sym, (off_x, off_y), sym)
canvas.save("icon-foreground.png")
print("saved icon-foreground.png", canvas.size)

# also save a version with solid white background (for the plain, non-adaptive icon)
white_bg = Image.new("RGBA", canvas.size, (255, 255, 255, 255))
white_bg.paste(canvas, (0, 0), canvas)
white_bg.convert("RGB").save("icon-flat.png")
print("saved icon-flat.png")
