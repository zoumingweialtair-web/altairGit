extends SceneTree
## Run with --ui-lab --ui-light. Exercises real pointer/keyboard routing without save writes.
const LIGHT_IDS: Array[String] = ["komorebi","shiro_note","mizu_letter","daily_margin","pocket_journal","pressed_leaf","pencil_day","pixel_breeze","pocket_cloud","starlit_pixel"]
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
 _run.call_deferred()

func check(ok: bool, label: String) -> void:
 checks += 1
 if ok: print("LIGHT_UI_PASS ",label)
 else:
  failures += 1
  push_error("LIGHT_UI_FAIL " + label)

func _key(code: Key) -> void:
 var pressed = InputEventKey.new()
 pressed.keycode = code
 pressed.physical_keycode = code
 pressed.pressed = true
 root.push_input(pressed,true)
 var released = InputEventKey.new()
 released.keycode = code
 released.physical_keycode = code
 released.pressed = false
 root.push_input(released,true)

func _mouse(down: bool, point: Vector2) -> void:
 var event = InputEventMouseButton.new()
 event.button_index = MOUSE_BUTTON_LEFT
 event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
 event.pressed = down
 event.position = point
 root.push_input(event,true)

func _click(button: Button, label: String) -> bool:
 var usable: bool = is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled
 check(usable,label + " is available")
 if not usable: return false
 var point: Vector2 = button.get_global_transform_with_canvas() * (button.size * 0.5)
 var motion = InputEventMouseMotion.new()
 motion.position = point
 root.push_input(motion,true)
 await process_frame
 _mouse(true,point)
 await process_frame
 _mouse(false,point)
 await process_frame
 return true

func _action(node: Node, id: String) -> Button:
 if node is Button and str(node.get_meta("ui_action","")) == id:
  return node as Button
 for child: Node in node.get_children():
  var found: Button = _action(child,id)
  if found != null: return found
 return null

func _named(node: Node, id: String) -> Button:
 return node.find_child(id,true,false) as Button

func _run() -> void:
 var args: PackedStringArray = OS.get_cmdline_user_args()
 if not args.has("--ui-lab") or not args.has("--ui-light"):
  push_error("Light UI tests require --ui-lab --ui-light to protect normal progress.")
  quit(1)
  return
 var normal: String = "user://window_diary_demo_save.json"
 var before: String = FileAccess.get_sha256(normal) if FileAccess.file_exists(normal) else "MISSING"
 var state = root.get_node("DiaryState")
 var scene = load("res://scenes/ui_lab.tscn").instantiate()
 root.add_child(scene)
 current_scene = scene
 await process_frame
 root.size = Vector2i(1440,852)
 await process_frame
 root.get_node("GMConsole").hide_console()
 scene._exporting = true
 scene.hud.modulate.a = 1.0
 # Keep actor dictionaries deterministic while the real GUI and lab controller keep processing.
 scene.world.set_process(false)
 scene.stage.set_process(false)
 check(state._save_path()=="","light preview disables save writes")
 check(scene.style_index==20,"light preview starts with proposal 21")
 check(scene.styles.size()>=30,"all ten lightweight proposals are registered")
 var compact_bar: bool = false
 for node: Node in scene.footer.get_children():
  if node is ColorRect and is_equal_approx(node.position.y,810.0) and is_equal_approx(node.size.y,42.0):
   compact_bar = true
 check(compact_bar,"showroom controls occupy a separate 42-pixel strip")

 for offset: int in range(LIGHT_IDS.size()):
  var id: String = LIGHT_IDS[offset]
  scene._change_style(offset + 20)
  await process_frame
  check(str(scene.styles[scene.style_index].id)==id,id + ": correct proposal")
  check(scene.get_active_style_kind()=="interactive" and scene.hud.visible and scene.world.visible and scene.stage.visible and not scene.art_view.visible,id + ": original animated scene stays visible")
  check(not is_instance_valid(scene.guide),id + ": guide starts closed")

  if await _click(_action(scene.hud,"guide"),id + ": guide button"):
   check(is_instance_valid(scene.guide),id + ": pointer opens guide")
  if not is_instance_valid(scene.guide):
   continue
  await _click(_named(scene.guide,"Entry_twin_moons"),id + ": unknown entry")
  var unknown: Dictionary = scene.guide.get_snapshot()
  var replay: Button = _named(scene.guide,"ReplayButton")
  check(unknown.get("selected","")=="twin_moons" and not unknown.get("known",true),id + ": unknown entry remains a mystery")
  check(replay!=null and replay.disabled,id + ": unknown replay is disabled")
  await _click(_named(scene.guide,"Entry_sparrow"),id + ": known entry")
  var prior: bool = bool(scene.guide.get_snapshot().get("favorited",false))
  await _click(_named(scene.guide,"FavoriteButton"),id + ": favorite")
  var wanted: bool = bool(scene.guide.get_snapshot().get("favorited",false))
  check(wanted!=prior,id + ": favorite toggles through real input")
  _key(KEY_ESCAPE)
  await process_frame
  check(not is_instance_valid(scene.guide),id + ": Escape closes guide")
  await _click(_action(scene.hud,"guide"),id + ": reopen guide")
  if is_instance_valid(scene.guide):
   check(bool(scene.guide.get_snapshot().get("favorited",false))==wanted,id + ": favorite survives closing the guide")
   await _click(_named(scene.guide,"CloseButton"),id + ": close guide")
   check(not is_instance_valid(scene.guide),id + ": close button returns to the view")
  else:
   check(false,id + ": guide reopens")

  scene.world.trigger("ufo",false)
  var actors_before: Array = scene.world.actors.duplicate(true)
  var events_before: Array = scene.world.spectacles.duplicate(true)
  if await _click(_action(scene.hud,"focus"),id + ": companion button"):
   check(scene.quiet,id + ": companion collapses HUD")
   check(not scene.world.quiet and not bool(scene.stage.get_atmosphere_snapshot().get("quiet",true)),id + ": companion keeps original weather motion mode")
   check(scene.world.actors==actors_before and scene.world.spectacles==events_before,id + ": companion preserves visitors and current events")
   await _click(_action(scene.hud,"focus"),id + ": return from companion")
   check(not scene.quiet,id + ": return restores compact HUD")

  var sound_before: bool = scene.sound_on
  await _click(_action(scene.hud,"sound"),id + ": music button")
  check(scene.sound_on!=sound_before and scene.music.playing==scene.sound_on,id + ": music control changes playback")
  await _click(_action(scene.hud,"sound"),id + ": restore music")
  check(scene.sound_on==sound_before,id + ": music toggles back")
  var weather_before: int = scene.weather_index
  var weather_button: Button = _action(scene.hud,"weather")
  if weather_button!=null:
   await _click(weather_button,id + ": weather button")
  else:
   _key(KEY_W)
   await process_frame
  check(scene.weather_index==(weather_before+1)%8 and scene.world.weather==scene.weather_index and scene.stage.weather==scene.weather_index,id + ": weather remains interactive")
  check(state._save_path()=="",id + ": preview still cannot write progress")

 scene._change_style(29)
 await process_frame
 _key(KEY_RIGHT)
 await process_frame
 check(scene.style_index==20,"right arrow wraps 30 to 21 within lightweight proposals")
 _key(KEY_LEFT)
 await process_frame
 check(scene.style_index==29,"left arrow wraps 21 to 30 within lightweight proposals")
 _key(KEY_F1)
 await process_frame
 check(root.get_node("GMConsole").is_open(),"F1 still opens the GM console")
 _key(KEY_F1)
 await process_frame
 check(not root.get_node("GMConsole").is_open(),"F1 closes the GM console")
 var after: String = FileAccess.get_sha256(normal) if FileAccess.file_exists(normal) else "MISSING"
 check(before==after,"normal progress remains byte-for-byte unchanged")
 print("LIGHT_UI_TEST checks=",checks," failures=",failures)
 quit(0 if failures==0 else 1)
