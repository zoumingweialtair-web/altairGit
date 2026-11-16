extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
 run.call_deferred()
func check(ok: bool,label: String) -> void:
 checks += 1
 if ok: print("ART_INPUT_PASS ",label)
 else:
  failures += 1
  push_error("ART_INPUT_FAIL " + label)
func mouse_button(button: MouseButton, down: bool, where: Vector2, double: bool=false) -> void:
 var event = InputEventMouseButton.new()
 event.button_index = button
 event.pressed = down
 event.button_mask = MOUSE_BUTTON_MASK_LEFT if down and button==MOUSE_BUTTON_LEFT else 0
 event.position = where
 event.double_click = double
 root.push_input(event,true)
func key(code: Key) -> void:
 var event = InputEventKey.new()
 event.keycode = code
 event.pressed = true
 root.push_input(event,true)
func run() -> void:
 if not OS.get_cmdline_user_args().has("--ui-lab"):
  push_error("Art viewer checks require --ui-lab")
  quit(1)
  return
 var normal: String = "user://window_diary_demo_save.json"
 var before: String = FileAccess.get_sha256(normal) if FileAccess.file_exists(normal) else "MISSING"
 root.size = Vector2i(1440,900)
 var scene = load("res://scenes/ui_lab.tscn").instantiate()
 root.add_child(scene)
 current_scene = scene
 await process_frame
 scene._change_style(10)
 await process_frame
 var art = scene.art_view
 check(art.visible and art.picture != null,"proposal 11 is visible and loaded")
 mouse_button(MOUSE_BUTTON_WHEEL_UP,true,Vector2(700,380))
 mouse_button(MOUSE_BUTTON_WHEEL_UP,false,Vector2(700,380))
 await process_frame
 check(art.zoom>1.0,"mouse wheel zooms the artwork")
 mouse_button(MOUSE_BUTTON_LEFT,true,Vector2(700,380))
 var motion = InputEventMouseMotion.new()
 motion.position = Vector2(750,410)
 motion.relative = Vector2(50,30)
 motion.button_mask = MOUSE_BUTTON_MASK_LEFT
 root.push_input(motion,true)
 mouse_button(MOUSE_BUTTON_LEFT,false,Vector2(750,410))
 await process_frame
 check(art.pan.length()>10.0,"dragging moves the enlarged artwork")
 mouse_button(MOUSE_BUTTON_LEFT,true,Vector2(700,380),true)
 mouse_button(MOUSE_BUTTON_LEFT,false,Vector2(700,380))
 await process_frame
 check(is_equal_approx(art.zoom,1.0) and art.pan==Vector2.ZERO,"double click resets the complete image")
 var point: Vector2 = scene.event_button.get_global_transform_with_canvas() * (scene.event_button.size * 0.5)
 var hover = InputEventMouseMotion.new()
 hover.position = point
 root.push_input(hover,true)
 await process_frame
 mouse_button(MOUSE_BUTTON_LEFT,true,point)
 await process_frame
 mouse_button(MOUSE_BUTTON_LEFT,false,point)
 await process_frame
 check(art.zoom>1.0,"zoom button works through actual GUI input")
 key(KEY_RIGHT)
 await process_frame
 check(scene.style_index==11,"arrow selection still works after clicking a control")
 key(KEY_F1)
 await process_frame
 var gm = root.get_node("GMConsole")
 check(gm.is_open(),"F1 still opens GM from the art gallery")
 key(KEY_F1)
 await process_frame
 check(not gm.is_open(),"F1 closes GM from the art gallery")
 scene._change_style(0)
 await process_frame
 check(scene.hud.visible and scene.stage.visible and scene.world.visible and not art.visible,"original interactive scenery is restored")
 check(not scene.weather_picker.disabled,"weather control is restored for interactive schemes")
 var after: String = FileAccess.get_sha256(normal) if FileAccess.file_exists(normal) else "MISSING"
 check(before==after,"normal save remains unchanged")
 print("ART_INPUT_TEST checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
