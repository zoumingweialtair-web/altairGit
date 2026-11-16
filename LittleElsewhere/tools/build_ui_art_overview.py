from pathlib import Path
import json
import re
from PIL import Image, ImageDraw, ImageFont
root = Path(__file__).resolve().parents[1]
source = (root / 'game/scripts/ui_art_styles.gd').read_text(encoding='utf-8')
entries = [json.loads(line.strip().rstrip(',')) for line in source.splitlines() if re.match(r'^\s+\["', line)]
assert len(entries) == 10
out = root / 'docs/ui-concepts-v2'
out.mkdir(parents=True,exist_ok=True)
font_path = r'C:\Windows\Fonts\msyh.ttc'
font = ImageFont.truetype(font_path,25)
small = ImageFont.truetype(font_path,18)
title = ImageFont.truetype(font_path,36)
width, thumb_w, thumb_h, gap, margin, top, label = 1544, 740, 417, 24, 20, 110, 79
row_h = thumb_h + label + gap
sheet = Image.new('RGB',(width,top+row_h*5+20),'#142629')
draw = ImageDraw.Draw(sheet)
draw.text((margin,18),'Little Elsewhere / 第二轮 UI 原画',fill='#f2eddf',font=title)
draw.text((margin,70),'11–20 · 每套包含主界面与图鉴 · 造型、笔触、材质方向选型',fill='#c4d0c3',font=small)
manifest=[]
for i,(ident,name,english,note) in enumerate(entries):
    image_file = root / 'game/assets/ui_concepts_v2' / f'{i+11:02d}-{ident}.png'
    original = Image.open(image_file).convert('RGB')
    preview=original.copy()
    preview.thumbnail((thumb_w,thumb_h),Image.Resampling.LANCZOS)
    x=margin+(i%2)*(thumb_w+gap)
    y=top+(i//2)*row_h
    sheet.paste(preview,(x+(thumb_w-preview.width)//2,y+(thumb_h-preview.height)//2))
    draw.text((x,y+thumb_h+10),f'{i+11:02d}  {name}  /  {english}',fill='#f2eddf',font=font)
    draw.text((x,y+thumb_h+47),note,fill='#c4d0c3',font=small)
    manifest.append({'index':i+11,'id':ident,'name':name,'english':english,'tagline':note,'image':f'../../game/assets/ui_concepts_v2/{image_file.name}','width':original.width,'height':original.height,'kind':'concept'})
sheet.save(out/'overview.png',optimize=True)
sheet.save(out/'overview.jpg',quality=92,optimize=True)
(out/'art-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Art overview:',sheet.size,'proposals:',len(manifest))