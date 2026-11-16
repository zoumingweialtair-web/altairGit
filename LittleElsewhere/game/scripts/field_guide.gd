extends Control
## Pocket Fieldkit journal. Selecting, filtering and replaying never award discoveries.
signal close_requested
signal closed
signal replay_requested(id: String)
signal favorite_changed

const Illustration = preload("res://scripts/guide_illustration.gd")
const Kit = preload("res://scripts/fieldkit_theme.gd")
const Icons = preload("res://scripts/fieldkit_icons.gd")
const PAGE_SIZE: int = 6
const CATEGORIES: Array[String] = ["birds", "animals", "insects", "scenery", "wonders"]
const PANEL_RECT: Rect2 = Rect2(190, 60, 1060, 690)

var current_filter: String = "birds"
var selected_id: String = ""
var status_filter: String = "all"
var search_query: String = ""
var page_index: int = 0
var _state: Node
var _refresh_queued: bool = false
var _visible_ids: Array[String] = []
var _page_ids: Array[String] = []
var _search: LineEdit
var _detail_scroll: ScrollContainer
var _detail_scroll_position: int = 0
var _detail_id: String = ""

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter = Control.MOUSE_FILTER_STOP
 texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 theme = Kit.theme()

func setup(state: Node, entry_id: String = "") -> void:
 if is_instance_valid(_state) and _state.changed.is_connected(_on_state_changed):
  _state.changed.disconnect(_on_state_changed)
 _state = state
 selected_id = entry_id
 if not entry_id.is_empty() and _state.get_entry_defs().has(entry_id):
  current_filter = _category(entry_id, _state.get_entry_defs())
 if not _state.changed.is_connected(_on_state_changed):
  _state.changed.connect(_on_state_changed)
 _rebuild(true)

func configure(state: Node, entry_id: String = "") -> void:
 setup(state, entry_id)

func _exit_tree() -> void:
 if is_instance_valid(_state) and _state.changed.is_connected(_on_state_changed):
  _state.changed.disconnect(_on_state_changed)

func _request_close() -> void:
 close_requested.emit()
 closed.emit()

## Compatibility entry point: favorites means every category, as in the original guide.
func set_filter(value: String) -> void:
 if value == "favorites":
  current_filter = "all"
  status_filter = "favorites"
 elif value in CATEGORIES or value == "all":
  current_filter = value
  status_filter = "all"
 else:
  return
 page_index = 0
 _rebuild()

func set_status_filter(value: String) -> void:
 if value not in ["all", "known", "favorites"]:
  return
 status_filter = value
 page_index = 0
 _rebuild()

func set_search(value: String) -> void:
 search_query = value
 page_index = 0
 _rebuild()

func set_page(value: int) -> void:
 page_index = clampi(value, 0, maxi(0, ceili(float(_visible_ids.size()) / PAGE_SIZE) - 1))
 _rebuild()

func select_entry(id: String) -> void:
 if not is_instance_valid(_state) or not _state.get_entry_defs().has(id):
  return
 selected_id = id
 if not _visible_ids.has(id):
  current_filter = _category(id, _state.get_entry_defs())
  status_filter = "all"
  search_query = ""
 _rebuild(true)

func get_visible_entry_ids() -> Array[String]:
 return _visible_ids.duplicate()

func get_page_entry_ids() -> Array[String]:
 return _page_ids.duplicate()

func get_detail_snapshot() -> Dictionary:
 var known: bool = is_instance_valid(_state) and _state.collection.has(selected_id)
 var profile: Dictionary = _profile(selected_id) if known else {}
 var visits: int = int(profile.get("visits", _state.collection.get(selected_id, {}).get("count", 0))) if is_instance_valid(_state) else 0
 return {"id": selected_id, "selected_id": selected_id, "discovered": known, "known": known,
  "replay_enabled": known, "favorite_enabled": known, "favorited": known and _favorite(selected_id),
  "filter": "favorites" if status_filter == "favorites" and current_filter == "all" else current_filter,
  "status_filter": status_filter, "query": search_query, "page": page_index,
  "page_count": maxi(1, ceili(float(_visible_ids.size()) / PAGE_SIZE)), "page_ids": _page_ids.duplicate(),
  "profile_visible": known and not profile.is_empty(), "visits": visits,
  "familiarity": mini(visits, 5) if not profile.is_empty() else 0,
  "keepsake_unlocked": known and bool(profile.get("keepsake_unlocked", false))}

func get_snapshot() -> Dictionary:
 return get_detail_snapshot()

func _on_state_changed() -> void:
 if _refresh_queued or not is_inside_tree():
  return
 _refresh_queued = true
 _deferred_refresh.call_deferred()

func _deferred_refresh() -> void:
 _refresh_queued = false
 if is_inside_tree():
  _rebuild()

func _category(id: String, defs: Dictionary) -> String:
 return str(defs.get(id, {}).get("category", "wonders"))

func _group_label(category: String) -> String:
 return {"birds": "鸟类", "animals": "动物", "insects": "昆虫", "scenery": "风景", "wonders": "奇遇"}.get(category, "全部")

func _profile(id: String) -> Dictionary:
 return _state.get_profile(id) if is_instance_valid(_state) and _state.has_method("get_profile") else {}

func _favorite(id: String) -> bool:
 return is_instance_valid(_state) and _state.has_method("is_favorite") and _state.is_favorite(id)

func _counts(category: String, defs: Dictionary) -> Vector2i:
 var found: int = 0
 var total: int = 0
 for id: String in defs:
  if category == "all" or _category(id, defs) == category:
   total += 1
   if _state.collection.has(id):
    found += 1
 return Vector2i(found, total)

func _matching_ids(defs: Dictionary) -> Array[String]:
 var ids: Array[String] = []
 var needle: String = search_query.strip_edges().to_lower()
 for id: String in defs:
  if current_filter != "all" and _category(id, defs) != current_filter:
   continue
  var known: bool = _state.collection.has(id)
  if status_filter == "known" and not known:
   continue
  if status_filter == "favorites" and not _favorite(id):
   continue
  # Unknown names and rare descriptions cannot be exposed by searching them.
  var searchable: String = str(defs[id].get("hint", "")) + " " + _group_label(_category(id, defs))
  if known:
   searchable += " " + str(defs[id].get("name", "")) + " " + str(defs[id].get("habitat", ""))
  if not needle.is_empty() and needle not in searchable.to_lower():
   continue
  ids.append(id)
 return ids

func _panel(parent: Node, rect: Rect2, fill: Color = Kit.PAPER, edge: Color = Kit.EDGE) -> Panel:
 var panel: Panel = Panel.new()
 panel.position = rect.position
 panel.size = rect.size
 panel.add_theme_stylebox_override("panel", Kit.box(fill, edge))
 panel.mouse_filter = Control.MOUSE_FILTER_STOP
 parent.add_child(panel)
 return panel

func _label(parent: Node, text: String, pos: Vector2, sz: Vector2, font_size: int = 18, color: Color = Kit.INK) -> Label:
 var label: Label = Label.new()
 label.text = text
 label.position = pos
 label.size = sz
 Kit.apply_label(label, font_size, color)
 label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
 parent.add_child(label)
 return label

func _wrap(parent: Node, text: String, width: float, font_size: int = 17, color: Color = Kit.INK) -> Label:
 var label: Label = Label.new()
 label.text = text
 label.custom_minimum_size.x = width
 label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 Kit.apply_label(label, font_size, color)
 parent.add_child(label)
 return label

func _button(parent: Node, text: String, rect: Rect2, callback: Callable, active: bool = false) -> Button:
 var button: Button = Button.new()
 button.text = text
 button.position = rect.position
 button.size = rect.size
 Kit.apply_button(button, active)
 button.pressed.connect(callback)
 parent.add_child(button)
 return button

func _icon(parent: Node, icon_id: String, pos: Vector2, extent: float = 32) -> TextureRect:
 var icon: TextureRect = TextureRect.new()
 icon.texture = Icons.texture(icon_id)
 icon.position = pos
 icon.size = Vector2(extent, extent)
 icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(icon)
 return icon

func _button_icon(button: Button, icon_id: String) -> void:
 button.icon = Icons.texture(icon_id)
 button.expand_icon = true
 button.add_theme_constant_override("icon_max_width", 26)
 button.add_theme_constant_override("h_separation", 8)

func _rule(parent: Node, pos: Vector2, width: float) -> void:
 for x: int in range(0, int(width), 8):
  var dash: ColorRect = ColorRect.new()
  dash.position = pos + Vector2(x, 0)
  dash.size = Vector2(4, 2)
  dash.color = Color("c8c4a6")
  dash.mouse_filter = Control.MOUSE_FILTER_IGNORE
  parent.add_child(dash)

func _rebuild(reveal_selection: bool = false) -> void:
 if not is_instance_valid(_state):
  return
 var restore_search: bool = is_instance_valid(_search) and _search.has_focus()
 var caret: int = _search.caret_column if restore_search else 0
 if is_instance_valid(_detail_scroll):
  _detail_scroll_position = _detail_scroll.scroll_vertical
 _detail_scroll = null
 for child: Node in get_children():
  remove_child(child)
  child.queue_free()
 var defs: Dictionary = _state.get_entry_defs()
 _visible_ids = _matching_ids(defs)
 if not _visible_ids.has(selected_id):
  selected_id = _visible_ids[0] if not _visible_ids.is_empty() else ""
 if reveal_selection and _visible_ids.has(selected_id):
  page_index = _visible_ids.find(selected_id) / PAGE_SIZE
 page_index = clampi(page_index, 0, maxi(0, ceili(float(_visible_ids.size()) / PAGE_SIZE) - 1))
 _page_ids.clear()
 for i: int in range(page_index * PAGE_SIZE, mini((page_index + 1) * PAGE_SIZE, _visible_ids.size())):
  _page_ids.append(_visible_ids[i])
 # Transparent click catcher keeps the scenery exactly as it is outside the notebook.
 var outside: Button = Button.new()
 outside.name = "CloseOutside"
 outside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 outside.flat = true
 outside.focus_mode = Control.FOCUS_NONE
 for style_name: String in ["normal", "hover", "pressed", "focus"]:
  outside.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
 outside.pressed.connect(_request_close)
 add_child(outside)
 var page: Panel = _panel(self, PANEL_RECT)
 page.name = "FieldkitGuidePanel"
 var header: Panel = _panel(page, Rect2(0, 0, 1060, 64), Kit.OLIVE, Kit.EDGE)
 header.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _icon(page, "book", Vector2(24, 14), 36)
 _label(page, "观察图鉴", Vector2(76, 12), Vector2(180, 42), 28, Kit.PAPER)
 _label(page, "POCKET FIELDKIT", Vector2(256, 23), Vector2(330, 25), 17, Color("e9edcf"))
 var total: Vector2i = _counts("all", defs)
 var counter: Panel = _panel(page, Rect2(814, 12, 152, 42), Kit.PAPER)
 var counter_text: Label = _label(counter, "%d / %d" % [total.x, total.y], Vector2(10, 5), Vector2(132, 30), 23)
 counter_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _button(page, "×", Rect2(988, 12, 48, 42), _request_close).name = "CloseButton"
 for i: int in range(CATEGORIES.size()):
  var category: String = CATEGORIES[i]
  var counts: Vector2i = _counts(category, defs)
  var tab: Button = _button(page, "%s  %d/%d" % [_group_label(category), counts.x, counts.y], Rect2(20 + i * 205, 78, 198, 44), set_filter.bind(category), current_filter == category)
  tab.name = "Filter_" + category
  _button_icon(tab, "bird" if category == "birds" else category)
 _search = LineEdit.new()
 _search.name = "GuideSearch"
 _search.position = Vector2(20, 136)
 _search.size = Vector2(388, 42)
 _search.text = search_query
 _search.placeholder_text = "搜索图鉴或观察线索…"
 _search.clear_button_enabled = true
 _search.add_theme_font_size_override("font_size", 18)
 _search.text_changed.connect(set_search)
 page.add_child(_search)
 for i: int in range(3):
  var key: String = ["all", "known", "favorites"][i]
  var button: Button = _button(page, ["全部", "已发现", "收藏"][i], Rect2(482 + i * 187, 136, 180, 42), set_status_filter.bind(key), status_filter == key)
  button.name = "Status_" + key
 _rule(page, Vector2(20, 187), 1020)
 var cards: Panel = _panel(page, Rect2(20, 200, 574, 442), Color("fcf9ef"), Color("b8bda3"))
 cards.name = "EntryGrid"
 for i: int in range(_page_ids.size()):
  var id: String = _page_ids[i]
  _card(cards, id, defs[id], Rect2(12 + (i % 3) * 187, 12 + (i / 3) * 192, 176, 180))
 if _page_ids.is_empty():
  var empty_text: String = "这里还留着空白。\n试试其他线索，或去窗边等一位来客。"
  if status_filter == "favorites":
   empty_text = "还没有收藏这一类相遇。\n打开已发现的卡片，点亮收藏。"
  var empty: Label = _label(cards, empty_text, Vector2(20, 150), Vector2(534, 90), 19, Kit.MUTED)
  empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 var page_count: int = maxi(1, ceili(float(_visible_ids.size()) / PAGE_SIZE))
 var previous: Button = _button(cards, "‹", Rect2(122, 396, 48, 34), set_page.bind(page_index - 1))
 previous.name = "PreviousPage"
 previous.disabled = page_index <= 0
 var page_label: Label = _label(cards, "%d / %d" % [page_index + 1, page_count], Vector2(182, 397), Vector2(210, 31), 18, Kit.MUTED)
 page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var next: Button = _button(cards, "›", Rect2(404, 396, 48, 34), set_page.bind(page_index + 1))
 next.name = "NextPage"
 next.disabled = page_index + 1 >= page_count
 _detail(page, defs)
 _label(page, "相遇自动留档 · 回放不增加来访次数", Vector2(24, 652), Vector2(660, 26), 16, Kit.MUTED)
 var matches: Label = _label(page, "%d 个图鉴条目" % _visible_ids.size(), Vector2(796, 652), Vector2(240, 26), 16, Kit.MUTED)
 matches.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
 if restore_search:
  _search.grab_focus.call_deferred()
  _search.set_deferred("caret_column", caret)

func _illustration(parent: Node, id: String, known: bool, rect: Rect2, animate: bool = false) -> void:
 var frame: Control = Control.new()
 frame.position = rect.position
 frame.size = rect.size
 frame.clip_contents = true
 frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(frame)
 var art: Control = Illustration.new()
 art.size = rect.size
 if _category(id, _state.get_entry_defs()) in ["birds", "animals", "insects"]:
  var center: Vector2 = Vector2(120, 64)
  var zoom: float = 1.35
  if id in ["sparrow", "tit", "robin"]:
   center = Vector2(110, 64)
   zoom = 1.7
  elif id == "butterfly":
   center = Vector2(159, 55)
   zoom = 1.5
  elif id == "woodpecker":
   center = Vector2(129, 55)
   zoom = 1.4
  elif id == "kingfisher":
   center = Vector2(112, 68)
   zoom = 1.5
  elif id == "swallow":
   center = Vector2(120, 54)
  var scale_factor: float = zoom * rect.size.x / 160.0
  art.size = Vector2(240, 120) * scale_factor
  art.position = rect.size * 0.5 - center * scale_factor
 frame.add_child(art)
 art.configure(id, known, animate)

func _card(parent: Node, id: String, definition: Dictionary, rect: Rect2) -> void:
 var known: bool = _state.collection.has(id)
 var selected: bool = selected_id == id
 var card: Button = _button(parent, "", rect, select_entry.bind(id), selected)
 card.name = "Card_" + id
 card.clip_contents = true
 if not selected:
  card.add_theme_stylebox_override("normal", Kit.box(Color("faf6e8") if known else Color("ede9dd"), Color("a1a68c")))
 _illustration(card, id, known, Rect2(8, 9, 160, 105))
 var title: Label = _label(card, str(definition.get("name", id)) if known else "未发现", Vector2(8, 120), Vector2(160, 28), 20, Kit.INK if known else Kit.MUTED)
 title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 var visits: int = int(_state.collection.get(id, {}).get("count", 0))
 var caption: Label = _label(card, ("来访 %d 次" if _category(id, _state.get_entry_defs()) in ["birds", "animals", "insects"] else "相遇 %d 次") % visits if known else "等待一次相遇", Vector2(8, 150), Vector2(160, 24), 17, Kit.MUTED)
 caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 if _favorite(id):
  _icon(card, "star", Vector2(138, 6), 28)
 if not known:
  var question: Label = _label(card, "?", Vector2(68, 47), Vector2(40, 45), 31, Kit.PAPER)
  question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _detail(page: Node, defs: Dictionary) -> void:
 var box: Panel = _panel(page, Rect2(612, 200, 428, 442), Color("fcf9ef"), Color("b8bda3"))
 box.name = "SelectedProfile"
 if selected_id.is_empty() or not defs.has(selected_id):
  var empty: Label = _label(box, "一页留白，也是一种期待。", Vector2(20, 175), Vector2(388, 72), 19, Kit.MUTED)
  empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  return
 var id: String = selected_id
 var definition: Dictionary = defs[id]
 var known: bool = _state.collection.has(id)
 var category: String = _category(id, defs)
 var profile: Dictionary = _profile(id) if known else {}
 var visitor: bool = not profile.is_empty()
 _label(box, str(definition.get("name", id)) if known else "等待新的相遇", Vector2(18, 10), Vector2(260, 38), 25)
 var badge: Panel = _panel(box, Rect2(296, 14, 112, 30), Kit.BLUE, Kit.BLUE)
 var badge_text: Label = _label(badge, str(definition.get("rarity", "已发现")) if known else "发现线索", Vector2(6, 1), Vector2(100, 27), 17, Kit.PAPER)
 badge_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 _illustration(box, id, known, Rect2(12, 51, 192, 116), true)
 if known:
  var visits: int = int(profile.get("visits", _state.collection[id].get("count", 0)))
  _label(box, "已收录", Vector2(218, 51), Vector2(188, 28), 19, Kit.OLIVE)
  _label(box, ("来访  %d 次" if visitor else "相遇  %d 次") % visits, Vector2(218, 84), Vector2(188, 27), 19)
  _label(box, "熟悉度  %d / 5" % mini(visits, 5) if visitor else "已留在观察日记", Vector2(218, 116), Vector2(188, 26), 17, Kit.MUTED)
  if visitor:
   _familiarity(box, visits, Vector2(220, 148))
 else:
  _label(box, "?", Vector2(87, 82), Vector2(50, 48), 35, Kit.PAPER)
  _label(box, "还没有认出它", Vector2(218, 70), Vector2(188, 31), 19, Kit.MUTED)
  _label(box, "留意窗外的小变化", Vector2(218, 108), Vector2(188, 44), 17, Kit.MUTED)
 _rule(box, Vector2(18, 172), 390)
 var scroll: ScrollContainer = ScrollContainer.new()
 _detail_scroll = scroll
 scroll.name = "DetailScroll"
 scroll.position = Vector2(18, 184)
 scroll.size = Vector2(390, 145 if visitor else 194)
 scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
 box.add_child(scroll)
 var content: VBoxContainer = VBoxContainer.new()
 content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 content.add_theme_constant_override("separation", 10)
 scroll.add_child(content)
 if known:
  _wrap(content, "观察位置  " + str(definition.get("habitat", "窗外")), 365)
  if visitor:
   _wrap(content, "偏好  " + str(profile.get("preference", "一段静静观察的时间")), 365, 17, Kit.OLIVE)
   _wrap(content, "个性  " + str(profile.get("personality", "安静而特别")), 365, 17, Kit.MUTED)
  _wrap(content, "相遇条件  " + str(definition.get("condition", definition.get("hint", "慢慢观察窗外。"))), 365, 17, Kit.MUTED)
  _wrap(content, str(definition.get("description", "窗外的一次相遇。")), 365, 17)
  var entry: Dictionary = _state.collection[id]
  _wrap(content, "首次  " + str(entry.get("first_seen", "已记录")) + "\n最近  " + str(entry.get("last_seen", "已记录")), 365, 17, Kit.MUTED)
  if not str(entry.get("last_weather", "")).is_empty():
   _wrap(content, "最近氛围  " + str(entry.last_weather), 365, 17, Kit.BLUE)
 else:
  _wrap(content, str(definition.get("hint", "有些相遇需要一点时间。")), 365, 20)
  _wrap(content, "留一个安静的角落。发现后，这一页会自动留下名字与来访记录。", 365, 17, Kit.MUTED)
  _wrap(content, "尚未发现的条目暂时无法收藏或回放。", 365, 17, Kit.MUTED)
 scroll.set_deferred("scroll_vertical", _detail_scroll_position if _detail_id == id else 0)
 _detail_id = id
 if visitor:
  _keepsake(box, profile)
 var favorite: Button = _button(box, "已收藏" if _favorite(id) else "收藏", Rect2(18, 394, 168, 36), _toggle_favorite.bind(id), _favorite(id))
 favorite.name = "FavoriteButton"
 _button_icon(favorite, "star")
 favorite.disabled = not known
 var replay: Button = _button(box, "观察回放", Rect2(198, 394, 210, 36), _replay.bind(id))
 replay.name = "ReplayButton"
 _button_icon(replay, "play")
 replay.disabled = not known

func _familiarity(parent: Node, visits: int, pos: Vector2) -> void:
 for i: int in range(5):
  var pip: Panel = _panel(parent, Rect2(pos + Vector2(i * 31, 0), Vector2(22, 18)), Kit.OLIVE if i < mini(visits, 5) else Kit.PAPER, Kit.OLIVE)
  pip.name = "Familiarity_" + str(i + 1)
  pip.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _keepsake(parent: Node, profile: Dictionary) -> void:
 var unlocked: bool = bool(profile.get("keepsake_unlocked", false))
 var visits: int = int(profile.get("visits", 0))
 var box: Panel = _panel(parent, Rect2(18, 338, 390, 46), Kit.SELECTED if unlocked else Color("e8e4d7"), Color("a6aa90"))
 box.name = "KeepsakeCard"
 box.tooltip_text = str(profile.get("keepsake_description", "")) if unlocked else "每次真实来访都会留下记录，来访 5 次后收下纪念。"
 var art: Control = Illustration.new()
 art.position = Vector2(8, 3)
 art.size = Vector2(44, 40)
 box.add_child(art)
 art.configure("keepsake_" + _keepsake_icon(str(profile.get("keepsake_name", ""))) if unlocked else "parcel", true)
 _label(box, str(profile.get("keepsake_name", "来访纪念")) if unlocked else "来访纪念  ·  再来 %d 次" % maxi(0, 5 - visits), Vector2(62, 6), Vector2(312, 32), 18, Kit.INK if unlocked else Kit.MUTED)

func _keepsake_icon(title: String) -> String:
 if "石" in title:
  return "stone_blue" if "深蓝" in title else ("stone_green" if "青绿" in title else "stone")
 if "羽" in title: return "feather"
 if "果壳" in title: return "shell"
 if "线团" in title: return "yarn"
 if "枝" in title or "树皮" in title: return "twig"
 if "圆片" in title: return "token"
 if "花瓣" in title: return "petal"
 if "种子" in title: return "seed"
 return "leaf"

func _toggle_favorite(id: String) -> void:
 if not _state.collection.has(id) or not _state.has_method("toggle_favorite"):
  return
 _state.toggle_favorite(id)
 favorite_changed.emit()
 _on_state_changed()

func _replay(id: String) -> void:
 if _state.collection.has(id):
  replay_requested.emit(id)
