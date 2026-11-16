extends Control
## Compact native overlays. Never draws, tints, or replaces the scenery.
signal action(action_id: String)
var palette: Dictionary
var font: SystemFont
var _bounds: Array[Rect2] = []

func build(style: Dictionary, weather: String, quiet: bool = false) -> void:
 palette = style
 size = Vector2(1440,810)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 font = SystemFont.new()
 font.font_names = PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Arial"])
 if quiet:
  _button("返回窗边",Rect2(1296,754,120,36),"focus")
 else:
  match str(style.id):
   "komorebi":
    _tag("窗外小世界  ·  " + weather,Rect2(24,24,230,36))
    _dock(Vector2(1124,750),0)
   "shiro_note":
    _tag("窗外小世界",Rect2(24,24,148,38))
    _weather(weather,Rect2(1320,24,96,34))
    _dock(Vector2(24,750),1)
   "mizu_letter":
    _weather(weather,Rect2(663,24,114,34))
    _dock(Vector2(1124,750),2)
   "daily_margin":
    _tag("窗边日记  /  " + weather,Rect2(24,748,228,42))
    _line(Vector2(36,780),Vector2(238,780),palette.border)
    _dock(Vector2(1124,750),1)
   "pocket_journal":
    _tag("今日窗边  ·  " + weather,Rect2(24,24,222,40))
    _line(Vector2(41,28),Vector2(41,60),palette.border)
    _dock(Vector2(574,750),3)
   "pressed_leaf":
    _tag("一叶一日  ·  " + weather,Rect2(24,24,218,36))
    _swatch(Rect2(24,24,5,36),palette.accent)
    _dock(Vector2(1124,750),4)
   "pencil_day":
    _tag("窗外小世界  /  " + weather,Rect2(24,24,234,36))
    _line(Vector2(37,54),Vector2(244,54),palette.border)
    _dock(Vector2(24,750),5)
   "pixel_breeze":
    _tag("窗外  ·  " + weather,Rect2(24,24,184,34))
    _pixel_spark(Vector2(37,36),palette.accent)
    _dock(Vector2(1124,750),6)
   "pocket_cloud":
    _weather(weather,Rect2(1296,24,120,34))
    _pixel_cloud(Vector2(1308,35))
    _dock(Vector2(574,750),7)
   "starlit_pixel":
    _tag("窗外小世界  ·  " + weather,Rect2(24,750,242,36))
    _pixel_spark(Vector2(37,762),palette.accent)
    _dock(Vector2(1124,750),8)
 set_meta("ui_bounds",_bounds)

func _box(fill: Color, border: Color, radius: int = -1) -> StyleBoxFlat:
 var result = StyleBoxFlat.new()
 result.bg_color = fill
 result.border_color = border
 result.set_border_width_all(1)
 result.set_corner_radius_all(int(palette.corner) if radius < 0 else radius)
 result.content_margin_left = 8
 result.content_margin_right = 8
 return result

func _tag(text: String, rect: Rect2) -> void:
 var panel = Panel.new()
 panel.position = rect.position
 panel.size = rect.size
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",_box(Color(palette.paper,0.94),palette.border))
 add_child(panel)
 var label = Label.new()
 label.text = text
 label.position = Vector2(12,0)
 label.size = rect.size - Vector2(24,0)
 label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 label.add_theme_font_override("font",font)
 label.add_theme_font_size_override("font_size",16)
 label.add_theme_color_override("font_color",palette.ink)
 panel.add_child(label)
 _bounds.append(rect)

func _weather(weather: String, rect: Rect2) -> void:
 _button(weather,rect,"weather")

func _dock(origin: Vector2, decoration: int) -> void:
 var labels = ["图鉴", "陪伴", "音乐"]
 var actions = ["guide", "focus", "sound"]
 for i: int in range(3):
  var button = _button(labels[i],Rect2(origin+Vector2(i*100,0),Vector2(92,38)),actions[i])
  if decoration in [1,3,4,5]:
   var mark_color: Color = palette.border
   if decoration==4 and i==0: mark_color = palette.accent
   _line(button.position+Vector2(12,31),button.position+Vector2(80,31),mark_color)
  if decoration in [6,7,8]:
   _swatch(Rect2(button.position+Vector2(8,17),Vector2(3,3)),palette.accent)
  if decoration==3:
   _swatch(Rect2(button.position+Vector2(14,-2),Vector2(24,4)),Color(palette.border,0.9))
   _bounds[_bounds.size()-1] = Rect2(button.position-Vector2(0,2),button.size+Vector2(0,2))

func _button(text: String, rect: Rect2, id: String) -> Button:
 var button = Button.new()
 button.position = rect.position
 button.size = rect.size
 button.text = text
 button.name = "Light_"+id
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 button.add_theme_font_override("font",font)
 button.add_theme_font_size_override("font_size",16)
 for state: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  button.add_theme_color_override(state,palette.ink)
 button.add_theme_stylebox_override("normal",_box(Color(palette.paper,0.95),palette.border))
 button.add_theme_stylebox_override("hover",_box(palette.paper.lightened(0.08),palette.accent))
 button.add_theme_stylebox_override("pressed",_box(palette.paper.darkened(0.045),palette.accent))
 var focus_box = _box(Color.TRANSPARENT,palette.accent)
 focus_box.set_border_width_all(2)
 button.add_theme_stylebox_override("focus",focus_box)
 button.tooltip_text = {"guide":"打开观察图鉴 · G","focus":"收起界面，安静陪伴 · 空格","sound":"打开 / 关闭轻音乐","weather":"切换天气 · W"}.get(id,"")
 button.pressed.connect(func(): action.emit(id))
 button.set_meta("ui_action",id)
 add_child(button)
 _bounds.append(rect)
 return button

func _line(a: Vector2,b: Vector2,color: Color) -> void:
 var line = Line2D.new()
 line.points = PackedVector2Array([a,b])
 line.default_color = color
 line.width = 1
 line.antialiased = str(palette.family)!="pixel"
 add_child(line)

func _swatch(rect: Rect2,color: Color) -> void:
 var swatch = ColorRect.new()
 swatch.position = rect.position
 swatch.size = rect.size
 swatch.color = color
 swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(swatch)

func _pixel_spark(origin: Vector2,color: Color) -> void:
 _swatch(Rect2(origin+Vector2(3,0),Vector2(3,9)),color)
 _swatch(Rect2(origin+Vector2(0,3),Vector2(9,3)),color)

func _pixel_cloud(origin: Vector2) -> void:
 _swatch(Rect2(origin+Vector2(3,3),Vector2(12,6)),palette.accent)
 _swatch(Rect2(origin+Vector2(6,0),Vector2(6,3)),palette.accent)
