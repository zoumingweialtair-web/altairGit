extends Control
## Ten native HUD compositions. All values are preview-only.
signal action(action_id: String)
const Illustration = preload("res://scripts/guide_illustration.gd")
var palette: Dictionary = {}
var body_font: SystemFont
var display_font: SystemFont
var weather_text: String = "晨曦"

func build(style: Dictionary, weather_label: String, quiet: bool = false) -> void:
 for child: Node in get_children():
  remove_child(child)
  child.queue_free()
 palette = style
 weather_text = weather_label
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 size = Vector2(1440,810)
 body_font = _font(str(style.font))
 display_font = _font(str(style.title_font))
 if quiet:
  _panel(Rect2(32,28,270,66),Color(0.10,0.16,0.17,0.84),Color(0,0,0,0),12)
  _text("Little Elsewhere",Rect2(48,38,238,29),23,Color("f0ecd8"),true)
  _text("留一点时间给窗外",Rect2(49,68,225,20),14,Color("d0d7c9"))
  _button("结束陪伴",Rect2(1228,724,180,50),"focus",true)
  return
 match str(style.id):
  "field_notes": _field_notes()
  "quiet_glass": _quiet_glass()
  "pocket_pixels": _pocket_pixels()
  "woodland_post": _woodland_post()
  "moon_observatory": _moon_observatory()
  "botanical_cabinet": _botanical_cabinet()
  "rain_radio": _rain_radio()
  "paper_theatre": _paper_theatre()
  "ink_stillness": _ink_stillness()
  "celestial_archive": _celestial_archive()

func _font(family: String) -> SystemFont:
 var font: SystemFont = SystemFont.new()
 font.font_names = PackedStringArray([family,"Microsoft YaHei UI","Microsoft YaHei","Arial"])
 return font

func _box(fill: Color, edge: Color, radius: int = -1, thickness: int = 1) -> StyleBoxFlat:
 var box: StyleBoxFlat = StyleBoxFlat.new()
 box.bg_color = fill
 box.border_color = edge
 box.set_border_width_all(thickness)
 box.set_corner_radius_all(int(palette.corner) if radius < 0 else radius)
 box.content_margin_left = 12
 box.content_margin_right = 12
 return box

func _panel(rect: Rect2, fill: Color = Color.TRANSPARENT, edge: Color = Color.TRANSPARENT, radius: int = -1, shadow: bool = false) -> Panel:
 var p: Panel = Panel.new()
 p.position = rect.position
 p.size = rect.size
 p.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var color: Color = palette.paper if fill == Color.TRANSPARENT else fill
 var border: Color = palette.border if edge == Color.TRANSPARENT else edge
 var style: StyleBoxFlat = _box(color,border,radius)
 if shadow:
  style.shadow_color = Color(0.06,0.1,0.07,0.22)
  style.shadow_size = 5
  style.shadow_offset = Vector2(3,4)
 p.add_theme_stylebox_override("panel",style)
 add_child(p)
 return p

func _text(value: String, rect: Rect2, font_size: int = 18, color: Color = Color.TRANSPARENT, display: bool = false, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
 var label: Label = Label.new()
 label.position = rect.position
 label.size = rect.size
 label.text = value
 label.add_theme_font_override("font",display_font if display else body_font)
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",palette.ink if color == Color.TRANSPARENT else color)
 label.horizontal_alignment = align
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.clip_text = true
 add_child(label)
 return label

func _button(value: String, rect: Rect2, id: String, filled: bool = false, light: bool = false) -> Button:
 var button: Button = Button.new()
 button.position = rect.position
 button.size = rect.size
 button.text = value
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 button.add_theme_font_override("font",body_font)
 button.add_theme_font_size_override("font_size",17)
 var base: Color = palette.accent if filled else palette.paper
 if light: base = Color(palette.paper,0.82)
 var color: Color = _contrasting_ink(base) if filled else palette.ink
 button.add_theme_color_override("font_color",color)
 button.add_theme_color_override("font_focus_color",color)
 button.add_theme_color_override("font_hover_color",_contrasting_ink(base.lightened(0.10)) if filled else color)
 button.add_theme_color_override("font_pressed_color",_contrasting_ink(base.darkened(0.06)) if filled else color)
 button.add_theme_stylebox_override("normal",_box(base,palette.border))
 button.add_theme_stylebox_override("hover",_box(base.lightened(0.10),palette.accent,-1,2))
 button.add_theme_stylebox_override("pressed",_box(base.darkened(0.06),palette.accent,-1,2))
 button.add_theme_stylebox_override("focus",_box(Color(0,0,0,0),palette.accent,-1,2))
 button.pressed.connect(_emit_action.bind(id))
 button.set_meta("ui_action",id)
 add_child(button)
 return button

# Contrast is measured in linear light after decoding sRGB.
func _contrast(a: Color, b: Color) -> float:
 var first: float = a.srgb_to_linear().get_luminance()
 var second: float = b.srgb_to_linear().get_luminance()
 return (maxf(first,second)+0.05)/(minf(first,second)+0.05)

func _contrasting_ink(background: Color) -> Color:
 var dark: Color = Color("24382e")
 var light: Color = Color("fff9e9")
 var chosen: Color = dark if _contrast(dark,background) >= _contrast(light,background) else light
 if _contrast(chosen,background) < 4.5:
  chosen = Color.BLACK if _contrast(Color.BLACK,background) >= _contrast(Color.WHITE,background) else Color.WHITE
 return chosen
func _emit_action(id: String) -> void:
 action.emit(id)

func _line(a: Vector2, b: Vector2, color: Color = Color.TRANSPARENT, width: float = 1.0) -> void:
 var line: Line2D = Line2D.new()
 line.points = PackedVector2Array([a,b])
 line.default_color = palette.border if color == Color.TRANSPARENT else color
 line.width = width
 line.antialiased = true
 add_child(line)

func _dashes(a: Vector2, b: Vector2, color: Color, dash: float = 7.0) -> void:
 var dist: float = a.distance_to(b)
 var direction: Vector2 = (b-a).normalized()
 var offset: float = 0.0
 while offset < dist:
  _line(a+direction*offset,a+direction*minf(dist,offset+dash),color,1.0)
  offset += dash*1.8

func _ring(center: Vector2, radius: float, color: Color, width: float = 1.0) -> void:
 var circle: Line2D = Line2D.new()
 var pts: PackedVector2Array = PackedVector2Array()
 for i: int in range(65): pts.append(center + Vector2.from_angle(float(i)*TAU/64.0)*radius)
 circle.points = pts
 circle.default_color = color
 circle.width = width
 circle.antialiased = true
 add_child(circle)

func _star(center: Vector2, extent: float, color: Color) -> void:
 var shape: Polygon2D = Polygon2D.new()
 var pts: PackedVector2Array = PackedVector2Array()
 for i: int in range(8): pts.append(center+Vector2.from_angle(-PI*0.5+float(i)*PI*0.25)*(extent if i%2==0 else extent*0.24))
 shape.polygon = pts
 shape.color = color
 add_child(shape)

func _bird(rect: Rect2) -> void:
 var picture: Control = Illustration.new()
 picture.position = rect.position
 picture.size = rect.size
 picture.configure("sparrow",true,true)
 picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(picture)

func _field_notes() -> void:
 _panel(Rect2(32,30,308,166),Color.TRANSPARENT,Color.TRANSPARENT,3,true)
 _panel(Rect2(82,22,110,20),Color("c5ceb1"),Color("c5ceb1"),0)
 _text("FIELD JOURNAL  /  01",Rect2(54,49,264,24),13,palette.muted,true)
 _text("Little Elsewhere",Rect2(54,78,264,43),29,Color.TRANSPARENT,true)
 _line(Vector2(54,129),Vector2(318,129))
 _text("今天，也来窗边坐一会儿。",Rect2(54,140,264,27),16)
 _button(weather_text+"  /  河湾",Rect2(1200,34,208,44),"weather")
 _panel(Rect2(32,650,366,126),Color.TRANSPARENT,Color.TRANSPARENT,3,true)
 _line(Vector2(62,666),Vector2(62,760),Color("bd8b78"))
 for y: int in [694,721,748]: _line(Vector2(78,y),Vector2(376,y),Color("c9ccb8"))
 _text("今日观察",Rect2(80,659,180,30),18)
 _text("麻雀来访  ·  12 / 50 已收录",Rect2(80,692,294,28),16)
 _text("留一点时间给微小的惊喜。",Rect2(80,721,294,28),15,palette.muted)
 _button("翻开图鉴",Rect2(1198,604,210,50),"guide")
 _button("偶遇奇观",Rect2(1198,665,210,46),"event")
 _button("开始陪伴  25:00",Rect2(1198,722,210,54),"focus",true)

func _quiet_glass() -> void:
 _panel(Rect2(32,30,326,94),Color(0.94,0.98,0.95,0.90),Color("d5e4d9"),24,true)
 _text("Little Elsewhere",Rect2(56,42,280,41),30,Color.TRANSPARENT,true)
 _text("窗外小世界",Rect2(57,82,260,25),15,palette.muted)
 _button(weather_text+"  18°",Rect2(1236,34,172,48),"weather",false,true)
 _panel(Rect2(1098,600,310,78),Color(0.94,0.98,0.95,0.94),Color("d5e4d9"),25)
 _bird(Rect2(1110,610,66,58))
 _text("一位熟悉的小邻居",Rect2(1190,609,200,25),16)
 _text("麻雀停在枝头",Rect2(1190,640,200,23),14,palette.muted)
 _panel(Rect2(314,708,812,72),Color(0.94,0.98,0.95,0.92),Color("d5e4d9"),36,true)
 _text("12 / 50",Rect2(338,721,112,42),20,Color.TRANSPARENT,true)
 _button("观察图鉴",Rect2(470,720,146,48),"guide",false,true)
 _button("轻音乐",Rect2(632,720,146,48),"sound",false,true)
 _button("开始陪伴  25:00",Rect2(798,720,302,48),"focus",true)

func _pocket_pixels() -> void:
 _panel(Rect2(40,40,350,112),Color("33482d"),Color("33482d"),0)
 _panel(Rect2(32,32,350,112),Color.TRANSPARENT,Color.TRANSPARENT,0)
 _text("LITTLE ELSEWHERE",Rect2(50,47,316,34),28,Color.TRANSPARENT,true)
 _text("WINDOW MODE  /  像素观察站",Rect2(50,92,316,30),15)
 _button(weather_text+"  [ W ]",Rect2(1176,32,232,54),"weather")
 _panel(Rect2(64,668,1312,108),Color("33482d"),Color("33482d"),0)
 _panel(Rect2(56,660,1312,108),Color.TRANSPARENT,Color.TRANSPARENT,0)
 _text("COLLECTION",Rect2(80,678,198,26),15,palette.muted,true)
 _text("12 / 50",Rect2(80,708,198,35),27,Color.TRANSPARENT,true)
 _line(Vector2(290,678),Vector2(290,750),palette.border,3)
 _text("VISITOR / 麻雀",Rect2(312,680,216,29),17)
 _text("静静等待下一次发现",Rect2(312,719,240,25),15,palette.muted)
 _button("[ G ] 图鉴",Rect2(592,686,190,56),"guide")
 _button("[ E ] 奇遇",Rect2(800,686,190,56),"event")
 _button("开始陪伴  25:00",Rect2(1008,686,334,56),"focus",true)

func _woodland_post() -> void:
 _panel(Rect2(32,30,350,154),Color.TRANSPARENT,Color.TRANSPARENT,2,true)
 _dashes(Vector2(45,42),Vector2(368,42),palette.accent)
 _dashes(Vector2(45,172),Vector2(368,172),palette.accent)
 _text("POSTCARDS FROM",Rect2(54,56,300,23),13,palette.muted,true)
 _text("Little Elsewhere",Rect2(54,84,300,43),32,Color.TRANSPARENT,true)
 _text("寄自：河湾的窗边",Rect2(54,131,288,27),16)
 _panel(Rect2(1266,28,140,136),Color.TRANSPARENT,Color.TRANSPARENT,0)
 _ring(Vector2(1336,80),35,palette.accent,1.5)
 _text("18 NOV",Rect2(1294,60,85,24),15,palette.accent,true,HORIZONTAL_ALIGNMENT_CENTER)
 _text("AIR MAIL",Rect2(1290,86,94,20),11,palette.accent,true,HORIZONTAL_ALIGNMENT_CENTER)
 _button(weather_text,Rect2(1280,122,112,32),"weather")
 _panel(Rect2(32,628,378,148),Color.TRANSPARENT,Color.TRANSPARENT,2,true)
 _bird(Rect2(48,650,104,100))
 _line(Vector2(169,647),Vector2(169,756))
 _text("一封新的来信",Rect2(188,648,196,29),20,Color.TRANSPARENT,true)
 _text("麻雀  /  见字如晤",Rect2(188,689,196,27),16)
 _text("已收藏 12 / 50",Rect2(188,728,196,25),14,palette.muted)
 _button("打开信册",Rect2(882,718,158,58),"guide")
 _button("奇遇来信",Rect2(1054,718,158,58),"event")
 _button("陪伴 25:00",Rect2(1226,718,182,58),"focus",true)

func _moon_observatory() -> void:
 _panel(Rect2(32,30,336,114),Color.TRANSPARENT,Color.TRANSPARENT,8,true)
 _text("THE QUIET OBSERVATORY",Rect2(54,47,288,23),12,palette.accent,true)
 _text("Little Elsewhere",Rect2(54,77,288,43),30,Color.TRANSPARENT,true)
 _panel(Rect2(1242,30,166,746),Color.TRANSPARENT,Color.TRANSPARENT,8,true)
 _ring(Vector2(1325,114),51,palette.accent)
 _ring(Vector2(1325,114),44,palette.border)
 _star(Vector2(1325,111),20,palette.accent)
 _text("观 测 席",Rect2(1260,178,130,28),16,palette.accent,false,HORIZONTAL_ALIGNMENT_CENTER)
 _line(Vector2(1266,222),Vector2(1384,222),palette.border)
 _button(weather_text,Rect2(1260,244,130,46),"weather")
 _text("12 / 50",Rect2(1260,325,130,41),26,Color.TRANSPARENT,true,HORIZONTAL_ALIGNMENT_CENTER)
 _text("已记录的微光",Rect2(1260,371,130,25),14,palette.muted,false,HORIZONTAL_ALIGNMENT_CENTER)
 _button("观测图鉴",Rect2(1260,440,130,50),"guide")
 _button("等待奇观",Rect2(1260,507,130,50),"event")
 _button("轻音乐",Rect2(1260,574,130,50),"sound")
 _button("陪伴 25:00",Rect2(1260,693,130,58),"focus",true)
 _panel(Rect2(32,710,378,66),Color.TRANSPARENT,Color.TRANSPARENT,8)
 _star(Vector2(61,741),8,palette.accent)
 _text("麻雀来访  /  一次平凡的闪光",Rect2(82,720,306,44),16)

func _botanical_cabinet() -> void:
 _panel(Rect2(32,30,334,128),Color.TRANSPARENT,Color.TRANSPARENT,1,true)
 _line(Vector2(48,48),Vector2(48,140),palette.accent,4)
 _text("Little Elsewhere",Rect2(66,48,278,40),29,Color.TRANSPARENT,true)
 _text("NATURAL HISTORY / 窗边博物志",Rect2(66,101,278,29),13,palette.muted,true)
 _button(weather_text+" / 野外记录",Rect2(1174,32,234,48),"weather")
 _panel(Rect2(1164,535,244,161),Color.TRANSPARENT,Color.TRANSPARENT,1,true)
 _text("SPECIMEN 001",Rect2(1184,549,202,22),13,palette.muted,true)
 _bird(Rect2(1184,580,78,94))
 _text("麻雀",Rect2(1280,588,108,35),24)
 _text("枝头来客",Rect2(1280,630,108,27),14,palette.muted)
 _panel(Rect2(32,720,1376,56),Color.TRANSPARENT,Color.TRANSPARENT,1,true)
 _text("CABINET  /  12 OF 50",Rect2(50,731,306,33),19,Color.TRANSPARENT,true)
 _button("观察图鉴",Rect2(678,729,172,38),"guide")
 _button("奇遇档案",Rect2(862,729,172,38),"event")
 _button("开始陪伴  25:00",Rect2(1048,729,344,38),"focus",true)
 _panel(Rect2(32,652,200,52),Color("c4cdb0"),Color("a2ac89"),1)
 _text("BIRDS  /  鸟类",Rect2(48,660,168,36),17)
 _panel(Rect2(246,652,200,52),Color.TRANSPARENT,Color.TRANSPARENT,1)
 _text("WONDERS  /  奇遇",Rect2(260,660,172,36),16)

func _rain_radio() -> void:
 _panel(Rect2(32,30,346,106),Color.TRANSPARENT,Color.TRANSPARENT,11,true)
 _text("Little Elsewhere",Rect2(54,46,300,35),27,Color.TRANSPARENT,true)
 _text("窗边电台  /  ON AIR",Rect2(54,91,300,24),15,palette.accent)
 _button(weather_text+"  ·  LIVE",Rect2(1192,34,216,46),"weather")
 _panel(Rect2(146,640,1148,136),Color.TRANSPARENT,Color.TRANSPARENT,15,true)
 _ring(Vector2(222,707),38,palette.border,3)
 _ring(Vector2(222,707),27,palette.accent,2)
 _line(Vector2(222,707),Vector2(241,688),palette.accent,3)
 _text("LOFI  88.6",Rect2(284,654,330,35),27,palette.accent,true)
 _line(Vector2(286,703),Vector2(591,703),palette.border,2)
 for i: int in range(24):
  var x: float = 286+float(i)*13.0
  _line(Vector2(x,698),Vector2(x,688 if i%4==0 else 692),palette.muted)
 _text("12 / 50 已记录  ·  麻雀来访",Rect2(284,719,324,25),15,palette.muted)
 _button("声音",Rect2(638,684,132,54),"sound")
 _button("图鉴",Rect2(784,684,132,54),"guide")
 _button("开始陪伴  25:00",Rect2(938,684,330,54),"focus",true)
 _panel(Rect2(1038,550,256,66),Color.TRANSPARENT,Color.TRANSPARENT,11)
 _text("此刻：风叶、河流与鸟鸣",Rect2(1055,563,224,38),16)

func _paper_theatre() -> void:
 _panel(Rect2(44,42,332,118),Color("b3aaa0"),Color("b3aaa0"),16)
 _panel(Rect2(32,30,332,118),Color.TRANSPARENT,Color.TRANSPARENT,16)
 _panel(Rect2(50,17,112,28),Color("c5c3d6"),Color("b5adc6"),2)
 _text("Little Elsewhere",Rect2(54,55,288,42),29,Color.TRANSPARENT,true)
 _text("小小舞台  /  大大的窗外",Rect2(56,109,284,27),15,palette.muted)
 _button(weather_text+"  天气票",Rect2(1202,32,206,50),"weather")
 _panel(Rect2(44,682,326,94),Color("b8c2ae"),Color("a5b39d"),15)
 _panel(Rect2(32,670,326,94),Color.TRANSPARENT,Color.TRANSPARENT,15)
 _text("今日演员：麻雀",Rect2(54,685,282,31),20)
 _text("12 / 50 个小故事",Rect2(54,726,282,26),15,palette.muted)
 _panel(Rect2(904,712,210,64),Color("baaab7"),Color("baaab7"),16)
 _button("故事图鉴",Rect2(894,702,210,64),"guide")
 _panel(Rect2(1136,712,272,64),Color("baaab7"),Color("baaab7"),16)
 _button("开场陪伴  25:00",Rect2(1126,702,272,64),"focus",true)
 _button("偶遇下一幕",Rect2(1190,628,208,50),"event")

func _ink_stillness() -> void:
 _panel(Rect2(32,30,360,104),Color(0.95,0.93,0.87,0.91),Color("cbcbbb"),0)
 _text("Little Elsewhere",Rect2(55,43,312,41),30,Color.TRANSPARENT,true)
 _text("一窗静观，万物自来。",Rect2(58,90,306,27),21,palette.muted)
 _panel(Rect2(1298,30,110,286),Color(0.95,0.93,0.87,0.95),Color("c7cab7"),0)
 _text("窗\n外\n有\n闲",Rect2(1322,50,62,208),32,Color.TRANSPARENT,false,HORIZONTAL_ALIGNMENT_CENTER)
 _panel(Rect2(1330,270,44,30),palette.accent,palette.accent,0)
 _text("静 观",Rect2(1332,272,40,26),13,Color("fff4df"),false,HORIZONTAL_ALIGNMENT_CENTER)
 _button(weather_text,Rect2(1298,338,110,44),"weather")
 _panel(Rect2(32,715,416,61),Color(0.95,0.93,0.87,0.93),Color("c7cab7"),0)
 _text("麻雀来访  ·  已记十二 / 五十",Rect2(50,726,380,38),20)
 _line(Vector2(50,714),Vector2(242,714),palette.ink,3)
 _button("翻阅图鉴",Rect2(944,722,198,54),"guide")
 _button("静坐  25:00",Rect2(1160,722,248,54),"focus",true)

func _celestial_archive() -> void:
 _panel(Rect2(32,30,340,128),Color.TRANSPARENT,Color.TRANSPARENT,0,true)
 _line(Vector2(46,44),Vector2(358,44),palette.accent)
 _line(Vector2(46,144),Vector2(358,144),palette.accent)
 _star(Vector2(202,47),6,palette.accent)
 _text("Little Elsewhere",Rect2(56,64,292,41),29,Color.TRANSPARENT,true,HORIZONTAL_ALIGNMENT_CENTER)
 _text("ARCHIVE OF SMALL WONDERS",Rect2(56,112,292,22),11,palette.accent,true,HORIZONTAL_ALIGNMENT_CENTER)
 _button(weather_text+"  /  OBSERVATION",Rect2(1114,32,294,48),"weather")
 _panel(Rect2(32,680,1376,96),Color.TRANSPARENT,Color.TRANSPARENT,0,true)
 _line(Vector2(46,692),Vector2(1394,692),palette.accent)
 _line(Vector2(46,764),Vector2(1394,764),palette.accent)
 _text("XII / L",Rect2(60,704,186,42),29,palette.accent,true)
 _text("COLLECTED",Rect2(60,744,186,18),11,palette.muted,true)
 _line(Vector2(262,706),Vector2(262,752),palette.accent)
 _text("今日档案  /  麻雀来访",Rect2(288,706,314,42),19)
 _button("打开图鉴",Rect2(660,708,172,42),"guide")
 _button("奇遇档案",Rect2(848,708,172,42),"event")
 _button("开始陪伴  25:00",Rect2(1038,708,342,42),"focus",true)
 _panel(Rect2(1194,544,214,104),Color.TRANSPARENT,Color.TRANSPARENT,0)
 _ring(Vector2(1234,595),21,palette.accent)
 _star(Vector2(1234,595),11,palette.accent)
 _text("等待下一次",Rect2(1270,563,120,28),15,palette.muted)
 _text("奇 遇",Rect2(1270,598,120,30),23,palette.accent)
