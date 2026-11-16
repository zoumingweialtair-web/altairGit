extends RefCounted
## Quiet overlays: the original scenery is shared by every proposal.
static func all_styles() -> Array[Dictionary]:
 var specs: Array = [
  ["komorebi","木漏れ日","Komorebi","日系 · 小白签与分散按钮", "f7f8ef","354b42","748773","c5cec0",12,"japanese"],
  ["shiro_note","白纸日和","Shiro Note","日系 · 薄纸签与轻线条", "fbfaf4","4c5149","87907a","d4d5c8",3,"japanese"],
  ["mizu_letter","水色来信","Mizu Letter","日系 · 水色小签与留白", "f0f7f6","36565b","71979a","bfd1cf",16,"japanese"],
  ["daily_margin","日常页边","Daily Margin","手账 · 窗台边的一行记录", "f8f1df","655a48","aa9970","d7c9aa",2,"journal"],
  ["pocket_journal","口袋手帖","Pocket Journal","手账 · 小页签与轻装订线", "f8f4e9","5c594e","929477","d3cfbb",4,"journal"],
  ["pressed_leaf","一叶书签","Pressed Leaf","手账 · 一枚叶色索引签", "f2f4e7","4b5d47","859778","c7d0b6",2,"journal"],
  ["pencil_day","铅笔日记","Pencil Day","手账 · 铅笔细线与纸白按钮", "faf9f3","565a56","8b948b","d0d3ca",0,"journal"],
  ["pixel_breeze","像素微风","Pixel Breeze","像素 · 一像素细边与小方钮", "f4f5e8","465943","7e9670","a9b69c",0,"pixel"],
  ["pocket_cloud","口袋云朵","Pocket Cloud","像素 · 天蓝小标签与阶梯线", "f2f6f4","46616a","88abb4","b6cad0",0,"pixel"],
  ["starlit_pixel","星点窗边","Starlit Pixel","像素 · 米白方钮与一点星色", "f6f2e5","465262","a49977","b7bfbd",0,"pixel"]
 ]
 var result: Array[Dictionary] = []
 for item: Array in specs:
  result.append({"id":item[0],"name":item[1],"english":item[2],"tagline":item[3],"paper":Color(item[4]),"ink":Color(item[5]),"accent":Color(item[6]),"muted":Color(item[5]).lightened(0.13),"border":Color(item[7]),"font":"Microsoft YaHei UI","title_font":"Consolas" if item[9]=="pixel" else "Microsoft YaHei UI","corner":item[8],"lightweight":true,"family":item[9]})
 return result
