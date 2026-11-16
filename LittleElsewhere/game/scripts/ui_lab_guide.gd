extends Control
## Self-contained sample guide for the UI laboratory. Never writes game progress.
signal closed
signal replay_requested(entry_id: String)

const Illustration = preload("res://scripts/guide_illustration.gd")
const IDS: Array[String] = ["sparrow", "kingfisher", "owl", "luna_moth", "aurora_crown", "twin_moons"]
const KNOWN: Array[String] = ["sparrow", "kingfisher", "owl", "luna_moth"]
const SAMPLE: Dictionary = {
 "sparrow": {"name":"麻雀", "type":"阳台来客", "rarity":"常见", "habitat":"低枝与喂鸟食盘", "description":"先在树枝上张望，再落到食盘旁。熟悉的身影，也有新的小动作。", "hint":"看看树枝和喂鸟食盘。"},
 "kingfisher": {"name":"翠鸟", "type":"水边来客", "rarity":"稀有", "habitat":"河岸低枝与水面上方", "description":"一抹蓝色贴着水面掠过，又轻轻落回低枝。河面恢复平静之后，它还在耐心地等。", "hint":"晨光里的河岸，也许藏着一小片蓝。"},
 "owl": {"name":"林鸮", "type":"夜间树梢来客", "rarity":"稀有", "habitat":"月色下的高枝与树冠边缘", "description":"它在高枝上眨眨眼，再慢慢转头，好像也想知道窗内的人在读什么。夜色里，多了一位安静的邻居。", "hint":"夜深后，高枝上可能有一双安静的眼睛。"},
 "luna_moth": {"name":"月蛾", "type":"夜间花边来客", "rarity":"稀有", "habitat":"月夜的花盆与树叶之间", "description":"浅绿色翅影绕过叶尖，像一张被风翻动的小纸片。它在月光与树影之间盘旋，把夜晚飞得很慢。", "hint":"月光里的浅绿色翅膀，和白天的蝶不一样。"},
 "aurora_crown": {"name":"极光冠冕", "type":"天空奇观", "rarity":"稀有", "habitat":"雪山上方与夜空深处", "description":"细长的光柱在高处相遇，慢慢展开一顶没有重量的冠冕。", "hint":"平缓的极光之外，还有一种会向天顶聚拢的光。"},
 "twin_moons": {"name":"双月临空", "type":"幻想天空奇遇", "rarity":"传说", "habitat":"山脊上方的月夜天空", "description":"一轮浅淡的月亮慢慢来到另一轮身旁，两道月光在水上并行。", "hint":"今晚的水面，会不会有两条月光铺成的路？"}
}

var _style: Dictionary = {}
var _selected: String = "sparrow"
var _favorites: Array[String] = []
var _font: Font
var _title_font: Font
var _paper: Color
var _ink: Color
var _accent: Color
var _muted: Color
var _border: Color
var _corner: int = 12

func build(style: Dictionary) -> void:
 _style = style.duplicate()
 _paper = style.get("paper",Color("eee8d9"))
 _ink = style.get("ink",Color("283d36"))
 _accent = style.get("accent",Color("567e60"))
 _muted = style.get("muted",Color("65736a"))
 _border = style.get("border",Color("b7bcac"))
 _corner = int(style.get("corner",12))
 _font = _make_font(str(style.get("font","Microsoft YaHei")))
 _title_font = _make_font(str(style.get("title_font","Georgia")))
 size = Vector2(1440,810)
 mouse_filter = Control.MOUSE_FILTER_STOP
 clip_contents = true
 _render()

func get_snapshot() -> Dictionary:
 return {"selected":_selected,"known":_selected in KNOWN,"favorited":_selected in _favorites,"visible_count":IDS.size(),"layout":str(_style.get("id","field_notes"))}

func get_preview_state() -> Dictionary:
 return {"selected":_selected,"favorites":_favorites.duplicate()}

func restore_preview_state(state: Dictionary) -> void:
 var selected: String = str(state.get("selected","sparrow"))
 if selected in IDS: _selected = selected
 _favorites.clear()
 for id in state.get("favorites",[]):
  if str(id) in KNOWN and not _favorites.has(str(id)): _favorites.append(str(id))
 if not _style.is_empty(): _render()
func select_entry(id: String) -> void:
 if id not in IDS:return
 _selected = id
 if not _style.is_empty():_render()

func _make_font(primary: String) -> SystemFont:
 var result: SystemFont = SystemFont.new()
 result.font_names = PackedStringArray([primary,"Microsoft YaHei UI","Microsoft YaHei","Arial"])
 return result

func _render() -> void:
 for node: Node in get_children():
  remove_child(node)
  node.queue_free()
 if bool(_style.get("lightweight",false)):
  _compact_drawer()
  return
 var shade: ColorRect = ColorRect.new()
 shade.size = size
 shade.color = Color(0.025,0.045,0.045,0.38)
 shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(shade)
 match str(_style.get("id","field_notes")):
  "quiet_glass":_glass_drawer()
  "pocket_pixels":_pixel_console()
  "woodland_post":_post_album()
  "moon_observatory":_observatory()
  "botanical_cabinet":_cabinet()
  "rain_radio":_radio_log()
  "paper_theatre":_paper_book()
  "ink_stillness":_ink_scroll()
  "celestial_archive":_star_archive()
  _:_field_notes()

func _box(rect: Rect2, fill: Color, edge: Color, radius: int = -1, thickness: int = 1) -> Panel:
 var p: Panel = Panel.new()
 p.position = rect.position
 p.size = rect.size
 p.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var s: StyleBoxFlat = StyleBoxFlat.new()
 s.bg_color = fill
 s.border_color = edge
 s.set_border_width_all(thickness)
 s.set_corner_radius_all(_corner if radius<0 else radius)
 p.add_theme_stylebox_override("panel",s)
 add_child(p)
 return p

func _line(rect: Rect2, color: Color) -> void:
 var c: ColorRect = ColorRect.new()
 c.position=rect.position
 c.size=rect.size
 c.color=color
 c.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(c)

func _label(content: String, rect: Rect2, points: int = 18, color: Color = Color.TRANSPARENT, title: bool = false, center: bool = false) -> Label:
 var l: Label = Label.new()
 l.text=content
 l.position=rect.position
 l.size=rect.size
 l.add_theme_font_override("font",_title_font if title else _font)
 l.add_theme_font_size_override("font_size",points)
 l.add_theme_color_override("font_color",_ink if color==Color.TRANSPARENT else color)
 l.mouse_filter=Control.MOUSE_FILTER_IGNORE
 l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
 if center:l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 add_child(l)
 return l

func _button(content: String, rect: Rect2, action: Callable, active: bool = false) -> Button:
 var b: Button = Button.new()
 b.text=content
 b.position=rect.position
 b.size=rect.size
 b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 b.add_theme_font_override("font",_font)
 b.add_theme_font_size_override("font_size",17)
 var normal: StyleBoxFlat = StyleBoxFlat.new()
 normal.bg_color=_accent if active else _paper
 normal.border_color=_accent if active else _border
 normal.set_border_width_all(1)
 normal.set_corner_radius_all(_corner)
 normal.content_margin_left=12
 normal.content_margin_right=12
 b.add_theme_stylebox_override("normal",normal)
 var hover: StyleBoxFlat=normal.duplicate() as StyleBoxFlat
 hover.bg_color=normal.bg_color.lerp(_ink,0.10)
 hover.border_color=_accent
 b.add_theme_stylebox_override("hover",hover)
 var pressed: StyleBoxFlat=hover.duplicate() as StyleBoxFlat
 pressed.bg_color=normal.bg_color.lerp(_ink,0.19)
 b.add_theme_stylebox_override("pressed",pressed)
 var disabled_style: StyleBoxFlat=normal.duplicate() as StyleBoxFlat
 disabled_style.bg_color=_paper.lerp(_border,0.2)
 b.add_theme_stylebox_override("disabled",disabled_style)
 var ring: StyleBoxFlat=StyleBoxFlat.new()
 ring.bg_color=Color.TRANSPARENT
 ring.border_color=_accent
 ring.set_border_width_all(3)
 ring.set_corner_radius_all(_corner)
 b.add_theme_stylebox_override("focus",ring)
 var text_color: Color=_paper if active else _ink
 if active and absf(_paper.get_luminance()-_accent.get_luminance())<0.35:
  text_color=Color("152a2b") if _accent.get_luminance()>0.35 else Color("f2eee5")
 b.add_theme_color_override("font_color",text_color)
 b.add_theme_color_override("font_hover_color",text_color)
 b.add_theme_color_override("font_pressed_color",text_color)
 b.add_theme_color_override("font_disabled_color",_muted)
 b.pressed.connect(action)
 add_child(b)
 return b

func _close(rect: Rect2) -> void:
 var b: Button=_button("关闭",rect,func()->void:closed.emit())
 b.name="CloseButton"

func _illustration(id: String, rect: Rect2, animate: bool=false) -> Control:
 var art: Control=Illustration.new()
 art.position=rect.position
 art.size=rect.size
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(art)
 art.configure(id,id in KNOWN,animate)
 return art

func _tile(id: String, rect: Rect2, number: int, stamp: bool = false) -> void:
 var known: bool=id in KNOWN
 var b: Button=_button("",rect,select_entry.bind(id),id==_selected)
 b.name="Entry_"+id
 b.tooltip_text=str(SAMPLE[id]["name"]) if known else "尚未相遇的奇遇"
 var inner: Rect2=Rect2(rect.position+Vector2(10,10),Vector2(rect.size.x-20,rect.size.y-47))
 _illustration(id,inner)
 var label_color: Color=_paper if id==_selected else _ink
 if id==_selected and absf(_paper.get_luminance()-_accent.get_luminance())<0.35:
  label_color=Color("152a2b") if _accent.get_luminance()>0.35 else Color("f2eee5")
 _label(("%02d  " % number)+(str(SAMPLE[id]["name"]) if known else "尚未相遇"),Rect2(rect.position+Vector2(8,rect.size.y-34),Vector2(rect.size.x-16,28)),16,label_color,false,true)
 if stamp:
  for x: int in range(8):
   _box(Rect2(rect.position+Vector2(9+x*(rect.size.x-18)/7.0,-3),Vector2(6,6)),_paper,_paper,3,0)
   _box(Rect2(rect.position+Vector2(9+x*(rect.size.x-18)/7.0,rect.size.y-3),Vector2(6,6)),_paper,_paper,3,0)

func _list_row(id: String, rect: Rect2, number: int, prefix: String="") -> void:
 var known: bool=id in KNOWN
 var text_value: String=prefix+("%02d  " % number)+(str(SAMPLE[id]["name"]) if known else "尚未相遇")
 var b: Button=_button(text_value,rect,select_entry.bind(id),id==_selected)
 b.name="Entry_"+id
 b.alignment=HORIZONTAL_ALIGNMENT_LEFT

func _detail(rect: Rect2, image_height: float = 180.0, title_size: int=30) -> void:
 var d: Dictionary=SAMPLE[_selected]
 var known: bool=_selected in KNOWN
 _label(str(d.name) if known else "未见的奇遇",Rect2(rect.position,Vector2(rect.size.x,42)),title_size,_ink,true)
 _label((str(d.rarity)+"  /  "+str(d.type)) if known else "等待一次不期而遇",Rect2(rect.position+Vector2(0,44),Vector2(rect.size.x,28)),16,_muted)
 var image_width: float=minf(rect.size.x,image_height*2.0)
 var art_rect: Rect2=Rect2(rect.position+Vector2((rect.size.x-image_width)*0.5,82),Vector2(image_width,image_height))
 _box(Rect2(art_rect.position-Vector2(6,6),art_rect.size+Vector2(12,12)),_paper.lerp(_accent,0.11),_border,maxi(0,_corner-3))
 _illustration(_selected,art_rect,true)
 var text_y: float=rect.position.y+82+image_height+18
 var available: float=rect.end.y-text_y-76
 var description: Label=_label(str(d.description) if known else str(d.hint),Rect2(Vector2(rect.position.x,text_y),Vector2(rect.size.x,maxf(60,available-30))),18,_ink)
 description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 description.vertical_alignment=VERTICAL_ALIGNMENT_TOP
 _label(("常停在 · "+str(d.habitat)) if known else "留意线索，下一次打开窗也许就会遇见。",Rect2(Vector2(rect.position.x,rect.end.y-91),Vector2(rect.size.x,28)),14,_muted)
 var half: float=(rect.size.x-12)/2.0
 var favorite: Button=_button("已在珍藏" if _selected in _favorites else "收藏为珍藏",Rect2(Vector2(rect.position.x,rect.end.y-50),Vector2(half,46)),_toggle_favorite,_selected in _favorites)
 favorite.name="FavoriteButton"
 favorite.disabled=not known
 var replay: Button=_button("回到窗边看它" if known else "尚未发现",Rect2(Vector2(rect.position.x+half+12,rect.end.y-50),Vector2(half,46)),_replay,known)
 replay.name="ReplayButton"
 replay.disabled=not known

func _toggle_favorite() -> void:
 if _selected not in KNOWN:return
 if _selected in _favorites:_favorites.erase(_selected)
 else:_favorites.append(_selected)
 _render()

func _replay() -> void:
 if _selected in KNOWN:replay_requested.emit(_selected)

func _field_notes() -> void:
 _box(Rect2(100,48,1240,716),_paper,_border,5)
 _box(Rect2(112,60,600,692),_paper.lightened(0.025),_border,3)
 _line(Rect2(716,70,2,672),_border)
 _label("Field notes",Rect2(144,78,520,45),34,_ink,true)
 _label("图鉴样册   /   已发现 4 / 6",Rect2(146,124,510,30),17,_muted)
 _close(Rect2(1220,72,90,44))
 for i: int in range(IDS.size()):
  _tile(IDS[i],Rect2(145+(i%2)*270,184+(i/2)*170,248,145),i+1)
 _label("每一次停留，都是一页新的观察。",Rect2(145,703,520,26),15,_muted)
 _detail(Rect2(760,138,526,576),190)

func _glass_drawer() -> void:
 var surface: Color=_paper
 surface.a=0.96
 _box(Rect2(776,24,640,762),surface,_border,24)
 _label("A little collection",Rect2(808,42,450,43),29,_ink,true)
 _label("图鉴样册 · 4 / 6 次相遇",Rect2(810,88,400,26),16,_muted)
 _close(Rect2(1300,48,88,44))
 for i: int in range(IDS.size()):
  _tile(IDS[i],Rect2(810+(i%3)*192,132+(i/3)*106,178,96),i+1)
 _line(Rect2(810,353,570,1),_border)
 _detail(Rect2(810,371,568,391),112,27)

func _pixel_console() -> void:
 _box(Rect2(176,58,1088,704),_ink,_ink,0,3)
 _box(Rect2(184,66,1072,688),_paper,_accent,0,3)
 _line(Rect2(204,84,1032,64),_accent)
 _label("POCKET FIELD GUIDE",Rect2(226,92,790,45),29,_paper,true)
 _close(Rect2(1126,94,100,44))
 _label("SAMPLE 04 / 06",Rect2(224,166,300,34),20,_muted,true)
 for i: int in range(IDS.size()):
  _list_row(IDS[i],Rect2(224,218+i*68,286,54),i+1,"> " if IDS[i]==_selected else "  ")
 _line(Rect2(540,168,3,512),_border)
 _detail(Rect2(578,168,630,518),162,30)
 _label("SELECT · 选择来客        RECORD · 珍藏        PLAY · 窗边回放",Rect2(224,710,980,26),16,_muted)

func _post_album() -> void:
 _box(Rect2(134,55,1172,702),_paper,_border,4)
 _label("Postcards from elsewhere",Rect2(174,77,850,52),33,_ink,true)
 _label("来自窗外的信 · 图鉴样册 4 / 6",Rect2(176,130,760,28),17,_muted)
 _close(Rect2(1180,84,92,44))
 _line(Rect2(740,182,1,522),_border)
 _detail(Rect2(178,186,520,518),155,29)
 for i: int in range(IDS.size()):
  _tile(IDS[i],Rect2(780+(i%2)*230,190+(i/2)*163,204,141),i+1,true)
 _label("寄给：每一个愿意慢下来的人",Rect2(780,703,440,25),16,_muted)

func _observatory() -> void:
 _box(Rect2(92,44,1256,724),_paper,_accent,22)
 _box(Rect2(106,58,1228,696),Color.TRANSPARENT,_border,16)
 _label("NOCTURNE / OBSERVATIONS",Rect2(138,76,900,44),28,_ink,true)
 _label("月光观测册     4 / 6 已点亮",Rect2(140,124,700,30),17,_muted)
 _close(Rect2(1218,78,96,44))
 for i: int in range(IDS.size()):
  var y: float=202+i*77
  _box(Rect2(140,y+21,10,10),_accent if IDS[i] in KNOWN else _border,_accent,5,0)
  if i<5:_line(Rect2(144,y+34,1,54),_border)
  _list_row(IDS[i],Rect2(170,y,290,54),i+1)
 _box(Rect2(501,181,790,540),Color.TRANSPARENT,_border,22)
 _detail(Rect2(536,204,720,485),140,31)
 _label("LITTLE ELSEWHERE     /     NIGHT ARCHIVE",Rect2(140,715,800,25),15,_muted,true)

func _cabinet() -> void:
 _box(Rect2(84,42,1272,730),_paper,_border,2,2)
 _line(Rect2(84,42,1272,15),_accent)
 _label("Botanical cabinet",Rect2(122,77,850,50),34,_ink,true)
 _label("自然观察标本柜 · 图鉴样册 · 4 / 6",Rect2(124,133,850,28),17,_muted)
 _close(Rect2(1226,80,94,44))
 for i: int in range(IDS.size()):
  _tile(IDS[i],Rect2(122+(i%3)*204,204+(i/3)*224,186,191),i+1)
 _line(Rect2(760,189,1,530),_border)
 _detail(Rect2(795,197,519,532),178,31)
 _label("NO. 01—06    /    COLLECTED WITH CARE",Rect2(124,695,610,28),16,_muted,true)

func _radio_log() -> void:
 _box(Rect2(142,64,1156,686),_paper,_border,18,2)
 _label("WINDOW FM",Rect2(180,88,500,48),32,_accent,true)
 _label("来客频道 · 接收日志",Rect2(180,143,560,30),18,_ink)
 _close(Rect2(1168,94,92,44))
 for i: int in range(34):
  _line(Rect2(180+i*12,197,3,14+(i%4)*5),_accent if i<23 else _border)
 _label("04 / 06 signals received",Rect2(180,238,410,34),19,_muted,true)
 for i: int in range(IDS.size()):
  _list_row(IDS[i],Rect2(180,292+i*60,390,48),i+1,"FM ")
 _line(Rect2(610,182,1,500),_border)
 _detail(Rect2(648,170,608,532),176,30)
 _label("SAMPLE LOG   /   QUIET HOURS",Rect2(180,690,580,26),16,_muted,true)

func _paper_book() -> void:
 var back: Panel=_box(Rect2(115,72,1206,682),_accent,_accent,10,0)
 back.rotation=-0.012
 _box(Rect2(126,58,1188,682),_paper,_border,8)
 _label("Small wonders, kept here.",Rect2(164,82,930,49),32,_ink,true)
 _label("剪纸收藏册 · 4 / 6 个小小发现",Rect2(166,134,800,30),17,_muted)
 _close(Rect2(1186,86,92,44))
 for i: int in range(IDS.size()):
  var x: float=164+(i%3)*190
  var y: float=210+(i/3)*211
  _tile(IDS[i],Rect2(x,y,172,178),i+1)
  var tape: Panel=_box(Rect2(x+58,y-8,58,16),_paper.lerp(_accent,0.35),Color.TRANSPARENT,1,0)
  tape.rotation=0.04 if i%2==0 else -0.04
 _detail(Rect2(780,182,490,518),162,30)
 _label("把平常的一天，剪成值得记住的形状。",Rect2(166,683,570,28),16,_muted)

func _ink_scroll() -> void:
 _box(Rect2(190,45,1060,720),_paper,_border,0)
 _line(Rect2(206,62,4,686),_ink)
 _line(Rect2(1230,62,4,686),_ink)
 _label("窗\n外\n拾\n记",Rect2(240,119,80,362),38,_ink,true,true)
 _label("图鉴样册\n已见四景\n未见二景",Rect2(230,518,110,114),17,_muted,false,true)
 _line(Rect2(354,111,1,569),_border)
 for i: int in range(IDS.size()):
  _list_row(IDS[i],Rect2(388,158+i*81,238,53),i+1)
 _line(Rect2(657,111,1,569),_border)
 _detail(Rect2(693,124,490,568),190,32)
 _close(Rect2(1100,65,104,44))
 _label("LITTLE ELSEWHERE",Rect2(235,704,920,28),17,_muted,true,true)

func _star_archive() -> void:
 _box(Rect2(100,49,1240,712),_paper,_accent,0,2)
 _box(Rect2(114,63,1212,684),Color.TRANSPARENT,_border,0)
 _line(Rect2(132,162,1176,1),_accent)
 _label("THE CELESTIAL ARCHIVE",Rect2(150,85,1030,49),31,_ink,true)
 _label("星象与来客的私人档案   /   图鉴样册 04—06",Rect2(152,132,1000,25),16,_muted)
 _close(Rect2(1204,92,98,44))
 for i: int in range(IDS.size()):
  _tile(IDS[i],Rect2(150+(i%2)*236,197+(i/2)*164,214,144),i+1)
 _line(Rect2(656,192,1,516),_accent)
 _detail(Rect2(698,190,592,520),160,31)
 _label("FILED UNDER: SMALL, EXTRAORDINARY THINGS",Rect2(152,712,1100,24),15,_muted,true)

## Small, on-demand collection drawer. No scrim: the outdoor image stays untouched.
func _compact_drawer() -> void:
 var surface: Color = _paper
 surface.a = 0.98
 var panel: Panel = _box(Rect2(1064,82,346,626),surface,_border,_corner)
 panel.name = "CompactGuidePanel"
 panel.set_meta("ui_bounds",Rect2(1064,82,346,626))
 var style_id: String = str(_style.get("id",""))
 var title: String = "窗边图鉴"
 if style_id in ["daily_margin","pocket_journal","pressed_leaf","pencil_day"]:
  title = "观察手记"
 elif style_id in ["pixel_breeze","pocket_cloud","starlit_pixel"]:
  title = "来客图鉴"
 _label(title,Rect2(1080,99,220,32),22,_ink)
 _close(Rect2(1330,98,64,34))
 _label("图鉴样册  ·  已见 4 / 6",Rect2(1080,137,314,24),14,_muted)
 _line(Rect2(1080,164,314,1),_border)
 for i: int in range(IDS.size()):
  var id: String = IDS[i]
  var known: bool = id in KNOWN
  var tile: Rect2 = Rect2(1080+(i%3)*108,176+(i/3)*86,98,78)
  var button: Button = _button("",tile,select_entry.bind(id),false)
  button.name = "Entry_"+id
  button.tooltip_text = str(SAMPLE[id]["name"]) if known else "尚未相遇的奇遇"
  if id == _selected:
   var selected_style: StyleBoxFlat = button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
   selected_style.bg_color = _paper.lerp(_accent,0.12)
   selected_style.border_color = _accent
   button.add_theme_stylebox_override("normal",selected_style)
  _illustration(id,Rect2(tile.position+Vector2(12,5),Vector2(74,43)))
  _label(str(SAMPLE[id]["name"]) if known else "未相遇",Rect2(tile.position+Vector2(4,48),Vector2(90,25)),16,_ink,false,true)
 _line(Rect2(1080,352,314,1),_border)
 _compact_detail()
 _label("小小的相遇，慢慢记下。",Rect2(1080,672,314,20),13,_muted)

func _compact_detail() -> void:
 var data: Dictionary = SAMPLE[_selected]
 var known: bool = _selected in KNOWN
 _label(str(data.name) if known else "未见的奇遇",Rect2(1080,366,194,30),22,_ink)
 _label(str(data.rarity)+" · "+str(data.type) if known else "等一次不期而遇",Rect2(1080,401,198,24),14,_muted)
 _illustration(_selected,Rect2(1286,364,108,66),true)
 _compact_paragraph(str(data.description) if known else str(data.hint),Rect2(1080,449,314,96),16,_ink)
 _compact_paragraph("常停在 · "+str(data.habitat) if known else "留意线索，也许下次打开窗就会遇见。",Rect2(1080,550,314,42),14,_muted)
 _line(Rect2(1080,604,314,1),_border)
 var favorite: Button = _button("已珍藏" if _selected in _favorites else "加入珍藏",Rect2(1080,620,151,38),_toggle_favorite,_selected in _favorites)
 favorite.name = "FavoriteButton"
 favorite.disabled = not known
 var replay: Button = _button("回到窗边" if known else "尚未发现",Rect2(1243,620,151,38),_replay,false)
 replay.name = "ReplayButton"
 replay.disabled = not known

func _compact_paragraph(content: String, rect: Rect2, points: int, color: Color) -> Label:
 # Enable wrapping before assigning text so its initial minimum width cannot expand the drawer.
 var label: Label = Label.new()
 label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 label.add_theme_font_override("font",_font)
 label.add_theme_font_size_override("font_size",points)
 label.add_theme_color_override("font_color",color)
 label.position = rect.position
 label.size = rect.size
 label.text = content
 label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
 label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(label)
 return label
