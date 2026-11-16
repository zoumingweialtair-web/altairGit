"""Compose native Godot captures; never alter or redraw the game scenery."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "ui-concepts-light"
items = json.loads((OUT / "manifest.json").read_text(encoding="utf-8"))
font_path = "C:/Windows/Fonts/msyh.ttc"
font = ImageFont.truetype(font_path, 25)
small = ImageFont.truetype(font_path, 17)
title = ImageFont.truetype(font_path, 34)
width, padding, card_w, row_h = 1520, 28, 720, 468
sheet = Image.new("RGB", (width, 128 + row_h * 5 + 24), "#f2f3ec")
draw = ImageDraw.Draw(sheet)
draw.text((padding, 22), "Little Elsewhere · 轻量 UI 21–30", font=title, fill="#354a41")
draw.text((padding, 76), "日系清淡 / 轻手账 / 小像素  ·  同一帧原生风景  ·  图鉴按需打开", font=font, fill="#657368")
for i, item in enumerate(items):
    x, y = padding + (i % 2) * (card_w + 24), 128 + (i // 2) * row_h
    draw.text((x, y), f"{item['index']}  {item['name']}  /  {item['english']}", font=font, fill="#354a41")
    picture = Image.open(OUT / item["hud"]).convert("RGB")
    assert picture.size == (1440, 810)
    picture = picture.resize((720, 405), Image.Resampling.LANCZOS)
    sheet.paste(picture, (x, y + 40))
    draw.rectangle((x, y + 40, x + 719, y + 444), outline="#bfc8bc", width=1)
assert all(item["background_unchanged"] for item in items)
sheet.save(OUT / "overview.jpg", quality=93, subsampling=0)
# A readable UI detail sheet complements the complete-scene comparisons.
details = Image.new("RGB", (1100, 1380), "#f2f3ec")
d = ImageDraw.Draw(details)
d.text((28, 24), "十套控件细节 · 原生截图原尺寸", font=title, fill="#354a41")
positions = [(24,24,254,60),(24,24,172,62),(663,24,777,58),(24,748,252,790),(24,24,246,64),(24,24,242,60),(24,24,258,60),(24,24,208,58),(1296,24,1416,58),(24,750,266,786)]
docks = [1124,24,1124,1124,574,1124,24,1124,574,1124]
for i, item in enumerate(items):
    y = 100 + i * 124
    d.text((28,y), f"{item['index']}  {item['name']}", font=font, fill="#354a41")
    d.text((380,y), item["tagline"], font=small, fill="#657368")
    pic = Image.open(OUT/item["hud"]).convert("RGB")
    details.paste(pic.crop(positions[i]),(28,y+42))
    details.paste(pic.crop((docks[i]-4,746,docks[i]+296,792)),(380,y+38))
details.save(OUT/"controls-detail.jpg",quality=95,subsampling=0)
print(f"Wrote {len(items)} unchanged-backdrop proposals to {OUT}")
