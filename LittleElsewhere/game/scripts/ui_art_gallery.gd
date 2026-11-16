extends Control
## Inspect the actual concept image without stretching, cropping, or pretending it is playable.
var picture: Texture2D
var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
var dragging: bool = false
var active_id: String = ""
var art_path: String = ""

func _ready() -> void:
 size = Vector2(1440,810)
 clip_contents = true
 mouse_filter = Control.MOUSE_FILTER_STOP
 mouse_default_cursor_shape = Control.CURSOR_DRAG

func build(style: Dictionary) -> void:
 active_id = str(style.id)
 art_path = str(style.art_path)
 picture = load(art_path) as Texture2D if ResourceLoader.exists(art_path) else null
 reset_view()

func reset_view() -> void:
 zoom = 1.0
 pan = Vector2.ZERO
 dragging = false
 queue_redraw()

func zoom_by(factor: float, anchor: Vector2 = Vector2(720,405)) -> void:
 var old_zoom: float = zoom
 zoom = clampf(zoom * factor,1.0,4.0)
 if is_equal_approx(zoom,1.0): pan = Vector2.ZERO
 else: pan = anchor - size * 0.5 - (anchor - size * 0.5 - pan) * zoom / old_zoom
 _clamp_pan()
 queue_redraw()

func _fitted_size() -> Vector2:
 if picture == null: return Vector2.ZERO
 var raw: Vector2 = picture.get_size()
 return raw * minf(size.x/raw.x,size.y/raw.y) * zoom

func _clamp_pan() -> void:
 var extent: Vector2 = (_fitted_size() - size) * 0.5
 pan.x = clampf(pan.x,-maxf(0.0,extent.x),maxf(0.0,extent.x))
 pan.y = clampf(pan.y,-maxf(0.0,extent.y),maxf(0.0,extent.y))

func get_snapshot() -> Dictionary:
 return {"id":active_id,"loaded":picture != null,"zoom":zoom,"pan":pan,"path":art_path}

func open_original() -> void:
 if not art_path.is_empty(): OS.shell_open(ProjectSettings.globalize_path(art_path))

func _draw() -> void:
 draw_rect(Rect2(Vector2.ZERO,size),Color("101c1e"))
 if picture != null:
  var fitted: Vector2 = _fitted_size()
  draw_texture_rect(picture,Rect2((size-fitted)*0.5+pan,fitted),false)

func _gui_input(event: InputEvent) -> void:
 if event is InputEventMouseButton:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed: zoom_by(1.2,event.position)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed: zoom_by(1.0/1.2,event.position)
  elif event.button_index == MOUSE_BUTTON_LEFT:
   dragging = event.pressed
   if event.double_click: reset_view()
  accept_event()
 elif event is InputEventMouseMotion and dragging and zoom > 1.0:
  pan += event.relative
  _clamp_pan()
  queue_redraw()
  accept_event()
