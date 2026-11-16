extends SceneTree
## Exercises real GM input routing against the actual game scene; run with --capture.
var checks: int = 0
var failures: int = 0

func check(ok: bool, label: String) -> void:
 checks += 1
 if ok: print("GM_UI_PASS ", label)
 else:
  failures += 1
  push_error("GM_UI_FAIL " + label)

func _initialize() -> void:
 _run.call_deferred()

func key(code: Key, character: int = 0) -> void:
 var input = InputEventKey.new()
 input.keycode = code
 input.physical_keycode = code
 input.unicode = character
 input.pressed = true
 root.push_input(input, true)
 var release = InputEventKey.new()
 release.keycode = code
 release.physical_keycode = code
 release.pressed = false
 root.push_input(release, true)

func _run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):
  push_error("GM UI tests require --capture to protect normal progress")
  quit(1)
  return
 var state = root.get_node("DiaryState")
 var normal = "user://window_diary_demo_save.json"
 var before = FileAccess.get_sha256(normal) if FileAccess.file_exists(normal) else "MISSING"
 state.set_process(false)
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 current_scene = game
 game.set_process(false)
 var gm = root.get_node("GMConsole")
 await process_frame
 gm.hide_console()
 key(KEY_F1)
 await process_frame
 check(gm.is_open(),"F1 opens the console")
 var input = gm.find_child("CommandInput",true,false) as LineEdit
 check(input != null,"command input exists")
 if input == null:
  quit(1)
  return
 var visitors = gm.find_child("VisitorPicker",true,false) as OptionButton
 var events = gm.find_child("EventPicker",true,false) as OptionButton
 check(visitors != null and visitors.item_count == 37,"all 37 creatures are available in the picker")
 check(events != null and events.item_count == 21,"all 21 wonders are available in the picker")
 var weather = gm.find_child("WeatherPicker",true,false) as OptionButton
 if weather != null:
  weather.select(1)
  for candidate in gm.find_children("*","Button",true,false):
   if candidate.text == "切换":
    var click = InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.pressed = true
    click.position = candidate.get_global_rect().get_center()
    root.push_input(click,true)
    var release = InputEventMouseButton.new()
    release.button_index = MOUSE_BUTTON_LEFT
    release.pressed = false
    release.position = click.position
    root.push_input(release,true)
    break
  await process_frame
  check(game.weather_mode == 1,"quick weather button responds to a real pointer event")
 input.text = "weather snow"
 input.text_submitted.emit(input.text)
 await process_frame
 check(game.weather_mode == 4,"input submission changes real weather")
 input.text = ""
 input.grab_focus()
 key(KEY_1,49)
 await process_frame
 check(game.weather_mode == 4,"typing digits does not trigger game weather shortcuts")
 gm.submit_command("pause on")
 await process_frame
 check(paused,"GM can pause gameplay")
 key(KEY_F1)
 await process_frame
 check(not gm.is_open(),"F1 closes console while paused")
 key(KEY_F1)
 await process_frame
 check(gm.is_open(),"F1 reopens console while paused")
 gm.submit_command("pause off")
 await process_frame
 check(not paused,"GM resumes gameplay")
 input.grab_focus()
 input.text = ""
 key(KEY_UP)
 await process_frame
 check(not input.text.is_empty(),"command history can be recalled")
 input.text = "weath"
 input.caret_column = input.text.length()
 key(KEY_TAB)
 await process_frame
 check(input.text.begins_with("weather"),"Tab completes a command")
 key(KEY_ESCAPE)
 await process_frame
 check(not gm.is_open(),"Escape closes the console")
 root.gui_release_focus()
 key(KEY_W,119)
 await process_frame
 check(str(game.fieldkit.get_snapshot().get("panel","")) == "weather","game shortcuts resume after closing")
 if OS.get_cmdline_user_args().has("--native-screenshot"):
  gm.show_console()
  await process_frame
  await gm.submit_command("screenshot")
  var last: Dictionary = gm.records.back()
  var message: String = str(last.get("message",""))
  check(message.begins_with("截图已保存："),"native screenshot reports a saved image")
  var picture_path: String = message.trim_prefix("截图已保存：")
  check(FileAccess.file_exists(picture_path),"native screenshot exists on disk")
  check(not gm.is_open(),"saved screenshot excludes the console overlay")
 var after = FileAccess.get_sha256(normal) if FileAccess.file_exists(normal) else "MISSING"
 check(before == after,"normal save stays byte identical")
 Engine.time_scale = 1.0
 paused = false
 print("GM_UI_TEST checks=",checks," failures=",failures)
 quit(0 if failures == 0 else 1)
