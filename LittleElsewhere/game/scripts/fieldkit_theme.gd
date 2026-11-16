extends RefCounted
## Shared native Pocket Fieldkit visual language: crisp stepped corners and small pixel shadows.
const PAPER = Color("faf6e8")
const INK = Color("384235")
const OLIVE = Color("7f9255")
const SELECTED = Color("d7e3aa")
const BLUE = Color("6d8796")
const GOLD = Color("d4a65c")
const MUTED = Color("777d6a")
const EDGE = Color("526046")
static var _font: SystemFont
static var _boxes: Dictionary = {}

static func font() -> SystemFont:
 if _font == null:
  _font = SystemFont.new()
  _font.font_names = PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Noto Sans CJK SC","Arial"])
 return _font

static func _inside(x: int,y: int) -> bool:
 if x < 0 or y < 0 or x >= 16 or y >= 16: return false
 if y in [0,15]: return x >= 4 and x <= 11
 if y in [1,2,13,14]: return x >= 2 and x <= 13
 return true

static func box(fill: Color = PAPER, edge: Color = EDGE, shadow: bool = true) -> StyleBoxTexture:
 var key: String = fill.to_html()+edge.to_html()+str(shadow)
 if _boxes.has(key): return _boxes[key]
 var image: Image = Image.create(18,18,false,Image.FORMAT_RGBA8)
 image.fill(Color.TRANSPARENT)
 if shadow:
  for y: int in range(16):
   for x: int in range(16):
    if _inside(x,y): image.set_pixel(x+2,y+2,Color(0.12,0.15,0.09,0.42))
 for y: int in range(16):
  for x: int in range(16):
   if not _inside(x,y): continue
   var boundary: bool = not _inside(x-1,y) or not _inside(x+1,y) or not _inside(x,y-1) or not _inside(x,y+1)
   var pixel: Color = edge if boundary else fill
   if not boundary and (not _inside(x,y-2) or not _inside(x-2,y)): pixel = fill.lightened(0.22)
   image.set_pixel(x,y,pixel)
 var style: StyleBoxTexture = StyleBoxTexture.new()
 style.texture = ImageTexture.create_from_image(image)
 for side: Side in [SIDE_LEFT,SIDE_TOP]: style.set_texture_margin(side,6)
 for side: Side in [SIDE_RIGHT,SIDE_BOTTOM]: style.set_texture_margin(side,8)
 style.content_margin_left = 12
 style.content_margin_top = 8
 style.content_margin_right = 14
 style.content_margin_bottom = 10
 _boxes[key] = style
 return style

static func panel_style(fill: Color = PAPER, edge: Color = EDGE) -> StyleBoxTexture:
 return box(fill,edge)

static func apply_button(button: Button, selected: bool = false) -> void:
 button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 button.add_theme_font_override("font",font())
 button.add_theme_font_size_override("font_size",18)
 for key: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
  button.add_theme_color_override(key,INK)
 button.add_theme_color_override("font_disabled_color",Color("96988b"))
 button.add_theme_stylebox_override("normal",box(SELECTED if selected else PAPER,OLIVE if selected else EDGE))
 button.add_theme_stylebox_override("hover",box(Color("fffdf5"),BLUE))
 button.add_theme_stylebox_override("pressed",box(Color("c9d59e") if selected else Color("e2dcc7"),OLIVE,false))
 button.add_theme_stylebox_override("disabled",box(Color("e3dfd2"),Color("a4a797"),false))
 var focus: StyleBoxFlat = StyleBoxFlat.new()
 focus.bg_color = Color.TRANSPARENT
 focus.border_color = BLUE
 focus.set_border_width_all(2)
 focus.set_expand_margin_all(2)
 button.add_theme_stylebox_override("focus",focus)
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

static func apply_label(label: Label, point_size: int = 18, color: Color = INK) -> void:
 label.add_theme_font_override("font",font())
 label.add_theme_font_size_override("font_size",point_size)
 label.add_theme_color_override("font_color",color)
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func theme() -> Theme:
 var result: Theme = Theme.new()
 result.default_font = font()
 result.default_font_size = 18
 result.set_color("font_color","Label",INK)
 result.set_color("font_color","Button",INK)
 for type_name: String in ["Button","OptionButton"]:
  result.set_stylebox("normal",type_name,box())
  result.set_stylebox("hover",type_name,box(Color("fffdf5"),BLUE))
  result.set_stylebox("pressed",type_name,box(SELECTED,OLIVE,false))
  result.set_color("font_hover_color",type_name,INK)
  result.set_color("font_pressed_color",type_name,INK)
  result.set_color("font_focus_color",type_name,INK)
  result.set_color("font_disabled_color",type_name,MUTED)
 result.set_stylebox("panel","Panel",box())
 result.set_stylebox("panel","PanelContainer",box())
 result.set_stylebox("normal","LineEdit",box(Color("fffdf4"),Color("a3ab91"),false))
 result.set_stylebox("focus","LineEdit",box(Color("fffdf4"),BLUE,false))
 result.set_color("font_color","LineEdit",INK)
 result.set_color("font_placeholder_color","LineEdit",MUTED)
 var track: StyleBoxFlat = StyleBoxFlat.new()
 track.bg_color = Color("c5c6b6")
 track.border_color = EDGE
 track.set_border_width_all(1)
 track.content_margin_top = 5
 track.content_margin_bottom = 5
 var progress: StyleBoxFlat = track.duplicate()
 progress.bg_color = OLIVE
 result.set_stylebox("slider","HSlider",track)
 result.set_stylebox("grabber_area","HSlider",progress)
 result.set_stylebox("grabber_area_highlight","HSlider",progress)
 var grab: Image = Image.create(18,22,false,Image.FORMAT_RGBA8)
 grab.fill(EDGE)
 for y: int in range(2,20):
  for x: int in range(2,16): grab.set_pixel(x,y,PAPER)
 result.set_icon("grabber","HSlider",ImageTexture.create_from_image(grab))
 result.set_icon("grabber_highlight","HSlider",ImageTexture.create_from_image(grab))
 result.set_stylebox("background","ProgressBar",track)
 result.set_stylebox("fill","ProgressBar",progress)
 return result
