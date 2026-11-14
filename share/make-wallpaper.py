"""Paper & ink halftone wallpaper: textured cream paper, fine ink dot grid,
large rose->gold halftone orb bottom-right, soft vignette. Rendered at 2x and
downsampled for clean anti-aliased dots."""
import math, random, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

OUT = sys.argv[1]
W, H = 2560, 1440
S = 2  # supersample
w, h = W * S, H * S
random.seed(11)

def lerp(a, b, t): return a + (b - a) * t
def mix(c1, c2, t): return tuple(int(lerp(a, b, t)) for a, b in zip(c1, c2))

PAPER = (247, 240, 231)
PAPER_LIGHT = (252, 248, 241)
INK = (87, 82, 121)
ROSE = (215, 130, 126)
GOLD = (234, 157, 52)
LOVE = (180, 99, 122)

# --- base: soft diagonal light across the paper
base = Image.new("RGB", (W, H), PAPER)
light = Image.new("L", (W, H), 0)
ImageDraw.Draw(light).ellipse([-W * 0.3, -H * 0.5, W * 0.55, H * 0.75], fill=210)
light = light.filter(ImageFilter.GaussianBlur(300))
base = Image.composite(Image.new("RGB", (W, H), PAPER_LIGHT), base, light)

# --- halftone layer at supersample
layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
d = ImageDraw.Draw(layer)

# 1) fine ink dot grid everywhere (very quiet)
pitch = 22 * S
for y in range(pitch // 2, h, pitch):
    for x in range(pitch // 2, w, pitch):
        r = 1.15 * S
        d.ellipse([x - r, y - r, x + r, y + r], fill=INK + (34,))

# 2) halftone orb: dot size follows a soft radial field, colour sweeps rose -> gold -> love
cx, cy, R = w * 0.71, h * 0.54, h * 0.36
hp = 13 * S
for y in range(0, h, hp):
    row_off = (hp // 2) if (y // hp) % 2 else 0
    for x in range(row_off, w, hp):
        dx, dy = x - cx, y - cy
        dist = math.hypot(dx, dy) / R
        if dist > 1.25:
            continue
        # light comes from top-left of the orb: bigger dots on the far (bottom-right) side
        shade = 0.5 + 0.5 * ((dx * 0.55 + dy * 0.85) / R)
        core = max(0.0, 1 - dist ** 2.2)
        fade = max(0.0, min(1.0, (1.25 - dist) / 0.35))
        size = (0.18 + 0.82 * core) * (0.45 + 0.55 * shade) * fade
        if size < 0.06:
            continue
        r = size * hp * 0.48
        ang = math.atan2(dy, dx)
        t = (math.sin(ang * 1.0 + 0.6) + 1) / 2
        col = mix(ROSE, GOLD, t * 0.75)
        if shade > 0.75:
            col = mix(col, LOVE, (shade - 0.75) * 1.2)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col + (int(150 + 90 * core),))

# 3) a thin ink orbit line around the orb, like a pen stroke
ow = 3 * S
d.ellipse([cx - R * 1.16, cy - R * 1.16, cx + R * 1.16, cy + R * 1.16], outline=INK + (60,), width=ow)
# small planet on the orbit
a = math.radians(222)
px, py = cx + R * 1.16 * math.cos(a), cy + R * 1.16 * math.sin(a)
pr = 11 * S
d.ellipse([px - pr, py - pr, px + pr, py + pr], fill=INK + (215,))

layer = layer.resize((W, H), Image.LANCZOS)
img = base.convert("RGBA")
img.alpha_composite(layer)
img = img.convert("RGB")

# --- paper fibre grain
noise = Image.effect_noise((W, H), 22).filter(ImageFilter.GaussianBlur(0.7))
grain = noise.point(lambda v: 128 + (v - 128) * 0.55)
img = ImageChops.overlay(img, Image.merge("RGB", (grain, grain, grain)))
img = Image.blend(base.convert("RGB"), img, 1.0)

# --- gentle vignette
vig = Image.new("L", (W, H), 0)
vd = ImageDraw.Draw(vig)
vd.ellipse([-W * 0.25, -H * 0.35, W * 1.25, H * 1.35], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(260))
dark = Image.new("RGB", (W, H), (226, 214, 204))
img = Image.composite(img, dark, vig)

img.save(OUT, optimize=True)
print("saved", OUT, img.size)
