#!/usr/bin/env python3
"""Generate theme 9-slice UI skins under assets/ui/skins/{grunge,clean,simple}/."""

from __future__ import annotations

import os
import random

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui", "skins")


def save(theme: str, name: str, img: Image.Image) -> None:
	d = os.path.join(ROOT, theme)
	os.makedirs(d, exist_ok=True)
	path = os.path.join(d, name)
	img.save(path, "PNG")
	print("wrote", path)


def make_grunge_panel() -> Image.Image:
	s = 96
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	fill = (220, 205, 180, 235)
	ink = (40, 32, 28, 255)
	d.rounded_rectangle([6, 6, 90, 90], radius=6, fill=fill, outline=ink, width=4)
	for _ in range(40):
		x = random.randint(4, 91)
		y = random.randint(4, 14) if random.random() < 0.5 else random.randint(82, 92)
		d.ellipse([x - 1, y - 1, x + 2, y + 2], fill=ink)
	stain = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	sd = ImageDraw.Draw(stain)
	for _ in range(8):
		cx, cy = random.randint(20, 76), random.randint(20, 76)
		r = random.randint(4, 12)
		sd.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(120, 70, 50, 28))
	img = Image.alpha_composite(img, stain.filter(ImageFilter.GaussianBlur(2)))
	px = img.load()
	for y in range(s):
		for x in range(s):
			if px[x, y][3] > 40:
				n = random.randint(-8, 8)
				r, g, b, a = px[x, y]
				px[x, y] = (max(0, min(255, r + n)), max(0, min(255, g + n)), max(0, min(255, b + n)), a)
	return img


def make_clean_panel() -> Image.Image:
	s = 96
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	d.rounded_rectangle([5, 5, 91, 91], radius=16, fill=(36, 42, 52, 235), outline=(110, 145, 180, 240), width=3)
	hi = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	hd = ImageDraw.Draw(hi)
	hd.rounded_rectangle([10, 8, 86, 28], radius=10, fill=(255, 255, 255, 38))
	img = Image.alpha_composite(img, hi.filter(ImageFilter.GaussianBlur(1.5)))
	d = ImageDraw.Draw(img)
	d.rounded_rectangle([9, 9, 87, 87], radius=13, outline=(180, 210, 240, 50), width=1)
	return img


def make_simple_panel() -> Image.Image:
	s = 96
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	cream = (250, 240, 220, 245)
	orange = (235, 150, 45, 255)
	dark = (180, 100, 25, 255)
	d.rounded_rectangle([4, 4, 92, 92], radius=22, fill=cream, outline=orange, width=6)
	for cx, cy in [(14, 14), (82, 14), (14, 82), (82, 82)]:
		d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=orange, outline=dark, width=2)
		d.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(255, 220, 150, 255))
	return img


def make_btn(radius: int, border_w: int, rough: bool = False) -> Image.Image:
	s = 64
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	border = (70, 70, 70, 255)
	d.rounded_rectangle([3, 3, 61, 61], radius=radius, fill=(245, 245, 245, 255), outline=border, width=border_w)
	if rough:
		for _ in range(20):
			x = random.randint(4, 59)
			y = random.randint(4, 9) if random.random() < 0.5 else random.randint(55, 60)
			d.point((x, y), fill=border)
	hi = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	hd = ImageDraw.Draw(hi)
	hd.rounded_rectangle([8, 6, 56, 22], radius=max(4, radius - 4), fill=(255, 255, 255, 55))
	return Image.alpha_composite(img, hi.filter(ImageFilter.GaussianBlur(1)))


def make_slot(radius: int, border_w: int, fill, border, tape: bool = False, joints: bool = False) -> Image.Image:
	s = 64
	img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	d.rounded_rectangle([3, 3, 61, 61], radius=radius, fill=fill, outline=border, width=border_w)
	if tape:
		d.polygon([(3, 10), (18, 3), (22, 8), (7, 15)], fill=(210, 190, 140, 180))
	if joints:
		for cx, cy in [(10, 10), (54, 10), (10, 54), (54, 54)]:
			d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=border)
	return img


def make_grunge_decor() -> Image.Image:
	img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	d.polygon([(2, 10), (28, 2), (30, 10), (4, 18)], fill=(210, 190, 145, 210))
	d.line([(4, 14), (28, 6)], fill=(170, 150, 110, 160), width=1)
	d.ellipse([18, 16, 28, 28], fill=(50, 30, 25, 160))
	return img


def make_clean_decor() -> Image.Image:
	img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	d.pieslice([0, 0, 24, 24], 180, 270, fill=(255, 255, 255, 55))
	d.arc([2, 2, 22, 22], 180, 270, fill=(140, 190, 240, 180), width=2)
	return img


def make_simple_decor() -> Image.Image:
	img = Image.new("RGBA", (28, 28), (0, 0, 0, 0))
	d = ImageDraw.Draw(img)
	orange = (235, 150, 45, 255)
	d.ellipse([2, 2, 26, 26], fill=orange, outline=(180, 100, 25, 255), width=2)
	d.ellipse([9, 9, 19, 19], fill=(255, 230, 170, 255))
	return img


def main() -> None:
	random.seed(7)
	save("grunge", "panel_9slice.png", make_grunge_panel())
	save("grunge", "button_9slice.png", make_btn(5, 3, True))
	save("grunge", "slot_9slice.png", make_slot(4, 3, (230, 218, 195, 250), (55, 40, 35, 230), tape=True))
	save("grunge", "decor_corner.png", make_grunge_decor())
	save("clean", "panel_9slice.png", make_clean_panel())
	save("clean", "button_9slice.png", make_btn(12, 2, False))
	save("clean", "slot_9slice.png", make_slot(12, 2, (48, 56, 70, 250), (100, 140, 175, 230)))
	save("clean", "decor_corner.png", make_clean_decor())
	save("simple", "panel_9slice.png", make_simple_panel())
	save("simple", "button_9slice.png", make_btn(18, 4, False))
	save("simple", "slot_9slice.png", make_slot(14, 4, (255, 248, 230, 250), (235, 150, 45, 255), joints=True))
	save("simple", "decor_corner.png", make_simple_decor())
	print("done")


if __name__ == "__main__":
	main()
