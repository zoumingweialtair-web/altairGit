extends Control
## UI35 — Pocket Fieldkit. A native overlay; scenery and state are owned by the game.
signal action(id: String, payload: Dictionary)
const Kit = preload("res://scripts/fieldkit_theme.gd")
const Icons = preload("res://scripts/fieldkit_icons.gd")
const Illustration = preload("res://scripts/guide_illustration.gd")
const WEATHER_LABELS: Array[String] = ["晴日","听雨","月夜","夕照","落雪","晨雾","风雨","晨曦"]
const WEATHER_ICONS: Array[String] = ["sun","rain","moon","dusk","snow","fog","storm","dawn"]
const SEED_IDS: Array[String] = ["sunflower","millet","berries"]
const SEED_NAMES: Array[String] = ["葵花籽","小米","浆果"]
const SEED_HINTS: Array[String] = ["山雀 · 啄木鸟","麻雀 · 绣眼鸟","松鼠 · 知更鸟"]
var hud: Control
var focus_bar: Control
var status_label: Label
var _panel: Panel
var _panel_id: String = ""
var _panel_tween: Tween
var _weather_label: Label
var _weather_icon: TextureRect
var _date_label: Label
var _visits_label: Label
var _collection_label: Label
var _food_label: Label
var _food_meter: Control
var _food_fill: ColorRect
var _recent_box: Control
var _recent_key: String = ""
var _records_key: String = ""
var _focus_clock: Label
var _focus_queue: Label
var _focus_pause: Button
var _focus_active: bool = false
var _hint: Panel
var _hint_age: float = 0.0
var _hint_id: String = ""
var _notice: Panel
var _notice_age: float = 0.0
var _selected_seed: String = "millet"
var _quantity: int = 6
var _selected_minutes: int = 25
var _feed_confirm: Button
var _feed_refill: Button
var _feed_quantity: Label
var _feed_stock_labels: Dictionary = {}
var _seed_buttons: Dictionary = {}
var _duration_buttons: Dictionary = {}
var _mixer_sliders: Dictionary = {}
var _mixer_labels: Dictionary = {}
var _audio_buttons: Dictionary = {}
var _toolbar_buttons: Dictionary = {}
var _state: Dictionary = {
 "weather_index":0,"weather_label":"晴日","day":1,"clock":"08:00",
 "visits":0,"collected":0,"total":66,"food_percent":0.0,
 "seed_stocks":{"sunflower":24,"millet":36,"berries":12},"supplies_available":true,
 "recent":[],"music_on":true,"ambience_on":true,
 "volumes":{"music":0.65,"rain":0.7,"wind":0.45,"river":0.55},
 "focus_active":false,"focus_remaining":0.0,"focus_paused":false,"focus_queued":0
}

func build() -> void:
 if is_instance_valid(hud): return
 name = "PocketFieldkit"
 size = Vector2(1440,810)
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 theme = Kit.theme()
 hud = Control.new()
 hud.name = "FieldkitHUD"
 hud.size = size
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(hud)
 _build_top()
 _build_tools()
 _build_food()
 _recent_box = Control.new()
 _recent_box.name = "RecentVisitors"
 _recent_box.position = Vector2(1360,318)
 _recent_box.size = Vector2(64,200)
 _recent_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
 hud.add_child(_recent_box)
 status_label = _label(hud,"",Rect2(0,0,1,1),18)
 status_label.hide()
 _build_focus()
 update_state({})
 set_process(true)

func _label(parent: Node, text: String, rect: Rect2, point_size: int = 18, color: Color = Kit.INK) -> Label:
 var result: Label = Label.new()
 result.text = text
 result.position = rect.position
 result.size = rect.size
 result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 result.clip_text = true
 Kit.apply_label(result,point_size,color)
 parent.add_child(result)
 return result

func _icon(parent: Node,id: String,rect: Rect2) -> TextureRect:
 var result: TextureRect = TextureRect.new()
 result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 result.texture = Icons.texture(id)
 result.position = rect.position
 result.size = rect.size
 result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(result)
 return result

func _button(parent: Node,node_name: String,text: String,rect: Rect2,callback: Callable,selected: bool = false) -> Button:
 var result: Button = Button.new()
 result.name = node_name
 result.text = text
 result.position = rect.position
 result.size = rect.size
 result.mouse_filter = Control.MOUSE_FILTER_STOP
 result.focus_mode = Control.FOCUS_ALL
 Kit.apply_button(result,selected)
 result.pressed.connect(callback)
 parent.add_child(result)
 return result

func _backplate(parent: Node,rect: Rect2,fill: Color = Kit.PAPER) -> Panel:
 var result: Panel = Panel.new()
 result.position = rect.position
 result.size = rect.size
 result.mouse_filter = Control.MOUSE_FILTER_IGNORE
 result.add_theme_stylebox_override("panel",Kit.box(fill))
 parent.add_child(result)
 return result

func _build_top() -> void:
 var weather: Button = _button(hud,"WeatherButton","",Rect2(24,22,296,50),func(): show_panel("weather"))
 weather.tooltip_text = "查看天气与风景 · 按 W 打开"
 _weather_icon = _icon(weather,"sun",Rect2(8,7,34,34))
 _weather_label = _label(weather,"晴日",Rect2(48,4,58,40),18)
 var divider: ColorRect = ColorRect.new()
 divider.color = Color("bdc4ab")
 divider.position = Vector2(113,12)
 divider.size = Vector2(1,24)
 divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
 weather.add_child(divider)
 _date_label = _label(weather,"第 1 天  08:00",Rect2(124,4,156,40),18,Kit.MUTED)
 var visits: Button = _button(hud,"RecordsButton","",Rect2(990,22,158,50),func(): show_panel("records"))
 visits.tooltip_text = "最近到访 · 每一次相遇都会留下记录"
 _icon(visits,"sparrow",Rect2(6,5,38,38))
 _visits_label = _label(visits,"来访 0",Rect2(49,5,97,38),18)
 var guide: Button = _button(hud,"CollectionButton","",Rect2(1158,22,190,50),func(): _emit_tool("guide"))
 guide.tooltip_text = "打开口袋图鉴 · 按 3"
 _icon(guide,"book",Rect2(7,8,32,32))
 _collection_label = _label(guide,"图鉴 0 / 66",Rect2(46,5,132,38),18)
 var audio_button: Button = _button(hud,"AudioButton","",Rect2(1358,22,58,50),func(): show_panel("audio"))
 _icon(audio_button,"audio",Rect2(12,8,32,32))
 audio_button.tooltip_text = "声音 · 四轨独立混音"

func _build_tools() -> void:
 var ids: Array[String] = ["observe","feed","guide","wonders","focus"]
 var titles: Array[String] = ["观察","投喂","图鉴","奇遇","陪伴"]
 var node_names: Array[String] = ["ObserveButton","FeedButton","GuideButton","WondersButton","FocusButton"]
 for i: int in range(5):
  var id: String = ids[i]
  var button: Button = _button(hud,node_names[i],"",Rect2(462+i*104,716,96,72),func(): activate_tool(id),i == 0)
  button.tooltip_text = "%s · %d" % [titles[i],i+1]
  _icon(button,id,Rect2(30,4,36,36))
  var title: Label = _label(button,titles[i],Rect2(6,39,82,28),18)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var key: Label = _label(button,str(i+1),Rect2(7,4,16,18),12,Kit.MUTED)
  key.vertical_alignment = VERTICAL_ALIGNMENT_TOP
  _toolbar_buttons[id] = button

func _build_food() -> void:
 var food: Button = _button(hud,"FoodMeterButton","",Rect2(24,742,264,46),func(): show_panel("feed"))
 food.tooltip_text = "食盘余量 · 打开投喂口袋"
 _icon(food,"feed",Rect2(8,5,32,32))
 _food_label = _label(food,"食盘 0%",Rect2(48,2,95,38),16)
 _food_meter = Control.new()
 _food_meter.name = "FoodMeter"
 _food_meter.position = Vector2(150,17)
 _food_meter.size = Vector2(96,10)
 _food_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
 food.add_child(_food_meter)
 var edge: ColorRect = ColorRect.new()
 edge.color = Kit.EDGE
 edge.size = Vector2(96,10)
 edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _food_meter.add_child(edge)
 var track: ColorRect = ColorRect.new()
 track.color = Color("c5c6b6")
 track.position = Vector2.ONE
 track.size = Vector2(94,8)
 track.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _food_meter.add_child(track)
 _food_fill = ColorRect.new()
 _food_fill.color = Kit.OLIVE
 _food_fill.position = Vector2.ONE
 _food_fill.size = Vector2(0,8)
 _food_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _food_meter.add_child(_food_fill)

func _build_focus() -> void:
 focus_bar = Control.new()
 focus_bar.name = "FocusHUD"
 focus_bar.size = size
 focus_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(focus_bar)
 var clock_plate: Panel = _backplate(focus_bar,Rect2(24,22,238,52))
 _icon(clock_plate,"focus",Rect2(9,9,32,32))
 _focus_clock = _label(clock_plate,"25:00",Rect2(50,7,122,38),24)
 _focus_pause = _button(focus_bar,"FocusPause","",Rect2(207,26,50,44),func(): action.emit("focus_pause",{}))
 _icon(_focus_pause,"pause",Rect2(10,7,28,28))
 _focus_pause.tooltip_text = "暂停 / 继续陪伴计时"
 var queue_button: Button = _button(focus_bar,"QuietQueueButton","",Rect2(24,744,278,44),func(): show_panel("records"))
 _icon(queue_button,"book",Rect2(8,5,30,30))
 _focus_queue = _label(queue_button,"新发现会安静收好",Rect2(46,4,216,34),16)
 _button(focus_bar,"FocusEnd","结束陪伴",Rect2(1240,744,176,44),func(): action.emit("focus_end",{}))
 focus_bar.hide()

func activate_tool(id: String) -> void:
 match id:
  "feed","focus": show_panel(id)
  _: _emit_tool(id)

func _emit_tool(id: String,payload: Dictionary = {}) -> void:
 close_panel()
 action.emit(id,payload)

func update_state(data: Dictionary) -> void:
 _state.merge(data,true)
 if not is_instance_valid(hud): return
 var index: int = clampi(int(_state.get("weather_index",0)),0,7)
 _weather_icon.texture = Icons.texture(WEATHER_ICONS[index])
 _weather_label.text = str(_state.get("weather_label",WEATHER_LABELS[index]))
 _date_label.text = "第 %d 天  %s" % [int(_state.get("day",1)),str(_state.get("clock","08:00"))]
 _visits_label.text = "来访 %d" % int(_state.get("visits",0))
 _collection_label.text = "图鉴 %d / %d" % [int(_state.get("collected",0)),int(_state.get("total",66))]
 var food: float = clampf(float(_state.get("food_percent",0)),0.0,100.0)
 _food_label.text = "食盘 %d%%" % roundi(food)
 _food_fill.size.x = 94.0*food/100.0
 var recent: Array = _state.get("recent",[])
 var recent_key: String = JSON.stringify(recent)
 if recent_key != _recent_key:
  _recent_key = recent_key
  _refresh_recent(recent)
 if _panel_id == "records":
  var panel_recent: Array = _state.get("focus_recent",[]) if _focus_active else _state.get("recent",[])
  if JSON.stringify(panel_recent) != _records_key:
   close_panel()
   show_panel("records")
 if _panel_id == "feed": _refresh_feed()
 if _panel_id in ["focus","audio"]: _refresh_mixer()
 if data.has("focus_active"):
  set_companion_mode(bool(_state.get("focus_active",false)),float(_state.get("focus_remaining",0)),bool(_state.get("focus_paused",false)),int(_state.get("focus_queued",0)))

func _refresh_recent(recent: Array) -> void:
 for child: Node in _recent_box.get_children():
  _recent_box.remove_child(child)
  child.queue_free()
 for i: int in range(mini(3,recent.size())):
  var entry: Dictionary = recent[i]
  var id: String = str(entry.get("id","sparrow"))
  var label: String = str(entry.get("name",id))
  var visit: Button = _button(_recent_box,"Recent_"+id,"",Rect2(0,i*62,56,54),func(): _emit_tool("guide",{"id":id}))
  _icon(visit,id,Rect2(7,6,40,40))
  visit.tooltip_text = "%s · %s\n打开这位来客的图鉴" % [label,str(entry.get("time","刚刚"))]

func show_panel(id: String,data: Dictionary = {}) -> void:
 if _focus_active and id not in ["audio","records"]: return
 if not data.is_empty(): _state.merge(data,true)
 if _panel_id == id:
  close_panel()
  return
 close_panel()
 _panel_id = id
 match id:
  "feed": _build_feed_panel()
  "focus": _build_focus_panel(false)
  "audio": _build_focus_panel(true)
  "weather": _build_weather_panel()
  "records": _build_records_panel()
  _: _panel_id = ""
 for tool: String in _toolbar_buttons:
  Kit.apply_button(_toolbar_buttons[tool],tool == id or (id == "" and tool == "observe"))
 if is_instance_valid(_panel):
  var target: Vector2 = _panel.position
  _panel.position.y += 9
  _panel.modulate.a = 0.0
  _panel_tween = create_tween().set_parallel(true)
  _panel_tween.tween_property(_panel,"position",target,0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  _panel_tween.tween_property(_panel,"modulate:a",1.0,0.14)

func close_panel() -> void:
 if is_instance_valid(_panel_tween): _panel_tween.kill()
 if is_instance_valid(_panel):
  remove_child(_panel)
  _panel.queue_free()
 _panel = null
 _panel_id = ""
 _feed_confirm = null
 _feed_refill = null
 _feed_quantity = null
 _feed_stock_labels.clear()
 _seed_buttons.clear()
 _duration_buttons.clear()
 _mixer_sliders.clear()
 _mixer_labels.clear()
 _audio_buttons.clear()
 for tool: String in _toolbar_buttons: Kit.apply_button(_toolbar_buttons[tool],tool == "observe")

func _create_panel(node_name: String,title: String,subtitle: String,rect: Rect2,icon: String) -> Panel:
 _panel = _backplate(self,rect)
 _panel.name = node_name
 _panel.mouse_filter = Control.MOUSE_FILTER_STOP
 _icon(_panel,icon,Rect2(20,16,36,36))
 _label(_panel,title,Rect2(66,14,rect.size.x-134,40),24)
 _label(_panel,subtitle,Rect2(24,57,rect.size.x-48,30),16,Kit.MUTED)
 var close_button: Button = _button(_panel,"ClosePanel","",Rect2(rect.size.x-62,14,42,38),close_panel)
 _icon(close_button,"close",Rect2(8,5,24,24))
 close_button.tooltip_text = "收起 · Esc"
 return _panel

func _build_feed_panel() -> void:
 var p: Panel = _create_panel("FeedingPocket","投喂口袋","留下一点食物，等熟悉的邻居慢慢靠近。",Rect2(442,338,540,360),"feed")
 for i: int in range(3):
  var seed: String = SEED_IDS[i]
  var card: Button = _button(p,"Seed_"+seed,"",Rect2(22+i*170,99,158,120),func(): _select_seed(seed),seed == _selected_seed)
  _icon(card,seed,Rect2(59,8,38,38))
  var title: Label = _label(card,SEED_NAMES[i],Rect2(5,47,146,28),18)
  title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var hint: Label = _label(card,SEED_HINTS[i],Rect2(5,75,146,22),13,Kit.MUTED)
  hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  var stock: Label = _label(card,"剩余 0 份",Rect2(5,95,146,20),13,Kit.MUTED)
  stock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  _feed_stock_labels[seed] = stock
  _seed_buttons[seed] = card
 _label(p,"投喂数量",Rect2(24,230,100,34),18)
 _button(p,"FeedMinus","−",Rect2(126,230,38,36),func(): _change_quantity(-1))
 _feed_quantity = _label(p,str(_quantity),Rect2(166,230,48,34),20)
 _feed_quantity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _button(p,"FeedPlus","+",Rect2(218,230,38,36),func(): _change_quantity(1))
 _feed_confirm = _button(p,"FeedConfirm","投喂",Rect2(280,228,232,42),func(): action.emit("feed",{"seed_id":_selected_seed,"amount":_quantity}),true)
 _feed_refill = _button(p,"FeedRefill","领取今日补给",Rect2(22,288,224,42),func(): action.emit("feed_refill",{}))
 _button(p,"AttractionButton","窗边布置",Rect2(262,288,250,42),func(): _emit_tool("attraction"))
 _refresh_feed()

func _select_seed(id: String) -> void:
 _selected_seed = id
 _quantity = clampi(_quantity,1,maxi(1,_stock(id)))
 _refresh_feed()

func _stock(id: String) -> int:
 var stocks: Dictionary = _state.get("seed_stocks",{})
 return maxi(0,int(stocks.get(id,0)))

func _change_quantity(delta: int) -> void:
 _quantity = clampi(_quantity+delta,1,maxi(1,_stock(_selected_seed)))
 _refresh_feed()

func _refresh_feed() -> void:
 if not is_instance_valid(_feed_confirm): return
 for id: String in _seed_buttons:
  Kit.apply_button(_seed_buttons[id],id == _selected_seed)
  _feed_stock_labels[id].text = "剩余 %d 份" % _stock(id)
 _quantity = clampi(_quantity,1,maxi(1,_stock(_selected_seed)))
 _feed_quantity.text = str(_quantity)
 var empty: bool = _stock(_selected_seed) < _quantity
 var full: bool = float(_state.get("food_percent",0.0)) >= 100.0
 _feed_confirm.disabled = empty or full
 _feed_confirm.text = "食盘已满" if full else ("口袋空了" if empty else "投喂 %d 份" % _quantity)
 var available: bool = bool(_state.get("supplies_available",true))
 _feed_refill.disabled = not available
 _feed_refill.text = "领取今日补给" if available else "今日补给已领取"

func _build_focus_panel(audio_only: bool) -> void:
 var height: int = 448 if audio_only else 568
 var p: Panel = _create_panel("SoundPocket" if audio_only else "FocusPocket","窗边声音" if audio_only else "安静陪伴","让窗外慢慢变化，新的发现会替你收好。",Rect2(444,120 if audio_only else 122,552,height),"audio" if audio_only else "focus")
 var y: int = 98
 if not audio_only:
  for i: int in range(3):
   var minutes: int = [25,45,60][i]
   var duration: Button = _button(p,"Duration%d" % minutes,"%d 分钟" % minutes,Rect2(24+i*170,98,160,44),func(): _select_duration(minutes),minutes == _selected_minutes)
   _duration_buttons[minutes] = duration
  y = 160
 _label(p,"声音混合",Rect2(24,y,160,30),18)
 _button(p,"MusicToggle","音乐 开",Rect2(268,y-3,120,34),func(): action.emit("audio",{"track":"music"}))
 _button(p,"AmbienceToggle","环境 开",Rect2(398,y-3,128,34),func(): action.emit("audio",{"track":"ambience"}))
 _audio_buttons["music"] = p.get_node("MusicToggle")
 _audio_buttons["ambience"] = p.get_node("AmbienceToggle")
 y += 52
 var tracks: Array[String] = ["music","rain","wind","river"]
 var titles: Array[String] = ["Lo-fi 音乐","雨声","风声","河流"]
 var icons: Array[String] = ["focus","rain","wind","river"]
 var volumes: Dictionary = _state.get("volumes",{})
 for i: int in range(4):
  var track: String = tracks[i]
  _icon(p,icons[i],Rect2(24,y+i*52,28,28))
  _label(p,titles[i],Rect2(62,y+i*52,126,30),18)
  var slider: HSlider = HSlider.new()
  slider.name = "Volume_"+track
  slider.position = Vector2(194,y+5+i*52)
  slider.size = Vector2(258,24)
  slider.min_value = 0.0
  slider.max_value = 1.0
  slider.step = 0.01
  slider.value = float(volumes.get(track,0.65))
  slider.mouse_filter = Control.MOUSE_FILTER_STOP
  slider.value_changed.connect(func(value: float):
   _mixer_labels[track].text = "%d%%" % roundi(value*100.0)
   action.emit("volume",{"track":track,"value":value}))
  p.add_child(slider)
  _mixer_sliders[track] = slider
  _mixer_labels[track] = _label(p,"",Rect2(472,y+i*52,56,30),16,Kit.MUTED)
 if not audio_only:
  _button(p,"FocusStart","开始陪伴 · %d 分钟" % _selected_minutes,Rect2(24,468,504,48),func():
   var minutes: int = _selected_minutes
   close_panel()
   action.emit("focus_start",{"minutes":minutes}),true)
  _label(p,"专注时收起工具栏 · 奇遇照常记录 · 可随时结束",Rect2(24,518,504,24),14,Kit.MUTED)
 else:
  _label(p,"雨、风与河流会随天气自然起伏。",Rect2(24,382,504,28),16,Kit.MUTED)
 _refresh_mixer()

func _select_duration(minutes: int) -> void:
 _selected_minutes = minutes
 for amount: int in _duration_buttons:
  Kit.apply_button(_duration_buttons[amount],amount == minutes)
 if is_instance_valid(_panel):
  var start: Button = _panel.get_node_or_null("FocusStart")
  if start != null: start.text = "开始陪伴 · %d 分钟" % minutes

func _refresh_mixer() -> void:
 var volumes: Dictionary = _state.get("volumes",{})
 for track: String in _mixer_sliders:
  var value: float = clampf(float(volumes.get(track,0.65)),0.0,1.0)
  var slider: HSlider = _mixer_sliders[track]
  if not slider.has_focus(): slider.set_value_no_signal(value)
  _mixer_labels[track].text = "%d%%" % roundi(slider.value*100.0)
 for track: String in _audio_buttons:
  var on: bool = bool(_state.get(track+"_on",true))
  var button: Button = _audio_buttons[track]
  button.text = ("音乐 " if track == "music" else "环境 ")+("开" if on else "关")
  Kit.apply_button(button,on)

func _build_weather_panel() -> void:
 var p: Panel = _create_panel("WeatherPocket","窗外气象","八种天气，八种安静看风景的方式。",Rect2(24,86,492,402),"sun")
 for i: int in range(8):
  var index: int = i
  var button: Button = _button(p,"Weather%d" % i,"",Rect2(22+(i%4)*114,100+(i/4)*92,106,82),func(): _emit_tool("weather",{"index":index}),int(_state.get("weather_index",0)) == i)
  _icon(button,WEATHER_ICONS[i],Rect2(37,5,32,32))
  var label: Label = _label(button,WEATHER_LABELS[i],Rect2(4,41,96,30),18)
  label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _label(p,"演示与调试",Rect2(24,291,200,28),16,Kit.MUTED)
 _button(p,"AtmosphereDemo","奇遇巡游",Rect2(22,329,140,44),func(): _emit_tool("demo"))
 _button(p,"CreatureLabButton","生物舞台",Rect2(172,329,140,44),func(): _emit_tool("creature_lab"))
 _button(p,"GMButton","调试指令",Rect2(322,329,146,44),func(): _emit_tool("gm"))

func _build_records_panel() -> void:
 var recent: Array = _state.get("focus_recent",[]) if _focus_active else _state.get("recent",[])
 _records_key = JSON.stringify(recent)
 var title: String = "陪伴期间的新发现" if _focus_active else "最近到访"
 var subtitle: String = "这些相遇已经安静收好，结束陪伴后也能回看。" if _focus_active else "相遇会自动记下，点开头像重温这位邻居。"
 var p: Panel = _create_panel("VisitsPocket",title,subtitle,Rect2(958,86,458,582),"bird")
 if recent.is_empty():
  _icon(p,"branch",Rect2(183,184,88,88))
  var empty_text: String = "暂时没有新的发现。\n安心做自己的事，窗外会慢慢变化。" if _focus_active else "枝头暂时很安静。\n留下一点食物，等待第一位来客。"
  var empty: Label = _label(p,empty_text,Rect2(30,292,398,76),18,Kit.MUTED)
  empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  return
 var scroll: ScrollContainer = ScrollContainer.new()
 scroll.name = "VisitScroll"
 scroll.position = Vector2(22,102)
 scroll.size = Vector2(414,388)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 p.add_child(scroll)
 var list: VBoxContainer = VBoxContainer.new()
 list.add_theme_constant_override("separation",10)
 list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(list)
 for entry: Dictionary in recent:
  var id: String = str(entry.get("id","sparrow"))
  var row: Button = Button.new()
  row.name = "Visit_"+id
  row.custom_minimum_size = Vector2(394,70)
  Kit.apply_button(row)
  list.add_child(row)
  _icon(row,id,Rect2(12,10,48,48))
  _label(row,str(entry.get("name",id)),Rect2(76,6,202,32),18)
  _label(row,"%s · 到访 %d 次" % [str(entry.get("time","刚刚")),int(entry.get("visits",1))],Rect2(76,37,286,24),15,Kit.MUTED)
  _icon(row,"book",Rect2(350,20,28,28))
  row.pressed.connect(func(): _emit_tool("guide",{"id":id}))
 _button(p,"FullRecordButton","打开完整来访记录",Rect2(22,514,414,42),func(): _emit_tool("records"))

func set_companion_mode(enabled: bool,remaining: float,time_paused: bool,queued: int) -> void:
 if not is_instance_valid(hud): return
 if enabled and not _focus_active:
  close_panel()
  hide_creature_hint()
 _focus_active = enabled
 hud.visible = not enabled
 focus_bar.visible = enabled
 var seconds: int = maxi(0,ceili(remaining))
 _focus_clock.text = "%02d:%02d" % [seconds/60,seconds%60]
 _focus_clock.modulate = Color(1,1,1,0.6) if time_paused else Color.WHITE
 var icon: TextureRect = _focus_pause.get_child(0)
 icon.texture = Icons.texture("play" if time_paused else "pause")
 _focus_queue.text = "已收好 %d 条新发现" % queued if queued > 0 else "新发现会安静收好"

func show_creature_hint(id: String,creature_name: String,visits: int,screenpos: Vector2,recorded: bool = true) -> void:
 if _focus_active: return
 hide_creature_hint()
 _hint_id = id
 _hint_age = 4.2
 var pos: Vector2 = screenpos+Vector2(24,-90)
 pos.x = clampf(pos.x,20.0,1170.0)
 pos.y = clampf(pos.y,86.0,602.0)
 _hint = _backplate(self,Rect2(pos,Vector2(246,94)))
 _hint.name = "CreatureHint"
 _icon(_hint,id,Rect2(10,10,48,48))
 _label(_hint,creature_name,Rect2(68,8,160,30),18)
 _label(_hint,"到访 %d 次 · %s" % [visits,"已记录" if recorded else "新邻居"],Rect2(68,36,166,24),14,Kit.MUTED)
 _label(_hint,"熟悉度",Rect2(14,63,66,20),13,Kit.MUTED)
 for i: int in range(5):
  var pip: ColorRect = ColorRect.new()
  pip.position = Vector2(83+i*20,69)
  pip.size = Vector2(12,8)
  pip.color = Kit.OLIVE if i < visits else Color("d9d9c7")
  pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
  _hint.add_child(pip)
 _hint.modulate.a = 0.0
 create_tween().tween_property(_hint,"modulate:a",1.0,0.12)

func hide_creature_hint() -> void:
 if is_instance_valid(_hint):
  remove_child(_hint)
  _hint.queue_free()
 _hint = null
 _hint_id = ""
 _hint_age = 0.0

func show_notice(text: String,duration: float = 3.0) -> void:
 if _focus_active: return
 if is_instance_valid(_notice):
  remove_child(_notice)
  _notice.queue_free()
 _notice = _backplate(self,Rect2(460,92,520,46))
 _notice.name = "FieldNotice"
 _icon(_notice,"check",Rect2(10,6,32,32))
 _label(_notice,text,Rect2(50,4,454,36),17)
 _notice_age = duration

func get_snapshot() -> Dictionary:
 return {"panel":_panel_id,"focus":_focus_active,"selected_seed":_selected_seed,"quantity":_quantity,"minutes":_selected_minutes,"hint_id":_hint_id,"recent_count":_recent_box.get_child_count() if is_instance_valid(_recent_box) else 0}

func _process(delta: float) -> void:
 if _hint_age > 0.0:
  _hint_age -= delta
  if _hint_age <= 0.0: hide_creature_hint()
 if _notice_age > 0.0:
  _notice_age -= delta
  if _notice_age <= 0.0 and is_instance_valid(_notice):
   remove_child(_notice)
   _notice.queue_free()
   _notice = null
