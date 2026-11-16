extends RefCounted
## Ten distinct visual directions for the native UI laboratory.

static func all_styles() -> Array[Dictionary]:
 return [
  {"id":"field_notes","name":"自然手账","english":"Field Notes","tagline":"暖纸、索引签与观察笔记，让收集像一本慢慢写满的手账。","paper":Color("f1ead8"),"ink":Color("37453b"),"accent":Color("627957"),"muted":Color("66745e"),"border":Color("b8b99e"),"font":"Microsoft YaHei","title_font":"Georgia","corner":3},
  {"id":"quiet_glass","name":"留白玻璃","english":"Quiet Glass","tagline":"轻透悬浮的控件，给窗外留出最多呼吸空间。","paper":Color(0.93,0.97,0.94,0.93),"ink":Color("284840"),"accent":Color("3d766a"),"muted":Color("55766c"),"border":Color("bcd5ca"),"font":"Microsoft YaHei UI","title_font":"Segoe UI Light","corner":25},
  {"id":"pocket_pixels","name":"像素掌机","english":"Pocket Pixels","tagline":"四阶绿、方角与明确按键，像一台放在窗边的小掌机。","paper":Color("d9dfaf"),"ink":Color("2c4936"),"accent":Color("4f6d43"),"muted":Color("5c704c"),"border":Color("384e31"),"font":"Microsoft YaHei","title_font":"Consolas","corner":0},
  {"id":"woodland_post","name":"森间来信","english":"Woodland Post","tagline":"邮票、明信片与邮戳，把每次来访收成一封信。","paper":Color("f4e7d2"),"ink":Color("604b3c"),"accent":Color("a96046"),"muted":Color("8a705b"),"border":Color("c9ad8b"),"font":"Microsoft YaHei","title_font":"Georgia","corner":2},
  {"id":"moon_observatory","name":"月光观测","english":"Moon Observatory","tagline":"深蓝、细金线与观测刻度，让夜空奇遇更神秘。","paper":Color(0.075,0.13,0.22,0.96),"ink":Color("e4dfc8"),"accent":Color("d4bd81"),"muted":Color("acb8bd"),"border":Color("647785"),"font":"Microsoft YaHei","title_font":"Georgia","corner":8},
  {"id":"botanical_cabinet","name":"植物标本","english":"Botanical Cabinet","tagline":"标本标签与分类抽屉，强调自然观察和图鉴收藏。","paper":Color("e7e6cd"),"ink":Color("354c3c"),"accent":Color("597457"),"muted":Color("6c785a"),"border":Color("a2ac89"),"font":"Microsoft YaHei","title_font":"Cambria","corner":1},
  {"id":"rain_radio","name":"雨夜电台","english":"Rain Radio","tagline":"暖琥珀的收音机面板，让声音和专注成为主角。","paper":Color(0.16,0.18,0.18,0.97),"ink":Color("f0dfbc"),"accent":Color("e0ad63"),"muted":Color("b9b8a0"),"border":Color("717569"),"font":"Microsoft YaHei","title_font":"Consolas","corner":11},
  {"id":"paper_theatre","name":"剪纸剧场","english":"Paper Theatre","tagline":"叠纸、错位阴影与彩色票签，轻巧而有童话感。","paper":Color("f1e9dc"),"ink":Color("514c60"),"accent":Color("a77381"),"muted":Color("7d7182"),"border":Color("b5a4ad"),"font":"Microsoft YaHei","title_font":"Trebuchet MS","corner":16},
  {"id":"ink_stillness","name":"水墨留白","english":"Ink & Stillness","tagline":"墨色、印章与疏朗留白，适合长时间安静陪伴。","paper":Color(0.95,0.93,0.87,0.95),"ink":Color("343f39"),"accent":Color("8c5148"),"muted":Color("6e7870"),"border":Color("b5b8a7"),"font":"KaiTi","title_font":"Georgia","corner":0},
  {"id":"celestial_archive","name":"星象档案","english":"Celestial Archive","tagline":"黄铜边框与几何刻线，把奇遇保存成一份珍贵档案。","paper":Color(0.12,0.25,0.26,0.97),"ink":Color("eee2bf"),"accent":Color("d5b77a"),"muted":Color("b5c5b4"),"border":Color("859981"),"font":"Microsoft YaHei","title_font":"Georgia","corner":0}
 ]
