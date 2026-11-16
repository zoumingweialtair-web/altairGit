extends CanvasLayer
## Optional global developer console. Hidden by default; all commands are whitelisted.
const Commands = preload("res://scripts/gm_commands.gd")
const Styles = preload("res://scripts/ui_lab_styles.gd")
const PAPER: Color = Color("eef2e8")
const MUTED: Color = Color("acb8b2")
const ACCENT: Color = Color("a4d8b7")
const WARN: Color = Color("f0c785")
const ERROR_COLOR: Color = Color("f0a5a0")
const WEATHER_IDS: Array[String] = ["sun","rain","night","dusk","snow","fog","storm","dawn"]
const WEATHER_LABELS: Array[String] = ["晴日","听雨","月夜","夕照","落雪","晨雾","风雨","晨曦"]
var event_ids: Array[String] = []
var event_labels: Array[String] = []
var visitor_ids: Array[String] = []
var visitor_labels: Array[String] = []
var backend: RefCounted
var overlay: Control
var panel: Panel
var command_input: LineEdit
var command_list: ItemList
var log_view: RichTextLabel
var detail: RichTextLabel
var category: OptionButton
var mode_label: Label
var commands: Array[Dictionary] = []
var filtered: Array[Dictionary] = []
var history: Array[String] = []
var history_cursor: int = 0
var history_draft: String = ""
var records: Array[Dictionary] = []
var font: SystemFont
var shown: bool = false
var completion_seed: String = ""
var completion_result: String = ""
var completion_choices: Array[String] = []
var completion_index: int = -1
var screenshot_pending: bool = false

func _ready() -> void:
 layer = 100
 process_mode = Node.PROCESS_MODE_ALWAYS
 backend = Commands.new()
 commands = backend.catalog()
 font = SystemFont.new()
 font.font_names = PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Consolas"])
 _populate_entity_options()
 _build_ui()
 _populate_categories()
 _log("info","输入 help 查看全部指令；点击左侧条目填入示例，再按 Enter 执行。")
 _log("info","方向键 ↑ ↓ 浏览历史，Tab 补全命令与对象；F1 或反引号开关，Esc 关闭。")
 if OS.get_cmdline_user_args().has("--gm-open"):
  show_console.call_deferred()

func is_open() -> bool:
 return shown

func show_console() -> void:
 if not is_instance_valid(overlay): return
 shown = true
 overlay.show()
 _update_mode()
 command_input.grab_focus()
 command_input.caret_column = command_input.text.length()

func hide_console() -> void:
 shown = false
 if is_instance_valid(panel):
  for node: Node in panel.find_children("*","OptionButton",true,false):
   (node as OptionButton).get_popup().hide()
 if is_instance_valid(overlay): overlay.hide()
 if is_instance_valid(command_input): command_input.release_focus()

func _input(event: InputEvent) -> void:
 if not event is InputEventKey: return
 var key: InputEventKey = event as InputEventKey
 if not key.pressed or key.echo: return
 if key.keycode == KEY_F1 or key.keycode == KEY_QUOTELEFT or key.physical_keycode == KEY_QUOTELEFT:
  if shown: hide_console()
  else: show_console()
  get_viewport().set_input_as_handled()
  return
 if not shown: return
 if key.keycode == KEY_ESCAPE:
  hide_console()
  get_viewport().set_input_as_handled()
 elif key.keycode == KEY_TAB:
  _complete_input()
  get_viewport().set_input_as_handled()
 elif command_input.has_focus() and key.keycode in [KEY_UP,KEY_DOWN]:
  _browse_history(-1 if key.keycode == KEY_UP else 1)
  get_viewport().set_input_as_handled()

func _style(color: Color, edge: Color = Color("4a5b54"), radius: int = 8) -> StyleBoxFlat:
 var box: StyleBoxFlat = StyleBoxFlat.new()
 box.bg_color = color
 box.border_color = edge
 box.set_border_width_all(1)
 box.set_corner_radius_all(radius)
 box.content_margin_left = 12
 box.content_margin_right = 12
 box.content_margin_top = 6
 box.content_margin_bottom = 6
 return box

func _label(value: String, rect: Rect2, font_size: int = 16, color: Color = PAPER) -> Label:
 var label: Label = Label.new()
 label.position = rect.position
 label.size = rect.size
 label.text = value
 label.add_theme_font_override("font",font)
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",color)
 label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(label)
 return label

func _button(value: String, rect: Rect2, callback: Callable, primary: bool = false) -> Button:
 var button: Button = Button.new()
 button.text = value
 button.position = rect.position
 button.size = rect.size
 button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 button.add_theme_font_override("font",font)
 button.add_theme_font_size_override("font_size",15)
 var background: Color = Color("a4d8b7") if primary else Color("293c34")
 var foreground: Color = Color("162a20") if primary else PAPER
 button.add_theme_color_override("font_color",foreground)
 button.add_theme_color_override("font_hover_color",foreground)
 button.add_theme_color_override("font_pressed_color",foreground)
 button.add_theme_stylebox_override("normal",_style(background))
 button.add_theme_stylebox_override("hover",_style(background.lightened(0.1),ACCENT))
 button.add_theme_stylebox_override("pressed",_style(background.darkened(0.07),ACCENT))
 button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,ACCENT))
 button.pressed.connect(callback)
 panel.add_child(button)
 return button

func _picker(labels: Array[String], rect: Rect2) -> OptionButton:
 var picker: OptionButton = OptionButton.new()
 picker.position = rect.position
 picker.size = rect.size
 picker.add_theme_font_override("font",font)
 picker.add_theme_font_size_override("font_size",15)
 picker.add_theme_color_override("font_color",PAPER)
 picker.add_theme_stylebox_override("normal",_style(Color("26372f")))
 picker.add_theme_stylebox_override("hover",_style(Color("32483c"),ACCENT))
 picker.add_theme_stylebox_override("pressed",_style(Color("1e2f26"),ACCENT))
 picker.get_popup().add_theme_font_override("font",font)
 picker.get_popup().add_theme_font_size_override("font_size",16)
 for value: String in labels: picker.add_item(value)
 panel.add_child(picker)
 return picker

func _build_ui() -> void:
 overlay = Control.new()
 overlay.name = "ConsoleOverlay"
 overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 overlay.mouse_filter = Control.MOUSE_FILTER_STOP
 overlay.hide()
 add_child(overlay)
 var shade: ColorRect = ColorRect.new()
 shade.color = Color(0.02,0.04,0.03,0.42)
 shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 shade.mouse_filter = Control.MOUSE_FILTER_STOP
 overlay.add_child(shade)
 panel = Panel.new()
 panel.name = "ConsolePanel"
 panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
 panel.offset_left = -560
 panel.offset_top = -340
 panel.offset_right = 560
 panel.offset_bottom = 340
 panel.mouse_filter = Control.MOUSE_FILTER_STOP
 panel.add_theme_stylebox_override("panel",_style(Color("17251f"),Color("658472"),15))
 overlay.add_child(panel)
 _label("GM 调试台",Rect2(22,17,260,36),27)
 _label("Little Elsewhere  /  指令、场景与进度工具",Rect2(24,57,660,23),14,MUTED)
 mode_label = _label("",Rect2(710,22,330,30),16,ACCENT)
 _button("关闭",Rect2(1042,22,56,34),hide_console)
 category = _picker(["全部命令"],Rect2(22,96,256,34))
 category.name = "CommandCategory"
 category.item_selected.connect(_on_category_selected)
 command_list = ItemList.new()
 command_list.name = "CommandList"
 command_list.position = Vector2(22,140)
 command_list.size = Vector2(256,276)
 command_list.add_theme_font_override("font",font)
 command_list.add_theme_font_size_override("font_size",16)
 command_list.add_theme_color_override("font_color",PAPER)
 command_list.add_theme_color_override("font_selected_color",Color("15261d"))
 command_list.add_theme_stylebox_override("panel",_style(Color("101e17")))
 command_list.add_theme_stylebox_override("selected",_style(ACCENT,ACCENT,3))
 command_list.add_theme_constant_override("v_separation",8)
 command_list.item_selected.connect(_on_command_selected)
 panel.add_child(command_list)
 detail = RichTextLabel.new()
 detail.name = "CommandHelp"
 detail.position = Vector2(22,430)
 detail.size = Vector2(256,124)
 detail.add_theme_font_override("normal_font",font)
 detail.add_theme_font_size_override("normal_font_size",14)
 detail.add_theme_color_override("default_color",MUTED)
 detail.scroll_active = true
 panel.add_child(detail)
 _button("填入所选示例",Rect2(22,564,256,34),_fill_selected_example)
 log_view = RichTextLabel.new()
 log_view.name = "Log"
 log_view.position = Vector2(300,96)
 log_view.size = Vector2(798,312)
 log_view.scroll_following = true
 log_view.selection_enabled = true
 log_view.add_theme_font_override("normal_font",font)
 log_view.add_theme_font_size_override("normal_font_size",15)
 log_view.add_theme_color_override("default_color",PAPER)
 log_view.add_theme_stylebox_override("normal",_style(Color("101a15")))
 panel.add_child(log_view)
 _build_quick_actions()
 command_input = LineEdit.new()
 command_input.name = "CommandInput"
 command_input.position = Vector2(22,614)
 command_input.size = Vector2(916,42)
 command_input.placeholder_text = "输入命令，例如：weather rain  或  help"
 command_input.add_theme_font_override("font",font)
 command_input.add_theme_font_size_override("font_size",17)
 command_input.add_theme_color_override("font_color",PAPER)
 command_input.add_theme_color_override("caret_color",ACCENT)
 command_input.add_theme_color_override("font_placeholder_color",MUTED)
 command_input.add_theme_stylebox_override("normal",_style(Color("101a15")))
 command_input.add_theme_stylebox_override("focus",_style(Color("101a15"),ACCENT))
 command_input.text_submitted.connect(submit_command)
 panel.add_child(command_input)
 var execute_button: Button = _button("执行  Enter",Rect2(954,614,144,42),_execute_input,true)
 execute_button.name = "ExecuteButton"
 _label("F1 / ` 开关    Esc 关闭    ↑ ↓ 历史    Tab 补全    ·    快捷操作会立即执行，清空进度需手动确认。",Rect2(24,658,1072,20),12,MUTED)

func _populate_entity_options() -> void:
 var definitions: Dictionary = get_node("/root/DiaryState").get_entry_defs()
 for id: String in definitions:
  var definition: Dictionary = definitions[id]
  var group: String = str(definition.get("category",""))
  if group == "wonders":
   event_ids.append(id)
   event_labels.append(str(definition.get("name",id)))
  elif group in ["birds","animals","insects"]:
   visitor_ids.append(id)
   visitor_labels.append(str(definition.get("name",id)))
func _build_quick_actions() -> void:
 _label("天气",Rect2(300,422,46,34),15,MUTED)
 var weather: OptionButton = _picker(WEATHER_LABELS,Rect2(350,422,154,34))
 weather.name = "WeatherPicker"
 _button("切换",Rect2(514,422,84,34),func() -> void: submit_command("weather "+WEATHER_IDS[weather.selected]))
 _label("奇遇",Rect2(620,422,46,34),15,MUTED)
 var event: OptionButton = _picker(event_labels,Rect2(670,422,266,34))
 event.name = "EventPicker"
 _button("播放奇遇",Rect2(948,422,150,34),func() -> void: submit_command("event "+event_ids[event.selected]))
 _label("来客",Rect2(300,468,46,34),15,MUTED)
 var visitor: OptionButton = _picker(visitor_labels,Rect2(350,468,154,34))
 visitor.name = "VisitorPicker"
 _button("邀请",Rect2(514,468,84,34),func() -> void: submit_command("spawn "+visitor_ids[visitor.selected]))
 _label("UI",Rect2(620,468,46,34),15,MUTED)
 var styles: Array[String] = []
 var scheme_definitions: Array[Dictionary] = Styles.all_styles()
 for index in range(scheme_definitions.size()):
  styles.append("%02d %s" % [index + 1, scheme_definitions[index].name])
 var style: OptionButton = _picker(styles,Rect2(670,468,160,34))
 style.name = "StylePicker"
 _button("应用",Rect2(840,468,76,34),func() -> void: submit_command("style "+str(style.selected+1)))
 _button("UI 演示",Rect2(926,468,80,34),submit_command.bind("ui lab"))
 _button("游戏",Rect2(1016,468,82,34),submit_command.bind("ui game"))
 _button("收集全部",Rect2(300,514,126,34),submit_command.bind("collect all"))
 _button("备份进度",Rect2(438,514,126,34),submit_command.bind("save backup"))
 _button("保存进度",Rect2(576,514,126,34),submit_command.bind("save now"))
 _button("截取画面",Rect2(714,514,126,34),submit_command.bind("screenshot"))
 _button("清空进度…",Rect2(852,514,246,34),_prepare_reset)
 _button("指令帮助",Rect2(300,564,126,34),submit_command.bind("help"))
 _button("查看状态",Rect2(438,564,126,34),submit_command.bind("status"))
 _button("清空日志",Rect2(576,564,126,34),_clear_log)
 _label("选项与示例均可编辑后执行。",Rect2(726,564,372,34),14,MUTED)

func _populate_categories() -> void:
 var names: Array[String] = ["全部命令"]
 for command: Dictionary in commands:
  var name: String = str(command.get("category","其他"))
  if not names.has(name): names.append(name)
 category.clear()
 for name: String in names: category.add_item(name)
 _on_category_selected(0)

func _on_category_selected(index: int) -> void:
 filtered.clear()
 command_list.clear()
 var selected: String = category.get_item_text(index)
 for command: Dictionary in commands:
  if index == 0 or str(command.get("category","其他")) == selected:
   filtered.append(command)
   command_list.add_item(str(command.get("name","")))
 if not filtered.is_empty():
  command_list.select(0)
  _show_help(0)

func _show_help(index: int) -> void:
 if index < 0 or index >= filtered.size(): return
 var command: Dictionary = filtered[index]
 detail.clear()
 detail.push_color(ACCENT)
 detail.add_text(str(command.get("usage",command.get("name","")))+"\n\n")
 detail.pop()
 detail.add_text(str(command.get("description",""))+"\n\n示例："+str(command.get("example","")))

func _on_command_selected(index: int) -> void:
 _show_help(index)
 _fill_selected_example()

func _fill_selected_example() -> void:
 var selected: PackedInt32Array = command_list.get_selected_items()
 if selected.is_empty() or selected[0] >= filtered.size(): return
 var command: Dictionary = filtered[selected[0]]
 var example: String = str(command.get("example",command.get("name","")))
 if example.strip_edges().begins_with("save reset"):
  _prepare_reset()
 else:
  _fill_input(example)

func _fill_input(value: String) -> void:
 command_input.text = value
 command_input.caret_column = value.length()
 command_input.grab_focus()
 _reset_completion()

func _prepare_reset() -> void:
 _fill_input("save reset")
 _log("warn","清空进度尚未执行。确认当前存档模式后，手动输入 save reset CONFIRM；系统会先备份再清空。")

func _execute_input() -> void:
 submit_command(command_input.text)

func submit_command(line: String) -> void:
 var trimmed: String = line.strip_edges()
 if trimmed.is_empty(): return
 if history.is_empty() or history.back() != trimmed: history.append(trimmed)
 if history.size() > 100: history.pop_front()
 history_cursor = history.size()
 history_draft = ""
 _reset_completion()
 _log("command","> "+trimmed)
 command_input.text = ""
 var scene: Node = get_tree().current_scene
 if not is_instance_valid(scene) or not scene.is_node_ready():
  _log("error","场景尚未就绪，请稍后重试。")
  return
 var result: Dictionary = backend.execute(trimmed,scene)
 var ok: bool = bool(result.get("ok",false))
 _log("ok" if ok else "error",str(result.get("message","指令未返回说明。")))
 _update_mode()
 if bool(result.get("screenshot",false)) and ok:
  await _capture_screenshot()
 elif bool(result.get("close",false)) and ok:
  hide_console()
 elif shown:
  command_input.grab_focus()

func _browse_history(direction: int) -> void:
 if history.is_empty(): return
 if history_cursor == history.size(): history_draft = command_input.text
 history_cursor = clampi(history_cursor+direction,0,history.size())
 _fill_input(history_draft if history_cursor == history.size() else history[history_cursor])

func _complete_input() -> void:
 var current: String = command_input.text
 if current != completion_result or completion_choices.is_empty():
  completion_seed = current
  completion_choices = backend.complete(current)
  completion_index = -1
 if completion_choices.is_empty():
  _log("info","没有可补全的内容；输入 help 查看支持的命令。")
  return
 completion_index = (completion_index+1)%completion_choices.size()
 completion_result = completion_choices[completion_index]
 command_input.text = completion_result
 command_input.caret_column = completion_result.length()
 command_input.grab_focus()
 if completion_choices.size() > 1 and completion_index == 0:
  _log("info","可补全："+"  ·  ".join(completion_choices.slice(0,12))+"。继续按 Tab 切换。")

func _reset_completion() -> void:
 completion_seed = ""
 completion_result = ""
 completion_choices.clear()
 completion_index = -1

func _log(kind: String, message: String) -> void:
 records.append({"kind":kind,"message":message,"time":Time.get_time_string_from_system()})
 if records.size() > 160: records.pop_front()
 if not is_instance_valid(log_view): return
 log_view.clear()
 for record: Dictionary in records:
  var color: Color = PAPER
  var prefix: String = "信息"
  match str(record.kind):
   "ok": color = ACCENT; prefix = "成功"
   "error": color = ERROR_COLOR; prefix = "失败"
   "warn": color = WARN; prefix = "提醒"
   "command": color = Color("b9d8ea"); prefix = "指令"
   _: color = MUTED
  log_view.push_color(color)
  log_view.add_text("["+str(record.time)+" "+prefix+"] "+str(record.message)+"\n")
  log_view.pop()

func _clear_log() -> void:
 records.clear()
 _log("info","日志已清空。命令历史保留，可按 ↑ ↓ 查看。")

func _update_mode() -> void:
 var path: String = get_node("/root/DiaryState")._save_path()
 var label: String = "正式进度"
 var color: Color = WARN
 if path.is_empty():
  label = "临时预览 · 不保存进度"
  color = MUTED
 elif path.get_file() == "window_diary_gm_save.json":
  label = "独立调试存档"
  color = ACCENT
 elif "test" in path.get_file():
  label = "测试存档"
  color = ACCENT
 mode_label.text = label
 mode_label.add_theme_color_override("font_color",color)

func _capture_screenshot() -> void:
 if screenshot_pending:
  _log("warn","上一张截图仍在保存，请稍后重试。")
  return
 if DisplayServer.get_name() == "headless":
  _log("error","后台运行没有可用画面，请在游戏窗口中截取画面。")
  return
 screenshot_pending = true
 hide_console()
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var directory: String = ProjectSettings.globalize_path("user://gm_screenshots")
 var error: Error = DirAccess.make_dir_recursive_absolute(directory)
 if error == OK:
  var stamp: String = Time.get_datetime_string_from_system().replace(":","").replace("-","")
  var path: String = directory.path_join("gm_"+stamp+"_"+str(Time.get_ticks_usec())+".png")
  var image: Image = get_viewport().get_texture().get_image()
  if image == null or image.is_empty():
   _log("error","未能读取当前画面。")
  else:
   error = image.save_png(path)
   if error == OK:
    _log("ok","截图已保存："+path)
    print("GM_SCREENSHOT "+path)
   else:
    _log("error","截图保存失败，错误码 "+str(error)+"。")
 else:
  _log("error","无法创建截图文件夹，错误码 "+str(error)+"。")
 screenshot_pending = false
