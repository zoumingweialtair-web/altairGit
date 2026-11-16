extends RefCounted
## Illustrated art-direction proposals: selectable previews, not implemented game skins.
static func all_styles() -> Array[Dictionary]:
 var specs: Array = [
  ["mossbound_storybook","苔庭绘本","Mossbound Storybook","藤蔓木雕、蘑菇书签与翻页鸟类绘本"],
  ["papercut_conservatory","立体纸庭","Papercut Conservatory","叠层剪纸、折纸花叶与立体卡册"],
  ["nordic_quilt","北欧织锦","Nordic Quilt","亚麻针脚、编织飞鸟与拼布图鉴"],
  ["cyanotype_herbarium","蓝晒标本","Cyanotype Herbarium","蓝晒植物负片、晒印纸与标本索引"],
  ["moon_stained_glass","月影彩窗","Moon Stained Glass","月蛾彩玻璃、铅条曲线与拱形收藏窗"],
  ["wooden_theatre","木偶窗剧场","Wooden Theatre","木版玩具舞台、幕布与来客戏票"],
  ["riso_ramble","孔版游记","Riso Ramble","三色错版、粗颗粒刻印与撕纸游记"],
  ["graphite_fieldwork","铅笔野录","Graphite Fieldwork","石墨速写、手写圈线与活页观察册"],
  ["night_signal","深夜讯号","Night Signal","琥珀点阵、复古旋钮与观测仪表"],
  ["tideglass_atlas","潮汐图仪","Tideglass Atlas","铜质罗盘、航海刻线与海图鸟类图鉴"]
 ]
 var result: Array[Dictionary] = []
 for i in range(specs.size()):
  var entry: Array = specs[i]
  result.append({"id":entry[0],"name":entry[1],"english":entry[2],"tagline":entry[3],"kind":"concept","art_path":"res://assets/ui_concepts_v2/%02d-%s.png" % [i+11,entry[0]],"paper":Color("eee8d9"),"ink":Color("283e38"),"accent":Color("537b64"),"muted":Color("667768"),"border":Color("a4b39f"),"font":"Microsoft YaHei","title_font":"Georgia","corner":0})
 return result
