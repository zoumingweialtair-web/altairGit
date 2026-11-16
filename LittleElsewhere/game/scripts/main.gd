extends Control

const INK = Color("384235")
const PAPER = Color("384235")
const ACCENT = Color("7f9255")
const DIM = Color("777d6a")
const Fieldkit = preload("res://scripts/fieldkit_ui.gd")
const KitTheme = preload("res://scripts/fieldkit_theme.gd")
const FieldGuide = preload("res://scenes/field_guide.tscn")
const WEATHER_NAMES: Array[String] = ["晴日", "听雨", "月夜", "夕照", "落雪", "晨雾", "风雨", "晨曦"]
const NEW_WONDERS: Array[String] = ["aurora_crown","ember_clouds","meteor_shower","deep_one","sunken_city","sky_jellyfish","twin_moons","floating_isles","bioluminescent_tide","constellation_stag"]
const WEATHER_ENTRIES: Array[String] = ["scene_sun", "scene_rain", "scene_night", "scene_dusk", "scene_snow", "scene_fog", "scene_storm", "scene_dawn"]
const WEATHER_CAPTIONS: Array[String] = ["晴光落在枝头，河面闪着细碎的光。","雨雾隐去远山，来客在树枝间避雨。","窗灯映着月色，树上的鸟慢慢安静下来。","雪山染上浅粉，晚归的鸟停在枝头。","雪覆上枝头与屋顶，窗内仍留着暖意。","晨雾浮在宽阔水面，对岸的塔灯隐约闪动。","风拂过河湾，远处城镇的灯依然亮着。","晨曦点亮对岸屋顶，河面开始苏醒。"]

var fieldkit: Control
var focus_target: float = 0.0
var focus_paused: bool = false
var next_hud_refresh: float = 0.0
var hint_id: String = ""
var hint_until: float = 0.0
var scene_view: Node2D
var backdrop: Node2D
var normal_ui: Control
var focus_ui: Control
var focus_clock: Label
var weather_buttons: Array[Button] = []
var collection_button: Button
var music_button: Button
var sound_button: Button
var status_label: Label
var toast_panel: Panel
var toast_text: Label
var modal: Control
var music_player: AudioStreamPlayer
var rain_player: AudioStreamPlayer
var forest_player: AudioStreamPlayer
var river_player: AudioStreamPlayer
var weather_mode: int = 0
var focusing: bool = false
var elapsed: float = 0.0
var focus_elapsed: float = 0.0
var focus_new_count: int = 0
var next_visit: float = 3.0
var visitor_index: int = 0
var session_event: int = 0
var next_save: float = 30.0
var focus_start_count: int = 0
var toast_until: float = 0.0
var next_rare: float = 65.0
var visitor_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var capture_mode: bool = false
var screenshot_path: String = ""
var screenshot_state: String = "sun"
var screenshot_delay: float = 3.5
var weather_observed: float = 0.0
var scenery_recordable: bool = true
var weather_recorded: bool = false
var resume_observation_at: float = -1.0
var audio_tween: Tween
var small_font: SystemFont
var running_tests: bool = false
var _status_atmosphere_id: String = ""

func _ready() -> void:
 get_window().content_scale_size=Vector2i(1440,810)
 get_tree().auto_accept_quit = false
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 visitor_rng.randomize()
 _read_args()
 _build_theme()
 _build_scene()
 _build_interface()
 _build_audio()
 DiaryState.changed.connect(_refresh_counts)
 scene_view.encounter.connect(_encounter)
 scene_view.bird_selected.connect(_bird_card)
 if OS.get_cmdline_user_args().has("--demo"):_prepare_showcase()
 _refresh_counts()
 if not capture_mode:
  _toast("演示存档 · W 天气 · 1–5 工具 · F1 调试" if OS.get_cmdline_user_args().has("--demo") else "口袋观察站已就绪 · 投喂、收集，或留一段安静的陪伴。", 7.0)
  if not DiaryState.last_summary.is_empty():
   status_label.text = DiaryState.last_summary
   if not OS.get_cmdline_user_args().has("--demo"):_toast(DiaryState.last_summary,7.0)
 if running_tests:
  _run_ui_smoke.call_deferred()
 elif capture_mode and not OS.get_cmdline_user_args().has("--fieldkit-test"):
  _capture.call_deferred()

func _read_args() -> void:
 var args: PackedStringArray = OS.get_cmdline_user_args()
 capture_mode = args.has("--capture")
 running_tests = args.has("--ui-test")
 for a: String in args:
  if a.begins_with("--shot="):
   screenshot_path = a.trim_prefix("--shot=")
  if a.begins_with("--state="):
   screenshot_state = a.trim_prefix("--state=")
  if a.begins_with("--at="):
   screenshot_delay = clampf(float(a.trim_prefix("--at=")),0.2,25.0)

func _build_theme() -> void:
 small_font=KitTheme.font()
 theme=KitTheme.theme()

func _style(color: Color, border: Color = Color("526046"), _radius: int = 0) -> StyleBoxTexture:
 return KitTheme.box(color,border)

func _label(parent: Node, content: String, pos: Vector2, sz: Vector2, font_size: int = 18, color: Color = PAPER) -> Label:
 var l: Label = Label.new()
 l.text = content
 l.position = pos
 l.size = sz
 l.add_theme_font_size_override("font_size", font_size)
 l.add_theme_color_override("font_color", color)
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

func _button(parent: Node, content: String, pos: Vector2, sz: Vector2, action: Callable) -> Button:
 var b: Button = Button.new()
 b.text = content
 b.position = pos
 b.size = sz
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 b.pressed.connect(action)
 parent.add_child(b)
 return b

func _panel(parent: Node, pos: Vector2, sz: Vector2, color: Color) -> Panel:
 var panel: Panel = Panel.new()
 panel.position = pos
 panel.size = sz
 panel.add_theme_stylebox_override("panel", _style(color))
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(panel)
 return panel

func _build_scene() -> void:
 backdrop = $WeatherStage
 scene_view = $World
 scene_view.set_attraction(DiaryState.attraction)
 scene_view.set_layered_weather_enabled(true)
 backdrop.painted_atmospheres_changed.connect(_on_painted_atmospheres_changed)
 _on_painted_atmospheres_changed(backdrop.get_painted_atmosphere_ids())

func _on_painted_atmospheres_changed(ids: Array[String]) -> void:
 scene_view.set_painted_atmospheres(ids)

func _update_atmosphere() -> void:
 var atmosphere_state: Dictionary=scene_view.get_atmosphere_state()
 atmosphere_state["quiet"]=focusing
 backdrop.set_atmosphere_state(atmosphere_state)
 var id: String=backdrop.get_active_atmosphere_id()
 if not id.is_empty():
  var name_text: String=str(DiaryState.get_entry_defs().get(id,{}).get("name",id))
  status_label.text="窗外奇遇 · "+name_text+"  /  静静看它变化"
 elif not _status_atmosphere_id.is_empty():
  status_label.text=WEATHER_CAPTIONS[weather_mode]
 _status_atmosphere_id=id

func _build_interface() -> void:
 fieldkit=Fieldkit.new()
 fieldkit.name="PocketFieldkit"
 add_child(fieldkit)
 fieldkit.build()
 fieldkit.action.connect(_fieldkit_action)
 normal_ui=fieldkit.hud
 focus_ui=fieldkit.focus_bar
 # Keep status labels available to the existing GM and weather integration.
 var compatibility: Control=Control.new()
 compatibility.hide()
 add_child(compatibility)
 collection_button=Button.new()
 music_button=Button.new()
 sound_button=Button.new()
 status_label=Label.new()
 focus_clock=Label.new()
 for item: Control in [collection_button,music_button,sound_button,status_label,focus_clock]:compatibility.add_child(item)
 toast_panel=_panel(self,Vector2(480,92),Vector2(480,48),Color("faf6e8"))
 toast_panel.name="DiscoveryToast"
 toast_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 toast_text=_label(toast_panel,"",Vector2(16,8),Vector2(448,30),16,INK)
 toast_text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 toast_text.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 toast_panel.hide()

func _build_audio() -> void:
 music_player=_audio("res://assets/audio/lofi_loop.wav",-15.0)
 forest_player=_audio("res://assets/audio/forest_loop.wav",-21.0)
 river_player=_audio("res://assets/audio/river_loop.wav",-21.0)
 rain_player=_audio("res://assets/audio/rain_loop.wav",-80.0)
 _update_audio(false)

func _audio(path: String, volume: float) -> AudioStreamPlayer:
 var player: AudioStreamPlayer = AudioStreamPlayer.new()
 if ResourceLoader.exists(path):
  var wave: AudioStreamWAV = load(path) as AudioStreamWAV
  wave.loop_mode=AudioStreamWAV.LOOP_FORWARD
  wave.loop_begin=0
  wave.loop_end=int(wave.get_length()*wave.mix_rate)
  player.stream=wave
 player.volume_db=volume
 add_child(player)
 if player.stream != null and not capture_mode and not running_tests:
  player.play()
 return player

func _update_audio(fade: bool = true) -> void:
 if music_player == null: return
 if audio_tween != null and audio_tween.is_running(): audio_tween.kill()
 audio_tween = create_tween().set_parallel(true)
 var dur: float = 1.4 if fade else 0.01
 var music_mix: Array[float] = [-15.0,-18.0,-19.0,-16.0,-18.0,-19.0,-20.0,-16.0]
 var rain_mix: Array[float] = [-80.0,-17.0,-80.0,-80.0,-80.0,-80.0,-13.0,-80.0]
 var forest_mix: Array[float] = [-22.0,-32.0,-37.0,-26.0,-34.0,-33.0,-25.0,-25.0]
 var river_mix: Array[float] = [-24.0,-29.0,-30.0,-25.0,-35.0,-25.0,-28.0,-23.0]
 var music_db: float = music_mix[weather_mode] if DiaryState.music_on else -80.0
 var rain_db: float = rain_mix[weather_mode] if DiaryState.ambience_on else -80.0
 var forest_db: float = forest_mix[weather_mode] if DiaryState.ambience_on else -80.0
 var river_db: float = river_mix[weather_mode] if DiaryState.ambience_on else -80.0
 music_db = _mix_db(music_db,"music")
 audio_tween.tween_property(music_player,"volume_db",music_db,dur)
 rain_db = _mix_db(rain_db,"rain")
 audio_tween.tween_property(rain_player,"volume_db",rain_db,dur)
 forest_db = _mix_db(forest_db,"wind")
 audio_tween.tween_property(forest_player,"volume_db",forest_db,dur)
 river_db = _mix_db(river_db,"river")
 audio_tween.tween_property(river_player,"volume_db",river_db,dur)
 music_button.text="音乐  开" if DiaryState.music_on else "音乐  关"
 sound_button.text="自然声  开" if DiaryState.ambience_on else "自然声  关"
 _refresh_fieldkit()

func _toggle_music() -> void:
 DiaryState.music_on=not DiaryState.music_on
 DiaryState.save_state()
 _update_audio()

func _toggle_ambience() -> void:
 DiaryState.ambience_on=not DiaryState.ambience_on
 DiaryState.save_state()
 _update_audio()

func _change_weather(value: int, recordable: bool = true) -> void:
 scene_view.clear_atmosphere_events()
 backdrop.set_atmosphere_state({})
 weather_mode=clampi(value,0,WEATHER_NAMES.size()-1)
 weather_observed=0.0
 weather_recorded=false
 scenery_recordable=recordable
 resume_observation_at=-1.0
 scene_view.set_weather(weather_mode)
 backdrop.set_weather(weather_mode)
 _refresh_weather_buttons()
 _update_audio()
 status_label.text=WEATHER_CAPTIONS[weather_mode]
 _refresh_fieldkit()

func _refresh_weather_buttons() -> void:
 for i: int in range(weather_buttons.size()):
  weather_buttons[i].add_theme_stylebox_override("normal",_style(Color("d7e3aa") if i==weather_mode else Color("faf6e8"),ACCENT if i==weather_mode else Color("7f9255"),9))

func _encounter(id: String,note: String) -> void:
 session_event += 1
 var fresh: bool = DiaryState.discover(id,note,"session_%s_%d" % [str(int(Time.get_unix_time_from_system()*1000000.0)),session_event])
 DiaryState.record_context(id,WEATHER_NAMES[weather_mode])
 DiaryState.consume_food(id)
 var defs: Dictionary = DiaryState.get_entry_defs()
 var name_text: String = str(defs.get(id,{}).get("name",id))
 if focusing:
  focus_new_count=maxi(0,_observation_total()-focus_start_count)
 else:
  if _status_atmosphere_id.is_empty():status_label.text=name_text+"来过这里，观察记录已保存。"
  if fresh: _toast("新发现 · "+name_text+"  已收入图鉴",4.0)
  elif int(DiaryState.collection.get(id,{}).get("count",0))==5:
   var profile: Dictionary=DiaryState.get_profile(id)
   if bool(profile.get("keepsake_unlocked",false)):
    _toast(name_text+"留下了「"+str(profile.get("keepsake_name","小小纪念"))+"」",5.0)

func _refresh_counts() -> void:
 _refresh_fieldkit()
 if is_instance_valid(collection_button):
  collection_button.text="图鉴  %d / %d" % [DiaryState.get_count(),DiaryState.get_entry_defs().size()]

func _toast(content: String, duration: float = 4.0) -> void:
 if focusing:return
 toast_text.text=content
 toast_panel.show()
 toast_until=elapsed+duration

func _process(delta: float) -> void:
 elapsed+=delta
 if resume_observation_at>=0.0 and elapsed>=resume_observation_at:
  _resume_observation()
 if toast_panel != null and elapsed>toast_until:toast_panel.hide()
 if focusing:
  if not focus_paused:
   focus_elapsed+=delta
   DiaryState.seconds_focused+=delta
  var secs: int = int(focus_elapsed)
  focus_clock.text="%02d:%02d" % [secs/60,secs%60]
  if focus_target>0.0 and focus_elapsed>=focus_target:_end_focus()
 if scenery_recordable and not weather_recorded and not capture_mode and not running_tests:
  weather_observed+=delta
  if weather_observed>=8.0:_record_scenery()
 if elapsed>next_visit and not capture_mode and not running_tests:
  var pool: Array[String]=_visitor_pool()
  scene_view.trigger(pool[visitor_rng.randi_range(0,pool.size()-1)])
  next_visit=elapsed+visitor_rng.randf_range(22.0,36.0)
 if elapsed>next_rare and not capture_mode and not running_tests:
  var pool: Array[String]=_rare_pool()
  scene_view.trigger(pool[visitor_rng.randi_range(0,pool.size()-1)])
  next_rare=elapsed+visitor_rng.randf_range(75.0,130.0)
 if elapsed>next_save:
  DiaryState.save_state()
  next_save=elapsed+30.0
 _update_atmosphere()
 if elapsed>=next_hud_refresh:
  _refresh_fieldkit()
  next_hud_refresh=elapsed+0.25

func _visitor_pool() -> Array[String]:
 var pool: Array[String]=DiaryState.get_visit_pool(weather_mode)
 if DiaryState.food_percent>0.0 and DiaryState.attraction in ["seeds","fruit"]:
  var preferred: Array={"sunflower":["tit","woodpecker"],"millet":["sparrow","white_eye"],"berries":["squirrel","robin"]}.get(DiaryState.active_seed,[])
  for id: String in preferred:
   if pool.has(id):pool.append(id);pool.append(id)
 return pool

func _rare_pool() -> Array[String]:
 return DiaryState.get_rare_pool(weather_mode)

func _resume_observation() -> void:
 resume_observation_at=-1.0
 scenery_recordable=true
 weather_recorded=false
 weather_observed=0.0

func _record_scenery() -> void:
 weather_recorded=true
 var id: String=WEATHER_ENTRIES[weather_mode]
 var day: String=Time.get_date_string_from_system()
 var fresh: bool=DiaryState.discover(id,"在窗边看了一会儿"+WEATHER_NAMES[weather_mode]+"。","scenery_"+day+"_"+id)
 DiaryState.record_context(id,WEATHER_NAMES[weather_mode])
 if fresh:_toast("风景入册 · "+str(DiaryState.get_entry_defs()[id]["name"]),4.0)

func _observation_total() -> int:
 var total: int=0
 for entry: Dictionary in DiaryState.collection.values():
  total+=int(entry.get("count",0))
 return total

func _start_focus(minutes: int = 0) -> void:
 _close_modal()
 fieldkit.close_panel()
 if not scenery_recordable:_resume_observation()
 focusing=true
 focus_elapsed=0.0
 focus_target=float(maxi(minutes,0))*60.0
 focus_paused=false
 focus_new_count=0
 focus_start_count=_observation_total()
 toast_panel.hide()
 scene_view.set_quiet(true)
 _refresh_fieldkit()

func _end_focus() -> void:
 if not focusing:return
 focusing=false
 focus_paused=false
 fieldkit.close_panel()
 focus_new_count=maxi(0,_observation_total()-focus_start_count)
 scene_view.set_quiet(false)
 DiaryState.save_state()
 _refresh_fieldkit()
 _toast("这段陪伴 %d 分钟 · 留下了 %d 条观察记录" % [int(focus_elapsed/60),focus_new_count],7.0)

func _new_modal(title: String, subtitle: String = "") -> Panel:
 _close_modal()
 fieldkit.close_panel()
 modal=Control.new()
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(modal)
 var shade: ColorRect=ColorRect.new()
 shade.size=Vector2(1440,810)
 shade.color=Color(0.1,0.13,0.09,0.10)
 modal.add_child(shade)
 var p: Panel=_panel(modal,Vector2(340,82),Vector2(760,646),Color("faf6e8"))
 p.mouse_filter=Control.MOUSE_FILTER_STOP
 _label(p,title,Vector2(28,18),Vector2(650,38),26)
 _label(p,subtitle,Vector2(29,59),Vector2(690,30),15,DIM)
 _button(p,"关闭 ×",Vector2(640,20),Vector2(94,40),_close_modal)
 return p

func _close_modal() -> void:
 if is_instance_valid(modal):
  remove_child(modal)
  modal.queue_free()
 modal=null

func _show_collection(selected_id: String = "") -> void:
 _close_modal()
 fieldkit.close_panel()
 var guide: Control=FieldGuide.instantiate()
 modal=guide
 add_child(guide)
 guide.close_requested.connect(_close_modal)
 guide.replay_requested.connect(_replay)
 guide.setup(DiaryState,selected_id)

func _bird_card(id: String) -> void:
 if focusing:return
 if not DiaryState.collection.has(id):
  # Inspection of a replay never grants a discovery.
  _show_collection(id)
  return
 if hint_id==id and elapsed<hint_until:
  _show_collection(id)
  hint_id=""
  return
 hint_id=id
 hint_until=elapsed+6.0
 var info: Dictionary=DiaryState.collection[id]
 fieldkit.show_creature_hint(id,str(info.get("name",id)),int(info.get("count",0)),scene_view.get_actor_position(id),true)

func _replay(id: String) -> void:
 _close_modal()
 scenery_recordable=false
 if WEATHER_ENTRIES.has(id):
  _change_weather(WEATHER_ENTRIES.find(id),false)
 else:
  _prepare_event_weather(id,false)
  scene_view.trigger(id,false)
  if id in scene_view.get_creature_ids():scene_view.seek_actor_phase(id,"entry",0.0)
  var replay_seconds: float=scene_view.get_event_duration(id) if scene_view.has_method("get_event_duration") else 36.0
  resume_observation_at=elapsed+replay_seconds+2.0
 _toast("正在重访 · 点天气按钮继续日常观察" if WEATHER_ENTRIES.has(id) else "正在回放 · 不会重复增加发现次数",4.0)

func _show_records() -> void:
 var panel: Panel=_new_modal("窗外发生了什么", "最近的观察记录会保留，长时间离开也可以回来慢慢看。")
 var scroll: ScrollContainer=ScrollContainer.new()
 scroll.position=Vector2(28,104)
 scroll.size=Vector2(704,460)
 panel.add_child(scroll)
 var list: VBoxContainer=VBoxContainer.new()
 list.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 list.add_theme_constant_override("separation",10)
 scroll.add_child(list)
 if DiaryState.records.is_empty():
  var empty: Label=Label.new()
  empty.text="树上的第一位客人正在路上。也可以去「演示」邀请一位。"
  empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  list.add_child(empty)
 for rec: Dictionary in DiaryState.records:
  var row: Button=Button.new()
  var stamp: String=str(rec.get("time",""))
  if rec.get("time") is float or rec.get("time") is int:
   stamp=Time.get_datetime_string_from_unix_time(int(rec["time"])).replace("T"," ")
  row.text=str(rec.get("name","来客"))+"   ·   "+stamp+"\n"+str(rec.get("note","窗外的一次相遇"))
  row.alignment=HORIZONTAL_ALIGNMENT_LEFT
  row.custom_minimum_size=Vector2(680,74)
  row.add_theme_font_size_override("font_size",16)
  row.pressed.connect(_replay.bind(str(rec.get("id","sparrow"))))
  list.add_child(row)
 _button(panel,"模拟离开 24 小时",Vector2(28,580),Vector2(280,44),_simulate_offline)
 _label(panel,"仅生成演示记录，不修改电脑时间。",Vector2(330,584),Vector2(380,40),14,DIM)

func _simulate_offline() -> void:
 var added: Array=DiaryState.simulate_offline(24)
 _show_records()
 _toast("离线演示已完成 · 新增 %d 条观察" % added.size(),4.0)

func _show_demo(filter: String = "new") -> void:
 var panel: Panel=_new_modal("窗外奇遇放映室", "看看天空、水面和远山正在发生什么。新相遇会收入图鉴。")
 var filters: Array[String]=["new","wonders","visitors"]
 var captions: Array[String]=["窗外奇遇 · 10","全部奇遇 · 21","来客 · 21"]
 for i: int in range(3):
  var tab: Button=_button(panel,captions[i],Vector2(28+i*238,103),Vector2(228,40),_show_demo.bind(filters[i]))
  if filter==filters[i]:tab.add_theme_stylebox_override("normal",_style(Color("d7e3aa"),ACCENT))
 var scroll: ScrollContainer=ScrollContainer.new()
 scroll.position=Vector2(28,155)
 scroll.size=Vector2(704,376)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 panel.add_child(scroll)
 var grid: GridContainer=GridContainer.new()
 grid.columns=2
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",12)
 scroll.add_child(grid)
 var actions: Array=[]
 var defs: Dictionary=DiaryState.get_entry_defs()
 for id: String in defs:
  var def: Dictionary=defs[id]
  var category: String=str(def.get("category",""))
  if filter=="new" and id not in NEW_WONDERS:continue
  if filter=="wonders" and category!="wonders":continue
  if filter=="visitors" and category not in ["birds","animals","insects"]:continue
  var kind: String={"birds":"鸟类","animals":"动物","insects":"昆虫","wonders":"奇遇"}.get(category,"访客")
  if id in NEW_WONDERS:kind="窗外奇遇"
  actions.append([kind+" · "+str(def.get("name",id)),id])
 for action: Array in actions:
  var b: Button=Button.new()
  b.text=str(action[0])
  b.custom_minimum_size=Vector2(338,58)
  b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
  b.pressed.connect(_demo_trigger.bind(str(action[1])))
  grid.add_child(b)
 _button(panel,"模拟离开 24 小时",Vector2(28,549),Vector2(280,44),_simulate_offline)
 _label(panel,"1–5 工具 · W 天气 · B 来鸟 · 空格陪伴",Vector2(325,550),Vector2(405,44),15,DIM)
 _label(panel,"奇遇约停留一分钟，再慢慢回到日常；图鉴可以再次观看。",Vector2(30,603),Vector2(700,28),14,ACCENT)

func _prepare_event_weather(id: String, recordable: bool = true) -> void:
 var def: Dictionary=DiaryState.get_entry_defs().get(id,{})
 var allowed: Array=def.get("weather_ids",[0])
 if not allowed.is_empty() and weather_mode not in allowed:
  _change_weather(int(allowed[0]),recordable)

func _demo_trigger(id: String) -> void:
 _close_modal()
 _prepare_event_weather(id)
 if not scenery_recordable:
  _resume_observation()
 scene_view.trigger(id)

func _show_attractions() -> void:
 var panel: Panel=_new_modal("给窗边添一点心意", "不同的布置会让喜欢它的来客更常出现，偶尔也会遇见意外访客。")
 var defs: Dictionary=DiaryState.get_attraction_defs()
 var order: Array[String]=["seeds","fruit","flowers","lantern"]
 for i: int in range(order.size()):
  var id: String=order[i]
  var item: Dictionary=defs[id]
  var active: bool=DiaryState.attraction==id
  var b: Button=_button(panel,("正在使用 · " if active else "布置 · ")+str(item.get("name",id)),Vector2(28,110+i*102),Vector2(704,58),_choose_attraction.bind(id))
  b.alignment=HORIZONTAL_ALIGNMENT_LEFT
  if active:b.add_theme_stylebox_override("normal",_style(Color("d7e3aa"),ACCENT))
  _label(panel,str(item.get("description","")),Vector2(41,172+i*102),Vector2(674,30),15,DIM)
 _button(panel,"调整陪伴声音",Vector2(28,550),Vector2(280,46),_show_sound)
 _label(panel,"熟客来访 5 次后，会留下一份小小纪念。",Vector2(331,548),Vector2(405,54),16,ACCENT)

func _choose_attraction(id: String) -> void:
 DiaryState.set_attraction(id)
 scene_view.set_attraction(id)
 _show_attractions()
 _toast("布置已换好，等喜欢它的小邻居来访。",4.0)

func _show_sound() -> void:
 _close_modal()
 fieldkit.show_panel("audio")

func _volume_change(value: float,player: AudioStreamPlayer) -> void:
 if audio_tween != null and audio_tween.is_running():audio_tween.kill()
 if not DiaryState.music_on:music_player.volume_db=-80.0
 if not DiaryState.ambience_on:
  rain_player.volume_db=-80.0
  forest_player.volume_db=-80.0
  river_player.volume_db=-80.0
 player.volume_db=-80.0 if value<=-50.0 else value
 if player==music_player:
  DiaryState.music_on=value>-50.0
  music_button.text="音乐  开" if DiaryState.music_on else "音乐  关"
 elif value>-50.0:
  DiaryState.ambience_on=true
  sound_button.text="自然声  开"
 DiaryState.save_state()

func _sound_preset(mode: int) -> void:
 DiaryState.music_on=true
 DiaryState.ambience_on=true
 _change_weather(mode)
 DiaryState.save_state()
 _close_modal()
 _toast("声音与景色已切换，可以开始陪伴了。",4.0)

func _unhandled_key_input(event: InputEvent) -> void:
 var gm = get_node_or_null("/root/GMConsole")
 if gm != null and gm.is_open(): return
 if not event is InputEventKey or not event.pressed or event.echo:return
 if get_viewport().gui_get_focus_owner() is LineEdit and event.keycode!=KEY_ESCAPE:return
 if event.keycode==KEY_ESCAPE:
  if is_instance_valid(modal):_close_modal()
  elif focusing:_end_focus()
  else:fieldkit.close_panel()
 elif event.keycode==KEY_SPACE:
  if focusing:focus_paused=not focus_paused
  elif not is_instance_valid(modal):_start_focus(25)
 elif not focusing:
  match event.keycode:
   KEY_1:_fieldkit_action("observe",{})
   KEY_2:_close_modal();fieldkit.show_panel("feed")
   KEY_3:_show_collection()
   KEY_4:_show_demo("wonders")
   KEY_5:_close_modal();fieldkit.show_panel("focus")
   KEY_W:_close_modal();fieldkit.show_panel("weather")
   KEY_B:scene_view.trigger("sparrow")
   KEY_U:_demo_trigger("ufo")

func _notification(what: int) -> void:
 if what==NOTIFICATION_WM_CLOSE_REQUEST:
  DiaryState.save_state()
  get_tree().quit()

func _capture() -> void:
 get_tree().root.size=Vector2i(1440,810)
 get_tree().root.content_scale_size=Vector2i(1440,810)
 if screenshot_state.begins_with("fieldkit"):
  for id: String in ["sparrow","tit","robin","owl","squirrel","cat","butterfly","luna_moth","scene_sun","scene_rain","scene_dawn","aurora_crown"]:
   DiaryState.discover(id,"演示观察记录")
  for n: int in range(2):DiaryState.discover("sparrow","熟悉的邻居又来啦")
  _change_weather(0,false)
  for id: String in ["sparrow","tit","butterfly","squirrel"]:
   scene_view.trigger(id,false)
   scene_view.seek_actor_phase(id,"idle",0.2)
  _refresh_fieldkit()
  match screenshot_state:
   "fieldkit_feed":fieldkit.show_panel("feed")
   "fieldkit_guide":_show_collection("sparrow")
   "fieldkit_unknown":_show_collection("supernova")
   "fieldkit_focus":_change_weather(1,false);_start_focus(25)
   "fieldkit_focus_settings":fieldkit.show_panel("focus")
   "fieldkit_weather":fieldkit.show_panel("weather")
   "fieldkit_records":_show_records()
   "fieldkit_wonders":_show_demo("wonders")
 if not screenshot_state.begins_with("fieldkit"):
  scene_view.trigger("tit",false)
  scene_view.trigger("robin",false)
  scene_view.trigger("sparrow",false)
 var names: Array[String]=["sun","rain","night","dusk","snow","fog","storm","dawn"]
 if names.has(screenshot_state):_change_weather(names.find(screenshot_state))
 if screenshot_state.begins_with("event_"):
  var id: String=screenshot_state.trim_prefix("event_")
  _prepare_event_weather(id,false)
  scene_view.trigger(id,false)
 if screenshot_state=="showcase":
  _change_weather(2,false)
  for id: String in ["owl","luna_moth","fireflies","star_whale"]:scene_view.trigger(id,false)
 if screenshot_state=="demo" or screenshot_state=="new_events":_show_demo()
 if screenshot_state=="attractions":_show_attractions()
 if screenshot_state=="river_night":
  _change_weather(2,false)
  scene_view.trigger("lanterns",false)
  scene_view.trigger("signal_echo",false)
 if screenshot_state=="river_dawn":
  _change_weather(7,false)
  scene_view.trigger("kingfisher",false)
  scene_view.trigger("egret",false)
 if screenshot_state=="focus":
  _change_weather(1)
  _start_focus()
 if screenshot_state.begins_with("collection"):
  for id: String in ["sparrow","tit","scene_sun","scene_rain","scene_night","scene_dusk","scene_snow","ufo"]:
   DiaryState.discover(id,"窗边的一次相遇")
   DiaryState.record_context(id,"听雨" if id=="scene_rain" else "晴日")
  DiaryState.toggle_favorite("sparrow")
  _change_weather(3)
  _show_collection("sparrow")
  if screenshot_state=="collection_scenery":
   modal.set_filter("scenery")
   modal.select_entry("scene_rain")
  if screenshot_state=="collection_unknown":
   modal.set_filter("wonders")
   modal.select_entry("supernova")
  if screenshot_state=="collection_favorites":modal.set_filter("favorites")
  if screenshot_state=="collection_new":
   for id: String in ["squirrel","woodpecker","owl","luna_moth","jewel_beetle","fireflies","aurora","star_whale","time_ripple","tree_spirit"]:DiaryState.discover(id,"新的观察记录")
   modal.set_filter("wonders")
   modal.select_entry("star_whale")
 if screenshot_state=="collection_v4":
  for id: String in NEW_WONDERS:DiaryState.discover(id,"河湾新奇遇")
  _show_collection("deep_one")
  modal.set_filter("wonders")
  modal.select_entry("deep_one")
 if screenshot_state=="collection_profile":
  for n: int in range(5):DiaryState.discover("kingfisher","熟悉的蓝色身影又来了")
  _show_collection("kingfisher")
 if screenshot_state=="collection_v3":
  for id: String in DiaryState.get_entry_defs():DiaryState.discover(id,"窗边观察手记")
  _show_collection("moon_gate")
  modal.set_filter("wonders")
 await get_tree().create_timer(screenshot_delay).timeout
 await RenderingServer.frame_post_draw
 if screenshot_path.is_empty():screenshot_path="user://demo_capture.png"
 var err: Error=get_viewport().get_texture().get_image().save_png(screenshot_path)
 print("SCREENSHOT ",screenshot_path," code=",err)
 get_tree().quit(0 if err==OK else 1)

func _check(ok: bool, message: String) -> bool:
 if not ok:
  push_error("UI_CHECK_FAILED "+message)
  get_tree().quit(1)
 else:print("UI_CHECK_OK "+message)
 return ok

func _run_ui_smoke() -> void:
 DiaryState.collection.clear()
 DiaryState.favorites.clear()
 await get_tree().process_frame
 scene_view.trigger("sparrow",true)
 scene_view.seek_actor_phase("sparrow","idle",0.2)
 var bird_position: Vector2=scene_view.get_actor_position("sparrow")
 var motion: InputEventMouseMotion=InputEventMouseMotion.new()
 motion.position=bird_position
 get_viewport().push_input(motion,true)
 await get_tree().process_frame
 var click: InputEventMouseButton=InputEventMouseButton.new()
 click.position=bird_position
 click.button_index=MOUSE_BUTTON_LEFT
 click.pressed=true
 get_viewport().push_input(click,true)
 await get_tree().process_frame
 if not _check(hint_id=="sparrow","viewport bird click opens compact inspection"):return
 _bird_card("sparrow")
 if not _check(is_instance_valid(modal),"second inspection opens illustrated guide"):return
 _close_modal()
 click.pressed=false
 get_viewport().push_input(click,true)
 _show_collection("supernova")
 var unknown_before: int=DiaryState.get_count()
 if not _check(not modal.get_detail_snapshot().replay_enabled,"unknown card cannot replay"):return
 modal.select_entry("scene_snow")
 if not _check(DiaryState.get_count()==unknown_before,"viewing unknown cards grants nothing"):return
 var filters: Dictionary={"birds":10,"animals":4,"insects":7,"scenery":8,"wonders":21}
 for category: String in filters:
  modal.set_filter(category)
  if not _check(modal.get_visible_entry_ids().size()==filters[category],"filter "+category):return
 _close_modal()
 for id: String in DiaryState.get_entry_defs():
  if not id.begins_with("scene_"):scene_view.trigger(id)
 for id: String in NEW_WONDERS:
  _demo_trigger(id)
  if not _check(weather_mode in DiaryState.get_entry_defs()[id]["weather_ids"],"new wonder weather "+id):return
 for id: String in WEATHER_ENTRIES:DiaryState.discover(id,"测试风景")
 if not _check(DiaryState.get_count()==50,"fifty entries discoverable"):return
 DiaryState.toggle_favorite("sparrow")
 _show_collection()
 modal.set_filter("favorites")
 if not _check(modal.get_visible_entry_ids()==["sparrow"],"favorite filter displays saved choice"):return
 _close_modal()
 _show_records()
 _close_modal()
 _show_demo()
 _close_modal()
 _show_sound()
 _close_modal()
 _show_attractions()
 _choose_attraction("flowers")
 if not _check(DiaryState.attraction=="flowers","arrangement choice reaches state"):return
 _close_modal()
 for mode: int in range(8):_change_weather(mode)
 await get_tree().create_timer(2.2).timeout
 var weights: Array=backdrop.get_weights()
 if not _check(weights[7]>0.99 and weights[0]<0.01,"rapid weather changes end at dawn"):return
 _start_focus()
 if not _check(focusing and not normal_ui.visible,"quiet mode hides toolbar"):return
 scene_view.trigger("ufo")
 if not _check(focus_new_count==1 and not toast_panel.visible,"quiet mode records without toast"):return
 _end_focus()
 var before: int=int(DiaryState.collection["ufo"]["count"])
 _replay("ufo")
 if not _check(int(DiaryState.collection["ufo"]["count"])==before,"event replay never rewards"):return
 if not _check(resume_observation_at>elapsed,"event replay schedules normal observation recovery"):return
 _resume_observation()
 if not _check(scenery_recordable and weather_observed==0.0,"observation recovery begins a fresh eight seconds"):return
 before=int(DiaryState.collection["scene_snow"]["count"])
 _replay("scene_snow")
 if not _check(not scenery_recordable and int(DiaryState.collection["scene_snow"]["count"])==before,"scenery replay never rewards"):return
 _change_weather(0)
 _record_scenery()
 before=int(DiaryState.collection["scene_sun"]["count"])
 _change_weather(0)
 _record_scenery()
 if not _check(int(DiaryState.collection["scene_sun"]["count"])==before,"same day scenery cannot be farmed"):return
 _demo_trigger("butterfly")
 if not _check(weather_mode in DiaryState.get_entry_defs()["butterfly"].get("weather_ids",[]),"butterfly demo has compatible weather"):return
 DiaryState.simulate_offline(24)
 if not _check(DiaryState.records.size()>0,"offline observations available"):return
 print("UI_SMOKE_OK weather/guide/favorites/unknown/focus/replay/offline")
 get_tree().quit()

func _mix_db(base: float, track: String) -> float:
 var gain: float=float(DiaryState.mixer_volumes.get(track,0.7))
 return -80.0 if gain<=0.001 or base<=-80.0 else base+linear_to_db(gain)

func _refresh_fieldkit() -> void:
 if not is_instance_valid(fieldkit):return
 var recent: Array=[]
 var seen: Array[String]=[]
 for rec: Dictionary in DiaryState.records:
  var id: String=str(rec.get("id",""))
  if id in seen:continue
  if str(DiaryState.get_entry_defs().get(id,{}).get("category","")) not in ["birds","animals","insects"]:continue
  seen.append(id)
  var row: Dictionary=rec.duplicate()
  row["visits"]=int(DiaryState.collection.get(id,{}).get("count",0))
  recent.append(row)
  if recent.size()>=12:break
 var now: Dictionary=Time.get_datetime_dict_from_system()
 var first_day: float=Time.get_unix_time_from_system()
 for entry: Dictionary in DiaryState.collection.values():
  first_day=minf(first_day,float(entry.get("first_timestamp",first_day)))
 var day_number: int=maxi(1,int((Time.get_unix_time_from_system()-first_day)/86400.0)+1)
 var focus_recent: Array=[]
 if focusing:
  focus_new_count=maxi(0,_observation_total()-focus_start_count)
  for i: int in range(mini(focus_new_count,DiaryState.records.size())):
   var row: Dictionary=DiaryState.records[i].duplicate()
   row["visits"]=int(DiaryState.collection.get(row.get("id",""),{}).get("count",0))
   focus_recent.append(row)
 var remaining: float=maxf(0.0,focus_target-focus_elapsed) if focus_target>0.0 else focus_elapsed
 fieldkit.update_state({"weather_index":weather_mode,"weather_label":WEATHER_NAMES[weather_mode],
  "day":day_number,"clock":"%02d:%02d" % [int(now.hour),int(now.minute)],
  "visits":_visitor_total(),"collected":DiaryState.get_count(),"total":50,
  "food_percent":DiaryState.food_percent,"seed_stocks":DiaryState.seed_stocks.duplicate(),
  "supplies_available":DiaryState.supplies_available(),"recent":recent,
  "music_on":DiaryState.music_on,"ambience_on":DiaryState.ambience_on,"volumes":DiaryState.mixer_volumes.duplicate(),
  "focus_recent":focus_recent,"focus_active":focusing,"focus_remaining":remaining,"focus_paused":focus_paused,"focus_queued":focus_new_count})

func _fieldkit_action(id: String, data: Dictionary) -> void:
 match id:
  "observe":_close_modal();fieldkit.close_panel()
  "guide":_show_collection(str(data.get("id","")))
  "wonders":_show_demo("wonders")
  "records":_show_records()
  "attraction":_show_attractions()
  "weather":_change_weather(int(data.get("index",0)))
  "feed":
   var result: Dictionary=DiaryState.feed(str(data.get("seed_id","millet")),int(data.get("amount",1)))
   if bool(result.get("ok",false)):
    scene_view.set_attraction(DiaryState.attraction)
    next_visit=minf(next_visit,elapsed+3.5)
   _toast(str(result.get("message","")))
   _refresh_fieldkit()
  "feed_refill":
   var success: bool=DiaryState.claim_supplies()
   _toast("今日补给已放入口袋。" if success else "今天的补给已领取，明天再来看看。")
   _refresh_fieldkit()
  "focus_start":_start_focus(int(data.get("minutes",25)))
  "focus_end":_end_focus()
  "focus_pause":focus_paused=not focus_paused;_refresh_fieldkit()
  "audio":
   if str(data.get("track","music"))=="ambience":_toggle_ambience()
   else:_toggle_music()
  "volume":
   DiaryState.set_mix(str(data.get("track","music")),float(data.get("value",0.7)))
   _update_audio(false)
  "replay":_replay(str(data.get("id","sparrow")))
  "gm":
   _close_modal()
   fieldkit.close_panel()
   var console: Node=get_node_or_null("/root/GMConsole")
   if console:console.show_console()
  "demo":_show_demo()
  "creature_lab":
   _close_modal()
   fieldkit.close_panel()
   var executable: String=OS.get_executable_path()
   OS.create_process(executable,["--path",ProjectSettings.globalize_path("res://"),"res://scenes/creature_lab.tscn","--","--ui-lab"])

func _prepare_showcase() -> void:
 get_tree().root.title="Little Elsewhere · Pocket Fieldkit Demo"
 if DiaryState.collection.is_empty():
  for id: String in ["sparrow","tit","robin","owl","squirrel","cat","butterfly","luna_moth","scene_sun","scene_rain","scene_dawn","aurora_crown"]:
   DiaryState.discover(id,"演示样例 · 用于体验图鉴交互")
  for n: int in range(2):DiaryState.discover("sparrow","演示样例 · 熟悉的邻居")
 _change_weather(0,false)
 for id: String in ["sparrow","squirrel","butterfly"]:scene_view.trigger(id,false)
 next_visit=18.0
 _resume_observation()

func _visitor_total() -> int:
 var total: int=0
 for id: String in DiaryState.collection:
  if str(DiaryState.get_entry_defs().get(id,{}).get("category","")) in ["birds","animals","insects"]:
   total+=int(DiaryState.collection[id].get("count",0))
 return total
