extends Control
## A complete journal overlay. Never discovers entries merely by opening them.
signal close_requested
signal replay_requested(id: String)
signal favorite_changed

const Illustration = preload("res://scripts/guide_illustration.gd")
const INK: Color=Color("2d4845")
const SOFT: Color=Color("6e8176")
const PAPER: Color=Color("f1eddf")
const LINE: Color=Color("c8cfba")
const ORDER: Array[String]=[
 "sparrow","tit","robin","woodpecker","owl","kingfisher","swallow","magpie","white_eye","egret",
 "squirrel","hedgehog","cat","bat",
 "butterfly","luna_moth","jewel_beetle","fireflies","dragonfly","ladybug","stag_beetle",
 "scene_sun","scene_rain","scene_night","scene_dusk","scene_snow","scene_fog","scene_storm","scene_dawn",
 "ufo","meteor","supernova","aurora","star_whale","time_ripple","tree_spirit","lanterns","ghost_train","moon_gate","signal_echo",
 "aurora_crown","ember_clouds","meteor_shower","deep_one","sunken_city","sky_jellyfish","twin_moons","floating_isles","bioluminescent_tide","constellation_stag"
]
var current_filter: String="all"
var selected_id: String=""
var _state: Node
var _refresh_queued: bool=false
var _visible_ids: Array[String]=[]
var _list_scroll: ScrollContainer
var _scroll_position: int=0
var _detail_scroll: ScrollContainer
var _detail_scroll_position: int=0
var _detail_id: String=""

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP

func setup(state: Node, selected_id: String="") -> void:
 if is_instance_valid(_state) and _state.changed.is_connected(_on_state_changed):
  _state.changed.disconnect(_on_state_changed)
 _state=state
 self.selected_id=selected_id
 if not _state.changed.is_connected(_on_state_changed):_state.changed.connect(_on_state_changed)
 _rebuild()

func _exit_tree() -> void:
 if is_instance_valid(_state) and _state.changed.is_connected(_on_state_changed):
  _state.changed.disconnect(_on_state_changed)

func set_filter(value: String) -> void:
 if value not in ["all","birds","animals","insects","scenery","wonders","favorites"]:return
 if value!=current_filter and is_instance_valid(_list_scroll):_list_scroll.scroll_vertical=0
 current_filter=value
 _rebuild()

func select_entry(id: String) -> void:
 if not is_instance_valid(_state) or not _state.get_entry_defs().has(id):return
 selected_id=id
 _rebuild()

func get_visible_entry_ids() -> Array[String]:
 return _visible_ids.duplicate()

func get_detail_snapshot() -> Dictionary:
 var known: bool=is_instance_valid(_state) and _state.collection.has(selected_id)
 var profile: Dictionary=_profile(selected_id) if known else {}
 return {"id":selected_id,"discovered":known,"replay_enabled":known,"favorite_enabled":known,"filter":current_filter,"profile_visible":known and not profile.is_empty(),"visits":int(profile.get("visits",0)),"keepsake_unlocked":known and bool(profile.get("keepsake_unlocked",false))}

func _on_state_changed() -> void:
 if _refresh_queued or not is_inside_tree():return
 _refresh_queued=true
 _deferred_refresh.call_deferred()

func _deferred_refresh() -> void:
 _refresh_queued=false
 if is_inside_tree():_rebuild()

func _style(bg: Color,border: Color=LINE,radius: int=10,width: int=1) -> StyleBoxFlat:
 var s: StyleBoxFlat=StyleBoxFlat.new()
 s.bg_color=bg
 s.border_color=border
 s.set_border_width_all(width)
 s.set_corner_radius_all(radius)
 s.content_margin_left=12
 s.content_margin_right=12
 s.content_margin_top=8
 s.content_margin_bottom=8
 return s

func _label(parent: Node,text: String,pos: Vector2,sz: Vector2,font_size: int=18,color: Color=INK) -> Label:
 var l: Label=Label.new()
 l.text=text
 l.position=pos
 l.size=sz
 l.add_theme_color_override("font_color",color)
 l.add_theme_font_size_override("font_size",font_size)
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

func _wrap(parent: Node,text: String,width: float,font_size: int=17,color: Color=INK) -> Label:
 var l: Label=Label.new()
 l.text=text
 l.custom_minimum_size.x=width
 l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_color_override("font_color",color)
 l.add_theme_font_size_override("font_size",font_size)
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 return l

func _button(parent: Node,text: String,pos: Vector2,sz: Vector2,callback: Callable,active: bool=false) -> Button:
 var b: Button=Button.new()
 b.text=text
 b.position=pos
 b.size=sz
 b.add_theme_font_size_override("font_size",17)
 b.add_theme_color_override("font_color",PAPER if active else INK)
 b.add_theme_color_override("font_hover_color",INK)
 b.add_theme_color_override("font_pressed_color",PAPER)
 b.add_theme_color_override("font_disabled_color",Color("96a090"))
 b.add_theme_stylebox_override("normal",_style(Color("4f6c5c") if active else Color("e7e8d9")))
 b.add_theme_stylebox_override("hover",_style(Color("dce2ce"),Color("8fa382")))
 b.add_theme_stylebox_override("pressed",_style(Color("597761")))
 b.add_theme_stylebox_override("disabled",_style(Color("e0e3d6"),Color("d5dbc9")))
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.pressed.connect(callback)
 parent.add_child(b)
 return b

func _category(id: String,defs: Dictionary) -> String:
 if defs[id].has("category"):return str(defs[id]["category"])
 if id.begins_with("scene_"):return "scenery"
 if id in ["squirrel","hedgehog","cat","bat"]:return "animals"
 if id in ["butterfly","luna_moth","jewel_beetle","fireflies","dragonfly","ladybug","stag_beetle"]:return "insects"
 return "birds" if ORDER.find(id)<10 else "wonders"

func _group_label(category: String) -> String:
 return {"birds":"鸟类","animals":"动物","insects":"昆虫","scenery":"窗外风景","wonders":"不可思议"}.get(category,"观察条目")

func _profile(id: String) -> Dictionary:
 if _state.has_method("get_profile"):return _state.get_profile(id)
 var visits: int=int(_state.collection.get(id,{}).get("count",0))
 return {"visits":visits,"bond_label":"初次相识" if visits<3 else "渐渐熟悉","personality":"安静的观察对象","preference":"留一点安静的空间","keepsake_unlocked":visits>=5,"keepsake_name":"相遇的纪念","keepsake_description":"一次次相遇，留下的一点小小心意。"}

func _rebuild() -> void:
 if not is_instance_valid(_state):return
 if is_instance_valid(_list_scroll):_scroll_position=_list_scroll.scroll_vertical
 if is_instance_valid(_detail_scroll):_detail_scroll_position=_detail_scroll.scroll_vertical
 for child: Node in get_children():
  remove_child(child)
  child.queue_free()
 var defs: Dictionary=_state.get_entry_defs()
 var shade: ColorRect=ColorRect.new()
 shade.size=Vector2(1440,900)
 shade.color=Color(0.04,0.09,0.10,0.66)
 add_child(shade)
 var page: Panel=Panel.new()
 page.position=Vector2(90,70)
 page.size=Vector2(1260,760)
 page.add_theme_stylebox_override("panel",_style(PAPER,Color("d4d4bf"),16))
 page.mouse_filter=Control.MOUSE_FILTER_STOP
 add_child(page)
 _label(page,"窗边观察图鉴",Vector2(28,20),Vector2(550,42),29)
 _label(page,"从初次相识，到留下一份小小的纪念。",Vector2(30,64),Vector2(690,28),16,SOFT)
 _label(page,"已发现  %d / %d" % [_state.get_count(),defs.size()],Vector2(912,23),Vector2(216,36),21,INK)
 _button(page,"合上图鉴 ×",Vector2(1115,24),Vector2(120,42),func():close_requested.emit())
 var progress: Control=Control.new()
 progress.position=Vector2(912,66)
 progress.size=Vector2(322,7)
 progress.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var track: StyleBoxFlat=_style(Color("dce0d0"),Color(0,0,0,0),3,0)
 var fill: StyleBoxFlat=_style(Color("7c9a6c"),Color(0,0,0,0),3,0)
 for bar_style: StyleBoxFlat in [track,fill]:
  bar_style.content_margin_top=0
  bar_style.content_margin_bottom=0
  bar_style.content_margin_left=0
  bar_style.content_margin_right=0
 var track_panel: Panel=Panel.new()
 track_panel.add_theme_stylebox_override("panel",track)
 track_panel.size=Vector2(322,7)
 track_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 progress.add_child(track_panel)
 var fill_panel: Panel=Panel.new()
 fill_panel.add_theme_stylebox_override("panel",fill)
 fill_panel.size=Vector2(322.0*float(_state.get_count())/maxi(1,defs.size()),7)
 fill_panel.visible=_state.get_count()>0
 fill_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 progress.add_child(fill_panel)
 page.add_child(progress)
 var keys: Array[String]=["all","birds","animals","insects","scenery","wonders","favorites"]
 var labels: Array[String]=["全部","鸟类","动物","昆虫","风景","奇遇","珍藏"]
 for i in range(keys.size()):
  var counts: Vector2i=_counts(keys[i],defs)
  var tab_text: String=labels[i]+(" %d" % counts.x if keys[i]=="favorites" else " %d/%d" % [counts.x,counts.y])
  var tab: Button=_button(page,tab_text,Vector2(29+i*109,108),Vector2(104,42),set_filter.bind(keys[i]),current_filter==keys[i])
  tab.name="Filter_"+keys[i]
  tab.add_theme_font_size_override("font_size",15)
  tab.size=Vector2(104,42)
 var note: String="认识每位来客的个性与喜好，让相遇慢慢变得熟悉。"
 if current_filter=="favorites":note="把喜欢的来客和景色留在这里，随时回来看看。"
 _label(page,note,Vector2(30,161),Vector2(740,26),15,SOFT)
 _visible_ids.clear()
 for id: String in ORDER:
  if not defs.has(id):continue
  if current_filter=="all" or current_filter==_category(id,defs) or (current_filter=="favorites" and _favorite(id)):
   _visible_ids.append(id)
 if not _visible_ids.has(selected_id):
  selected_id=_visible_ids[0] if not _visible_ids.is_empty() else ""
 var scroll: ScrollContainer=ScrollContainer.new()
 _list_scroll=scroll
 scroll.name="EntryScroll"
 scroll.position=Vector2(28,196)
 scroll.size=Vector2(760,514)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 page.add_child(scroll)
 var grid: GridContainer=GridContainer.new()
 grid.columns=3
 grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",12)
 scroll.add_child(grid)
 for id: String in _visible_ids:
  _card(grid,id,defs[id],_category(id,defs))
 scroll.set_deferred("scroll_vertical",_scroll_position)
 if _visible_ids.is_empty():
  var empty: Label=_label(page,"还没有珍藏的相遇。\n打开一张已发现的卡片，点「珍藏」。",Vector2(66,355),Vector2(660,120),21,SOFT)
  empty.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 _detail(page,defs)
 _label(page,"发现自动留档 · 回放不重复计数 · 未发现的条目可以查看线索",Vector2(30,723),Vector2(1150,28),15,SOFT)

func _counts(category: String,defs: Dictionary) -> Vector2i:
 var found: int=0
 var total: int=0
 for id: String in defs:
  if category=="favorites":
   if _favorite(id):found+=1;total+=1
  elif category=="all" or _category(id,defs)==category:
   total+=1
   if _state.collection.has(id):found+=1
 return Vector2i(found,total)

func _favorite(id: String) -> bool:
 return _state.has_method("is_favorite") and _state.is_favorite(id)

func _card(parent: Node,id: String,def: Dictionary,category: String) -> void:
 var known: bool=_state.collection.has(id)
 var selected: bool=selected_id==id
 var card: Button=Button.new()
 card.name="Card_"+id
 card.custom_minimum_size=Vector2(236,172)
 card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 card.add_theme_stylebox_override("normal",_style(Color("faf7ed") if known else Color("e5e7db"),Color("718d65") if selected else LINE,10,3 if selected else 1))
 card.add_theme_stylebox_override("hover",_style(Color("e5ead8"),Color("8aa077"),10,2))
 card.add_theme_stylebox_override("pressed",_style(Color("dce5ce"),Color("6e8c61"),10,3))
 card.pressed.connect(select_entry.bind(id))
 card.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 parent.add_child(card)
 var illustration: Control=Illustration.new()
 illustration.position=Vector2(10,10)
 illustration.size=Vector2(216,91)
 card.add_child(illustration)
 illustration.configure(id,known)
 var name_text: String=str(def.get("name",id)) if known else "尚未发现"
 _label(card,name_text,Vector2(13,110),Vector2(164,27),19,INK if known else SOFT)
 var count: int=int(_state.collection.get(id,{}).get("count",0))
 var caption: String=("%s  ·  %s %d 次" % [_group_label(category),"来访" if category in ["birds","animals","insects"] else "相遇",count]) if known else (_group_label(category)+"  ·  等待相遇")
 _label(card,caption,Vector2(13,141),Vector2(208,24),13,SOFT)
 if known and bool(_profile(id).get("keepsake_unlocked",false)):
  _label(card,"◇",Vector2(175,108),Vector2(24,28),21,Color("aa8b4f"))
 if _favorite(id):
  var mark: Label=_label(card,"★",Vector2(196,106),Vector2(27,30),20,Color("aa8b4f"))
  mark.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER

func _detail(page: Node,defs: Dictionary) -> void:
 var box: Panel=Panel.new()
 box.position=Vector2(815,108)
 box.size=Vector2(419,602)
 box.add_theme_stylebox_override("panel",_style(Color("e3e6d6"),LINE,12))
 page.add_child(box)
 if selected_id.is_empty() or not defs.has(selected_id):
  _label(box,"一页留白，也是一种期待。",Vector2(25,240),Vector2(365,80),20,SOFT)
  return
 var id: String=selected_id
 var def: Dictionary=defs[id]
 var known: bool=_state.collection.has(id)
 var illustration: Control=Illustration.new()
 illustration.position=Vector2(17,17)
 illustration.size=Vector2(385,150)
 box.add_child(illustration)
 illustration.configure(id,known,true)
 var category: String=_category(id,defs)
 _label(box,str(def.get("name",id)) if known else "等待一次新的相遇",Vector2(20,178),Vector2(375,35),25,INK)
 var detail_kind: String=_group_label(category)+"  /  "+(str(def.get("rarity","观察")) if known else "发现线索")
 if known and def.has("type"):detail_kind+="  ·  "+str(def["type"])
 var kind_label: Label=_label(box,detail_kind,Vector2(21,216),Vector2(376,26),15,SOFT)
 kind_label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 var scroll: ScrollContainer=ScrollContainer.new()
 _detail_scroll=scroll
 scroll.name="DetailScroll"
 scroll.position=Vector2(20,250)
 scroll.size=Vector2(379,273)
 scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 box.add_child(scroll)
 var content: VBoxContainer=VBoxContainer.new()
 content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation",12)
 scroll.add_child(content)
 if known:
  _profile_section(content,id,category)
  _wrap(content,str(def.get("description","窗外的一次相遇。")),356,17,INK)
  var habitat: String=str(def.get("habitat","窗边"))
  var condition: String=str(def.get("condition",def.get("hint","慢慢观察窗外。")))
  _wrap(content,"观察位置  "+habitat,356,15,SOFT)
  _wrap(content,"相遇条件  "+condition,356,15,SOFT)
  var behavior: String=str(def.get("behavior",""))
  if not behavior.is_empty():_wrap(content,"观察重点  "+behavior,356,15,SOFT)
  var entry: Dictionary=_state.collection[id]
  _wrap(content,"已观察  %d 次\n首次  %s\n最近  %s" % [int(entry.get("count",0)),str(entry.get("first_seen","已记录")),str(entry.get("last_seen","已记录"))],356,14,INK)
  var weather_text: String=str(entry.get("last_weather",""))
  if not weather_text.is_empty():_wrap(content,"最近的氛围  "+weather_text,356,14,SOFT)
 else:
  _wrap(content,str(def.get("hint","有些相遇需要一点时间。")),356,19,INK)
  _wrap(content,"观察方向  "+str(def.get("habitat","窗外")),356,16,SOFT)
  _wrap(content,"相遇条件  "+str(def.get("condition","留意自然变化，或在演示中体验。")),356,16,SOFT)
  _wrap(content,"现场没有看到也没关系。事件发生后会自动记入日记，回来再慢慢看。",356,15,SOFT)
 scroll.set_deferred("scroll_vertical",_detail_scroll_position if _detail_id==id else 0)
 _detail_id=id
 var favorite: Button=_button(box,"取消珍藏" if _favorite(id) else "☆ 珍藏",Vector2(20,544),Vector2(144,42),_toggle_favorite.bind(id))
 var play: Button=_button(box,"重访这片风景" if category=="scenery" else "回到窗边回放",Vector2(178,544),Vector2(221,42),_replay.bind(id),true)
 favorite.disabled=not known
 play.disabled=not known

func _profile_section(content: VBoxContainer,id: String,category: String) -> void:
 if category not in ["birds","animals","insects"]:return
 var profile: Dictionary=_profile(id)
 var visits: int=int(profile.get("visits",0))
 var visitor: bool=category in ["birds","animals","insects"]
 var unlocked: bool=bool(profile.get("keepsake_unlocked",false))
 _wrap(content,"%s  ·  %s %d 次" % [str(profile.get("bond_label","初次相识")),"来访" if visitor else "相遇",visits],356,18,INK)
 var bond: HBoxContainer=HBoxContainer.new()
 bond.add_theme_constant_override("separation",5)
 content.add_child(bond)
 for i in range(5):
  var segment: ColorRect=ColorRect.new()
  segment.custom_minimum_size=Vector2(66,4)
  segment.color=Color("849e72") if i<mini(visits,5) else Color("cbd3be")
  segment.mouse_filter=Control.MOUSE_FILTER_IGNORE
  bond.add_child(segment)
 _wrap(content,("个性  " if visitor else "印象  ")+str(profile.get("personality","安静而特别")),356,15,SOFT)
 _wrap(content,("喜欢的布置  " if visitor else "相遇偏好  ")+str(profile.get("preference","一段静静观察的时间")),356,15,SOFT)
 var gift: PanelContainer=PanelContainer.new()
 gift.name="KeepsakeCard"
 gift.custom_minimum_size=Vector2(356,104)
 gift.add_theme_stylebox_override("panel",_style(Color("f4eddb") if unlocked else Color("dce1d1"),Color("c9c9ad"),8))
 content.add_child(gift)
 var row: HBoxContainer=HBoxContainer.new()
 row.add_theme_constant_override("separation",10)
 gift.add_child(row)
 var icon: Control=Illustration.new()
 icon.custom_minimum_size=Vector2(66,76)
 icon.size_flags_vertical=Control.SIZE_SHRINK_CENTER
 row.add_child(icon)
 icon.configure("keepsake_"+_keepsake_icon(str(profile.get("keepsake_name",""))) if unlocked else "parcel",true)
 var text_column: VBoxContainer=VBoxContainer.new()
 text_column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 text_column.add_theme_constant_override("separation",5)
 row.add_child(text_column)
 _wrap(text_column,str(profile.get("keepsake_name","相遇的纪念")) if unlocked else "一份未来的纪念",253,16,INK)
 _wrap(text_column,str(profile.get("keepsake_description","相遇留下的小小心意。")) if unlocked else "再%s %d 次，收下一份小小心意。" % ["来访" if visitor else "相遇",maxi(0,5-visits)],253,14,SOFT)

func _keepsake_icon(title: String) -> String:
 if "石" in title:
  return "stone_blue" if "深蓝" in title else ("stone_green" if "青绿" in title else "stone")
 if "羽" in title:return "feather"
 if "果壳" in title:return "shell"
 if "线团" in title:return "yarn"
 if "枝" in title or "树皮" in title:return "twig"
 if "圆片" in title:return "token"
 if "花瓣" in title:return "petal"
 if "种子" in title:return "seed"
 return "leaf"

func _toggle_favorite(id: String) -> void:
 if not _state.collection.has(id) or not _state.has_method("toggle_favorite"):return
 _state.toggle_favorite(id)
 favorite_changed.emit()
 _on_state_changed()

func _replay(id: String) -> void:
 if _state.collection.has(id):replay_requested.emit(id)
