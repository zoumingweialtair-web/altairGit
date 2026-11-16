from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
root = Path(__file__).resolve().parents[1] / 'docs' / 'ui-concepts'
styles = json.loads((root / 'manifest.json').read_text(encoding='utf-8'))
font_path = r'C:\Windows\Fonts\msyh.ttc'
font = ImageFont.truetype(font_path, 23)
small = ImageFont.truetype(font_path, 17)
title = ImageFont.truetype(font_path, 35)
width, thumb_w, gutter, margin, top, label_h = 1544, 740, 24, 20, 108, 69
thumb_h = 463
for kind, filename, heading in [('hud','overview.png','10 种主界面风格'),('guide','guide-overview.png','10 种图鉴风格')]:
    row_h = thumb_h + label_h + gutter
    sheet = Image.new('RGB', (width, top + row_h * 5 + margin), '#142629')
    draw = ImageDraw.Draw(sheet)
    draw.text((margin,18), 'Little Elsewhere / ' + heading, fill='#edf0e4', font=title)
    draw.text((margin,67), 'Godot 实景演示  ·  同一晨曦背景  ·  示例收藏与陪伴状态', fill='#bacbbd', font=small)
    for i, item in enumerate(styles):
        x = margin + (i % 2) * (thumb_w + gutter)
        y = top + (i // 2) * row_h
        source = Image.open(root / item[kind]).convert('RGB')
        source.thumbnail((thumb_w, thumb_h), Image.Resampling.LANCZOS)
        sheet.paste(source, (x, y))
        draw.text((x, y + thumb_h + 9), f"{item['index']:02d}  {item['name']}  /  {item['english']}", fill='#edf0e4', font=font)
        draw.text((x, y + thumb_h + 42), item['tagline'], fill='#bacbbd', font=small)
    sheet.save(root / filename, optimize=True)
    print(filename, sheet.size)