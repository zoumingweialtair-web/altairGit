extends Control
const DetailedVisitor=preload("res://scripts/visitor_art.gd")
const Silhouette=preload("res://shaders/visitor_silhouette.gdshader")
var _portrait: Node2D
var _postcard: Texture2D

## Native pixel vignette used by collection cards and detail pages.
var entry_id: String = "sparrow"
var discovered: bool = true
var animated: bool = false
var _elapsed: float = 0.0
var _redraw_wait: float = 0.0

const BIRD: Array[String] = [
 "...........OOOO....", "..........OHHHHO...", "..........OHHEHOO..",
 ".........OHHHHHOBB.", "....OOOOOHHHHOO....", "...OWWWWWWWCCCO....",
 "..OWWWWWWWCCCCCO...", ".OTWWWWWWWCCCCO....", "OTTWWWWWCCCCOO.....",
 "TTTOOOOOOOOO.......", "......L..L.........", ".....LL..LL........"
]

func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 clip_contents=true
 resized.connect(queue_redraw)
 set_process(animated and discovered)
 _update_detailed_portrait()

func configure(id: String, known: bool, animate: bool=false) -> void:
 entry_id=id
 discovered=known
 animated=animate and known
 _elapsed=0.0
 _redraw_wait=0.0
 set_process(animated)
 _update_detailed_portrait()
 queue_redraw()

func _process(delta: float) -> void:
 _elapsed+=delta
 _redraw_wait+=delta
 # Detail illustrations breathe at twenty-four frames per second. Cards stay still.
 if _redraw_wait>=1.0/24.0:
  _redraw_wait=fmod(_redraw_wait,1.0/24.0)
  _update_detailed_portrait()
  queue_redraw()

func _bob(speed: float=1.6,amount: float=2.0) -> float:
 return roundf(sin(_elapsed*speed)*amount) if animated else 0.0

func _blink() -> bool:
 return animated and fmod(_elapsed,4.8)>4.55

func _col(hex: String) -> Color:
 var c: Color=Color(hex)
 if not discovered:
  var lum: float=c.r*0.21+c.g*0.72+c.b*0.07
  # Reduce the whole vignette to quiet silhouettes, hiding its original colors.
  var shade: float=0.55 if lum<0.56 else 0.70
  return Color(shade,shade+0.035,shade-0.015)
 return c

func _block(x: float,y: float,w: float,h: float,color: String) -> void:
 draw_rect(Rect2(x,y,w,h),_col(color))

func _draw() -> void:
 if size.x<=0.0 or size.y<=0.0:return
 if DetailedVisitor.is_creature(entry_id):
  _draw_portrait_habitat()
  return
 if _postcard!=null:
  if discovered:
   var source: Vector2=_postcard.get_size()
   var ratio: float=maxf(size.x/source.x,size.y/source.y)
   var area: Rect2=Rect2((size-source*ratio)*0.5,source*ratio)
   draw_texture_rect(_postcard,area,false)
  else:
   draw_rect(Rect2(Vector2.ZERO,size),Color("a6b0a0"))
   draw_circle(size*0.5,minf(size.x,size.y)*0.27,Color("899783"))
  return
 if entry_id=="parcel" or entry_id.begins_with("keepsake_"):
  var scale_factor: float=minf(size.x/120.0,size.y/120.0)
  draw_set_transform((size-Vector2(120,120)*scale_factor)*0.5,0.0,Vector2(scale_factor,scale_factor))
  _keepsake(entry_id.trim_prefix("keepsake_"))
  draw_set_transform(Vector2.ZERO)
  return
 draw_set_transform(Vector2.ZERO,0.0,Vector2(size.x/240.0,size.y/120.0))
 if entry_id.begins_with("scene_"):
  _landscape(entry_id.trim_prefix("scene_"))
 elif entry_id in ["ufo","meteor","supernova"]:
  _wonder()
 elif entry_id=="butterfly":
  _butterfly()
 elif entry_id=="squirrel":
  _squirrel()
 elif entry_id=="woodpecker":
  _woodpecker()
 elif entry_id=="owl":
  _owl()
 elif entry_id=="luna_moth":
  _luna_moth()
 elif entry_id=="jewel_beetle":
  _jewel_beetle()
 elif entry_id=="fireflies":
  _fireflies()
 elif entry_id=="aurora":
  _aurora()
 elif entry_id=="star_whale":
  _star_whale()
 elif entry_id=="time_ripple":
  _time_ripple()
 elif entry_id=="tree_spirit":
  _tree_spirit()
 elif entry_id=="kingfisher":
  _kingfisher()
 elif entry_id=="swallow":
  _swallow()
 elif entry_id=="magpie":
  _magpie()
 elif entry_id=="white_eye":
  _white_eye()
 elif entry_id=="egret":
  _egret()
 elif entry_id=="hedgehog":
  _hedgehog()
 elif entry_id=="cat":
  _cat()
 elif entry_id=="bat":
  _bat()
 elif entry_id=="dragonfly":
  _dragonfly()
 elif entry_id=="ladybug":
  _ladybug()
 elif entry_id=="stag_beetle":
  _stag_beetle()
 elif entry_id=="lanterns":
  _lanterns()
 elif entry_id=="ghost_train":
  _ghost_train()
 elif entry_id=="moon_gate":
  _moon_gate()
 elif entry_id=="signal_echo":
  _signal_echo()
 elif entry_id=="aurora_crown":
  _aurora_crown()
 elif entry_id=="ember_clouds":
  _ember_clouds()
 elif entry_id=="meteor_shower":
  _meteor_shower()
 elif entry_id=="deep_one":
  _deep_one()
 elif entry_id=="sunken_city":
  _sunken_city()
 elif entry_id=="sky_jellyfish":
  _sky_jellyfish()
 elif entry_id=="twin_moons":
  _twin_moons()
 elif entry_id=="floating_isles":
  _floating_isles()
 elif entry_id=="bioluminescent_tide":
  _bioluminescent_tide()
 elif entry_id=="constellation_stag":
  _constellation_stag()
 else:
  _bird_scene()
 draw_set_transform(Vector2.ZERO)

func _landscape(mode: String) -> void:
 var palettes: Dictionary={
  "sun":["bfd9d7","97b4ba","f4efdb","91bcb7","aab9ab","6c8974"],
  "rain":["9baeb7","8c9fa9","c6d1d0","809da6","849a9b","688174"],
  "night":["283f59","455970","b1c2ca","416779","526b74","405e54"],
  "dusk":["ddb4a2","9e92a8","dfc9bd","ac999f","9d989c","727f69"],
  "snow":["cbd6dc","a4b9c4","f6f3e7","afc9ce","bccbcb","bacbbc"],
  "fog":["cbd5ce","b7c6c0","dce2d7","b3c7bf","adbfba","8ea697"],
  "storm":["536778","617789","bbc7c9","5c7e8c","677e85","4d6b60"],
  "dawn":["d9d2c6","a9b9bd","f0e6d4","b0c7c3","b6bdaf","8eaa8a"]
 }
 var p: Array=palettes.get(mode,palettes["sun"])
 var sky: String=p[0]
 var dark: bool=mode in ["night","storm"]
 _block(0,0,240,120,sky)
 if mode=="dawn":_block(0,39,240,27,"ead7ba")
 if mode=="dusk":_block(0,35,240,31,"e8c4ad")
 if mode=="night":
  _block(180,12,15,16,"dfe0bc")
  _block(186,9,13,15,sky)
  for i in range(13):_block(10+(i*41)%218,8+(i*19)%43,2,2,"d1dbcd")
 elif mode in ["sun","dusk","dawn"]:
  var sun_y: float=15 if mode=="sun" else (38 if mode=="dawn" else 29)
  _block(180,sun_y,18,16,"f1e4bc")
  _block(177,sun_y+4,24,8,"f1e4bc")
 var cloud: String="e1e7df" if not dark else "40576d"
 if mode in ["fog","rain"]:cloud="b7c7c8"
 var drift: float=_bob(0.3,3.0)
 for origin: Vector2 in [Vector2(16,20),Vector2(101,12)]:
  _block(origin.x+drift,origin.y,43,6,cloud)
  _block(origin.x+7+drift,origin.y-4,27,8,cloud)
 draw_colored_polygon(PackedVector2Array([Vector2(0,68),Vector2(48,39),Vector2(76,53),Vector2(116,26),Vector2(154,57),Vector2(194,43),Vector2(240,67),Vector2(240,81),Vector2(0,81)]),_col(p[1]))
 draw_colored_polygon(PackedVector2Array([Vector2(92,46),Vector2(116,26),Vector2(141,48),Vector2(126,42),Vector2(117,46),Vector2(108,39)]),_col(p[2]))
 # Two hill towers stand at different depths, away from the small riverside town.
 _block(0,65,240,46,p[5])
 draw_colored_polygon(PackedVector2Array([Vector2(0,72),Vector2(22,64),Vector2(47,58),Vector2(70,67),Vector2(96,78)]),_col(p[5]))
 draw_colored_polygon(PackedVector2Array([Vector2(145,80),Vector2(169,71),Vector2(186,64),Vector2(212,71),Vector2(240,65),Vector2(240,95)]),_col(p[5]))
 _hill_tower(45,62,0.6,p[4])
 _hill_tower(185,68,1.0,p[4])
 for i in range(8):
  var x: float=67+i*12
  var height: float=7+(i*7)%12
  var base: float=_shore_y(x)-3
  _block(x,base-height,9,height,p[4])
  for row in range(2):
   for col in range(2):
    if (i+row+col)%3!=0 and row*5+5<height:_block(x+2+col*4,base-height+3+row*5,2,2,"e1d3a3" if dark or mode=="dusk" else "7f9997")
 var water_edge: PackedVector2Array=PackedVector2Array()
 for x in range(0,241,8):water_edge.append(Vector2(x,_shore_y(x)))
 water_edge.append(Vector2(240,111))
 water_edge.append(Vector2(0,111))
 draw_colored_polygon(water_edge,_col(p[3]))
 for i in range(18):
  var wave_x: float=7+(i*43+int(_elapsed*2.0))%221
  _block(wave_x,85+(i*7)%23,5+(i%4)*4,1,"c4d4ca" if not dark else "76969d")
 if dark or mode in ["dusk","dawn"]:
  for i in range(5):_block(179-i*2,83+i*5,7+i*2,1,"c5c39e" if mode!="dawn" else "e6d4af")
 draw_colored_polygon(PackedVector2Array([Vector2(0,97),Vector2(22,98),Vector2(39,103),Vector2(60,109),Vector2(72,111),Vector2(0,111)]),_col(p[5]))
 if mode=="fog":
  _block(0,63+_bob(0.3,2),240,7,"c6d3cc")
  _block(20,73,202,3,"c3d1ca")
  _block(48,90,172,3,"c3d2ca")
 _block(0,67,31,42,"c2b69f" if not dark else "526461")
 _block(0,62,35,6,"928476" if mode!="snow" else "eef0e4")
 for x in [7,20]:
  _block(x,74,6,10,"daca9f" if dark or mode=="dusk" else "647f7e")
  _block(x,92,6,9,"daca9f" if dark else "647f7e")
 _block(214,43,6,67,"7d8268" if not dark else "465e51")
 _block(199,35,34,15,p[5] if mode!="snow" else "e5ece1")
 _block(206,27,23,24,p[5] if mode!="snow" else "e5ece1")
 _block(0,110,240,5,"677e70")
 for x in [16,57,98,139,180,221]:_block(x,115,4,5,"677e70")
 if mode in ["rain","storm"]:
  for i in range(28 if mode=="storm" else 18):
   var x: int=(i*37)%233
   var y: int=(i*23+int(_elapsed*(45 if mode=="storm" else 29)))%107
   _block(x,y,1,7,"bfced2")
   if mode=="storm":_block(x-1,y+6,1,4,"bfced2")
 if mode=="storm" and (not animated or fmod(_elapsed,6.0)<0.28):
  for xy: Vector2 in [Vector2(74,7),Vector2(70,15),Vector2(73,22),Vector2(68,29)]:_block(xy.x,xy.y,4,9,"e4dfc7")
 if mode=="snow":
  for i in range(24):_block((i*43+int(_elapsed*3.0))%237,(i*19+int(_elapsed*9.0))%109,2,2,"f6f5e9")

func _shore_y(x: float) -> float:
 return 76.0+roundf(sin(x*0.021-0.9)*5.0+sin(x*0.049)*2.0)

func _hill_tower(x: float,base: float,scale_factor: float,stone: String) -> void:
 _block(x-3*scale_factor,base-18*scale_factor,7*scale_factor,18*scale_factor,stone)
 _block(x-5*scale_factor,base-20*scale_factor,11*scale_factor,4*scale_factor,stone)
 _block(x-4*scale_factor,base-23*scale_factor,2*scale_factor,4*scale_factor,stone)
 _block(x+3*scale_factor,base-23*scale_factor,2*scale_factor,4*scale_factor,stone)
 _block(x-scale_factor,base-14*scale_factor,3*scale_factor,4*scale_factor,"d5c392")

func _bird_scene() -> void:
 _block(0,0,240,120,"d9dfc8")
 _block(0,0,240,52,"c1d5ca")
 for xy: Vector2 in [Vector2(12,13),Vector2(188,25),Vector2(38,83),Vector2(205,90)]:
  _block(xy.x,xy.y,24,11,"a7ba92")
  _block(xy.x+6,xy.y-7,13,20,"a7ba92")
 _block(27,84,186,6,"8b816a")
 _block(46,80,5,9,"8b816a")
 _block(169,76,5,12,"8b816a")
 var head: String="aa9478"
 var wing: String="83725c"
 var body: String="d8c6a2"
 if entry_id=="tit":head="d5dabc";wing="6b8d93";body="d9c575"
 if entry_id=="robin":head="c88e69";wing="8d7962";body="dc9d70"
 var palette: Dictionary={"O":"384f4d","H":head,"E":"213b3d","B":"b9a369","W":wing,"C":body,"T":wing,"L":"637363"}
 for y in range(BIRD.size()):
  for x in range(BIRD[y].length()):
   var key: String=BIRD[y].substr(x,1)
   if key!=".":
    if key=="E" and _blink():_block(82+x*3,49+y*3,3,1,str(palette[key]))
    else:_block(82+x*3,48+y*3,3,3,str(palette[key]))
 if not discovered:
  _block(112,41,5,8,"e2e5d4")

func _butterfly() -> void:
 _block(0,0,240,120,"dce2ca")
 _block(0,0,240,70,"c9dbd0")
 _block(39,86,38,34,"b6927c")
 _block(35,82,46,8,"c4a087")
 _block(57,49,4,34,"7f9b77")
 _block(44,59,14,6,"8aa880")
 _block(60,67,18,6,"8aa880")
 _block(49,38,18,16,"eee4bb")
 _block(45,42,26,8,"eee4bb")
 _block(54,43,8,7,"ceb079")
 var wing: float=18.0-absf(_bob(5.0,6.0))
 var lift: float=_bob()
 _block(155-wing,34+lift,wing,25,"f3edd1")
 _block(163,34+lift,wing,25,"f3edd1")
 _block(155-wing+4,62+lift,maxf(3,wing-4),14,"e3d8b4")
 _block(163,62+lift,maxf(3,wing-4),14,"e3d8b4")
 _block(157,37+lift,4,38,"697b67")
 _block(152,30+lift,3,9,"697b67")
 _block(163,30+lift,3,9,"697b67")

func _wonder() -> void:
 _block(0,0,240,120,"2e455d")
 _block(0,91,240,29,"445f69")
 draw_colored_polygon(PackedVector2Array([Vector2(0,100),Vector2(58,65),Vector2(91,87),Vector2(130,59),Vector2(181,97),Vector2(220,70),Vector2(240,91),Vector2(240,120),Vector2(0,120)]),_col("728b98"))
 for i in range(15):_block(8+(i*43)%219,10+(i*17)%65,2,2,"c9d4c2")
 if entry_id=="ufo":
  var lift: float=_bob(1.5,3.0)
  _block(107,30+lift,26,13,"99bebb")
  _block(96,43+lift,48,6,"c0d4ca")
  _block(83,49+lift,74,8,"6b939d")
  _block(94,57+lift,52,5,"a9c2b7")
  _block(106,66+lift,27,3,"7e9f9c")
  for i in range(4):_block(96+i*13,52+lift,4,2,"dce4b2" if (i+floori(_elapsed*3))%3==0 else "a6beb0")
  _block(96,110,40,2,"c1d0b7")
 elif entry_id=="meteor":
  for i in range(17):
   _block(165-i*5,51-i*2,4,3,"f2dfaa" if i<8 else "a8b8b2")
  _block(164,50,7,5,"f5e9c2")
 else:
  var pulse: float=absf(_bob(2.0,3.0))
  _block(116,24-pulse,5,54+pulse*2,"879fae")
  _block(91-pulse,49,55+pulse*2,5,"879fae")
  _block(114,35,9,32,"c9d7d3")
  _block(103,46,31,10,"c9d7d3")
  _block(113,45,11,12,"f3e9bd")

func _garden(night: bool=false,branch: bool=true) -> void:
 _block(0,0,240,120,"334c57" if night else "c4d6c6")
 _block(0,83,240,37,"48645e" if night else "a4b794")
 for xy: Vector2 in [Vector2(10,19),Vector2(33,30),Vector2(190,16),Vector2(207,64)]:
  var leaf: String="56756b" if night else "a6bd99"
  _block(xy.x,xy.y,28,11,leaf)
  _block(xy.x+7,xy.y-7,16,23,leaf)
 if branch:
  _block(22,90,196,7,"756f5d")
  _block(38,86,5,9,"756f5d")
  _block(193,82,5,11,"756f5d")

func _sprite(rows: Array[String],colors: Dictionary,origin: Vector2,pixel: float=3.0) -> void:
 for y in range(rows.size()):
  for x in range(rows[y].length()):
   var key: String=rows[y].substr(x,1)
   if key!=".":_block(origin.x+x*pixel,origin.y+y*pixel,pixel,pixel,str(colors[key]))

func _squirrel() -> void:
 _garden()
 # The curled tail, little ears and held acorn give this visitor its own profile.
 var tail: Array[String]=[
  "....TTTTTTT.............", "..TTTHHHHHTT............", ".TTHHHHHHHHTT...........",
  "TTHHHHHHHTTT........C.C.", "THHHHTTTTT.........CCCC.", "THHHTT.............CCEC.",
  "THHHT.............CCCCCB", "THHHTT.........CCCCCC...", "TTHHHTT.......CCCCCC....",
  ".TTHHHTT.....CCCCCCC....", "..TTHHHTTT..CCCCCCCH....", "...TTHHHHTTTCCCHHHHA....",
  "....TTTHHHHCCCCHHHHAA...", "......TTTTTCCCCHHHH.....", ".........CCCCCCCCCC.....",
  ".........CCCCC..CCC.....", "........CCCCC...CCCC...."
 ]
 var colors: Dictionary={"T":"8c715d","H":"c1a17a","C":"b18761","E":"b18761" if _blink() else "304842","B":"725b49","A":"d5b67d"}
 _sprite(tail,colors,Vector2(76,39),3)
 _block(202,76,9,8,"cab183")
 _block(201,74,11,3,"826e55")

func _woodpecker() -> void:
 _garden(false,false)
 _block(151,0,25,120,"867960")
 _block(156,0,6,120,"a59977")
 for y in [7,35,68,102]:_block(167,y,6,15,"6e6a56")
 var peck: float=2.0 if animated and fmod(_elapsed,2.6)>2.25 else 0.0
 var rows: Array[String]=[
  "......RRRRR......", ".....RRRRRRO.....", ".....OCCCCOO.....", ".....OCECCOOOBBB.",
  ".....OCCCCCO.....", "....OOCCCOO......", "...OOOOCCO.......", "..OOOWOOCCO......",
  "..OOWWOWCCO......", "..OOOWOOCCO......", "..OOWWOWCCO......", "..OOOWOOCCO......",
  "...OOOORRRO......", "...OOOOORRO......", "....OOOOOLLL.....", "....OOOOO........",
  "....OOOO.........", "....OOO..........", "....OO..........."
 ]
 _sprite(rows,{"R":"b56f5c","O":"374d49","C":"e5dec4","E":"253b37","B":"aa9670","W":"b9c8bb","L":"7c755c"},Vector2(103+peck,25),3)
 _block(181,31,6,4,"9fa78a")
 _block(186,38,3,3,"9fa78a")

func _owl() -> void:
 _garden(true)
 _block(42,17,12,12,"d3d5b5")
 _block(47,14,11,12,"334c57")
 var rows: Array[String]=[
  "..OOO.........OOO..", "..OCCOO.....OOCCO..", "..OCCCCOOOOOCCCCO..",
  "..OCCCCCCCCCCCCCO..", ".OCHHHHCCCHHHHHCO.", ".OCHHEHCCCHHEHHCO.",
  ".OCHHHHCBCHHHHHCO.", "..OCCCCCBCCCCCCO..", "..OCCCCCCCCCCCCO..",
  "..OWCCCCCCCCCCWO..", "..OWWCHCHCHCCWWO..", "...OWCHCHCHCCWO...",
  "...OWWCHCHCCWWO...", "....OWWCCCWWWO....", ".....OOOOOOOO.....",
  "......L...L.......", ".....LLL.LLL......"
 ]
 var colors: Dictionary={"O":"3a4b46","C":"a99d80","H":"d2c7a6","E":"344844","B":"c5ad74","W":"807e69","L":"b7a57c"}
 if _blink():colors["E"]="a99d80"
 _sprite(rows,colors,Vector2(91,39),3)
 if _blink():
  _block(106,56,7,1,"344844")
  _block(130,56,7,1,"344844")

func _luna_moth() -> void:
 _garden(true,false)
 _block(25,22,15,15,"d8dbb8")
 _block(30,18,14,15,"334c57")
 var flutter: float=absf(_bob(3.8,5.0))
 var lift: float=_bob(1.2,2.0)
 for side in [-1,1]:
  var left: float=120+side*23.0-flutter*side
  _block(left-17,32+lift,34-flutter,8,"7fae91")
  _block(left-22,40+lift,42-flutter,22,"afd0a0")
  _block(left-16,62+lift,31-flutter,17,"92bb92")
  _block(left-9,79+lift,10,17,"88b495")
  _block(left-6,96+lift,6,9,"88b495")
  _block(left-5,48+lift,9,8,"d5d5a2")
  _block(left-2,50+lift,3,4,"657f72")
 _block(118,34+lift,5,43,"d9d8b2")
 _block(115,27+lift,3,9,"a5b68b")
 _block(124,27+lift,3,9,"a5b68b")
 _block(113,26+lift,5,3,"a5b68b")
 _block(124,26+lift,5,3,"a5b68b")

func _jewel_beetle() -> void:
 _garden(false,false)
 # A broad leaf acts as a small display stage for a metallic beetle.
 _block(46,71,151,17,"739a74")
 _block(60,62,123,35,"83a67a")
 _block(79,55,86,49,"83a67a")
 _block(50,80,141,3,"b6c492")
 for i in range(4):
  _block(77+i*22,68,3,13,"a1ba88")
  _block(88+i*22,83,3,13,"a1ba88")
 for side in [-1,1]:
  for i in range(3):
   var leg_x: float=118+side*(17+i*2)
   _block(leg_x,50+i*10,13,3,"3b645c")
   _block(leg_x+(10 if side>0 else 0),47+i*10,3,7,"3b645c")
 _block(113,28,17,8,"406f67")
 _block(107,36,29,43,"397f70")
 _block(111,32,21,53,"397f70")
 _block(111,41,10,35,"78ac87")
 _block(123,41,9,35,"548f79")
 _block(120,38,3,42,"285d59")
 _block(115,43,3,23,"b7c27c")
 _block(127,47,3,20,"90b28a")
 _block(109,23,3,10,"3b645c")
 _block(132,23,3,10,"3b645c")
 if animated and fmod(_elapsed,3.2)>2.4:
  _block(113,49,9,2,"dfe5b2")
  _block(117,45,2,10,"dfe5b2")

func _fireflies() -> void:
 _garden(true,false)
 _block(0,93,240,27,"344e48")
 for i in range(21):
  var x: float=7+i*11
  var tall: float=7+(i*13)%24
  _block(x,120-tall,3,tall,"617e65")
  _block(x-4,122-tall,4,2,"617e65")
 for i in range(12):
  var x: float=24+(i*37)%195
  var y: float=20+(i*29)%68
  if animated:
   x+=roundf(sin(_elapsed*0.7+i)*3.0)
   y+=roundf(cos(_elapsed*0.8+i*2)*3.0)
  var bright: bool=not animated or sin(_elapsed*1.6+i)>-0.15
  if bright:
   _block(x-3,y-1,8,4,"6d8e68")
   _block(x-1,y-3,4,8,"6d8e68")
  _block(x,y,2,2,"e3dfa0" if bright else "99b184")

func _night_sky() -> void:
 _block(0,0,240,120,"2d4558")
 _block(0,94,240,26,"536d77")
 for i in range(21):
  var bright: bool=not animated or (floori(_elapsed*2)+i)%7!=0
  _block(7+(i*43)%226,10+(i*23)%74,2,2,"bdcdbf" if bright else "67838a")

func _mountain_base() -> void:
 draw_colored_polygon(PackedVector2Array([Vector2(0,112),Vector2(36,83),Vector2(65,101),Vector2(104,76),Vector2(145,109),Vector2(188,83),Vector2(240,108),Vector2(240,120),Vector2(0,120)]),_col("5e7981"))
 draw_colored_polygon(PackedVector2Array([Vector2(82,93),Vector2(104,76),Vector2(125,94),Vector2(110,91),Vector2(103,94),Vector2(98,88)]),_col("a3b7b5"))

func _aurora() -> void:
 _night_sky()
 for i in range(34):
  var x: float=17+i*6
  var crest: float=24+roundf(sin(i*0.21+_elapsed*0.26)*10.0)
  var depth: float=19+roundf(cos(i*0.18)*9.0)
  _block(x,crest,6,depth+12,"425f6c")
  _block(x,crest+3,6,depth+4,"507b79")
  _block(x,crest+7,6,depth-2,"6b9d8b")
  _block(x,crest+9,6,4,"a4c8a6")
  if i>19:_block(x,crest-3,6,5,"8b8fa4")
 _mountain_base()

func _star_whale() -> void:
 _night_sky()
 var lift: float=_bob(0.9,3.0)
 var rows: Array[String]=[
  "...........BBBBBBBBBB..................", ".......BBBBHHHHHHHHHHBBBB..............",
  ".....BBBHHHHHHHHHHHHHHHHBBB............", "....BBHHHHHHHHHHHHHHHHHHHHBB...........",
  "...BBHHHHHHHHHHHHHHHHHHHHHHBB..........", "..BBHHHHHHHHHHHHHHHHHHHHHHHHBB....BB...",
  ".BBHHHHHHHHHHHHHHHHHHHHHHHHHHBBBBBHB...", ".BBHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHBB...",
  ".BBHHHEHHHHHHHHHHHHHHHHHHHHHHHHHHBB....", "..BBCCCCCCCCCHHHHHHHHHHHHHHHHHHHHHBB...",
  "...BBCCCCCCCCCCCHHHHHHHHHHHHHHBBBBHBB..", "....BBBBCCCCCCCCCCCCHHHHHHHBBBB...BBBB.",
  "........BBBBBBBBBBBBBBBBBBBB...........", "..............BBHHHBB..................",
  "...............BBHHHBB.................", "................BBBBBB................."
 ]
 _sprite(rows,{"B":"688c9b","H":"87acb6","C":"b8c9c2","E":"f0e7b4"},Vector2(54,32+lift),3)
 for xy: Vector2 in [Vector2(93,47),Vector2(121,42),Vector2(138,53),Vector2(155,46)]:
  _block(xy.x,xy.y+lift,2,2,"d9dec4")
 _block(43,58,7,2,"a8c5be")
 _block(34,50,3,3,"a8c5be")
 _mountain_base()

func _pixel_ring(cx: float,cy: float,rx: float,ry: float,color: String) -> void:
 _block(cx-rx*0.55,cy-ry,rx*1.10,2,color)
 _block(cx-rx*0.55,cy+ry,rx*1.10,2,color)
 _block(cx-rx,cy-ry*0.42,2,ry*0.84,color)
 _block(cx+rx-2,cy-ry*0.42,2,ry*0.84,color)
 for side in [-1,1]:
  _block(cx+side*rx*0.82-2,cy-ry*0.78,rx*0.24,2,color)
  _block(cx+side*rx*0.82-2,cy+ry*0.78,rx*0.24,2,color)

func _time_ripple() -> void:
 _night_sky()
 _block(0,82,240,38,"5a7c80")
 _block(22,93,33,2,"87a4a0")
 _block(181,104,47,2,"87a4a0")
 var pulse: float=_bob(1.1,2.0)
 _pixel_ring(121,60,61+pulse,35+pulse,"6a9091")
 _pixel_ring(121,60,48+pulse,28+pulse,"89aaa2")
 _pixel_ring(121,60,33+pulse,20+pulse,"c0cbb0")
 _pixel_ring(121,60,19,12,"e0dbb0")
 _block(119,47,3,15,"d6d6ad")
 _block(121,59,12,3,"d6d6ad")
 _block(111,96,24,2,"bbc7aa")
 _block(100,102,47,2,"8eaaa2")
 for i in range(5):
  var angle: float=i*1.25+_elapsed*0.2
  _block(121+roundf(cos(angle)*57),60+roundf(sin(angle)*32),3,3,"dedbb0")

func _tree_spirit() -> void:
 _night_sky()
 _block(0,103,240,17,"4c675d")
 # A sleeping, leaf-crowned tree spirit, lit from within.
 _block(111,62,20,48,"918875")
 _block(117,70,8,39,"b1a085")
 _block(101,104,43,7,"918875")
 _block(97,108,17,7,"918875")
 _block(133,106,14,7,"918875")
 _block(92,68,23,7,"918875")
 _block(91,60,7,12,"918875")
 _block(129,65,23,7,"918875")
 _block(148,57,6,13,"918875")
 for xy: Vector2 in [Vector2(86,42),Vector2(107,26),Vector2(129,40),Vector2(96,55)]:
  _block(xy.x,xy.y,30,21,"789a7b")
  _block(xy.x+6,xy.y-6,18,31,"789a7b")
  _block(xy.x+5,xy.y+4,13,6,"a1bb8c")
 if _blink():
  _block(113,80,5,1,"e7dbab")
  _block(125,80,5,1,"e7dbab")
 else:
  _block(113,77,4,5,"e7dbab")
  _block(126,77,4,5,"e7dbab")
 _block(120,88,4,2,"705f55")
 for i in range(6):
  var drift: float=_bob(0.7+i*0.1,2.0)
  var x: float=51+(i*29)%142
  var y: float=37+(i*17)%53+drift
  _block(x,y,3,3,"d4d3a3")
  _block(x-2,y+1,7,1,"9eb38a")

func _riverside() -> void:
 _block(0,0,240,120,"c2d8cf")
 _block(0,67,240,11,"9cb69b")
 _block(0,78,240,42,"95b9b1")
 for i in range(9):_block(9+(i*37)%219,85+(i*13)%31,11+(i%3)*5,2,"c5d5c6")
 for x in [25,31,202,211]:
  _block(x,49+(x%11),2,59-(x%11),"7e9b79")
  _block(x-2,43+(x%11),5,12,"a69c77")

func _kingfisher() -> void:
 _riverside()
 _block(42,88,147,5,"897c61")
 var rows: Array[String]=[
  "........BBBBBB...........", ".......BHHHHHHB..........", "......BHHHHEHHBBBBBBBBBB..",
  "......BHHHHHHHB..........", ".....BBHHHCCCCB..........", "....BHHHHHCCCCB..........",
  "...BHHHHHCCCCCB..........", "..BBHHHHHCCCCCB..........", ".BBHHHHHCCCCCB...........",
  "BBHHHHCCCCCCB............", "BBBBBBBBBBBB.............", "......LL.LL.............."
 ]
 _sprite(rows,{"B":"3e6d73","H":"6daba9","C":"caa47a","E":"32514e" if not _blink() else "6daba9","L":"a58b64"},Vector2(76,51),3)
 _block(113,57,5,2,"bad1c2")

func _swallow() -> void:
 _block(0,0,240,120,"cadcd4")
 _block(19,21,51,6,"e8e9dc")
 _block(31,16,30,7,"e8e9dc")
 _block(177,82,44,6,"dde5d8")
 var flap: float=_bob(4.0,3.0)
 var rows: Array[String]=[
  "BB............................BB", "BBB..........................BBB", ".BBBB......................BBBB.",
  "..BBBBB..................BBBBB..", "....BBBBBB............BBBBBB....", "......BBBBBB...BB...BBBBBB......",
  "........BBBBBBBBBBBBBBBB........", "..........BBBCBBBBCBBB..........", "............BCCCRCCB............",
  ".............BCCCRB.............", "..............BBBB..............", "..............BBBB..............",
  ".............BB..BB.............", "............BB....BB............", "...........BB......BB..........."
 ]
 _sprite(rows,{"B":"425f64","C":"d9dece","R":"b18470"},Vector2(72,31+flap),3)
 _block(112,52+flap,3,2,"bfd0c3")

func _magpie() -> void:
 _garden()
 var rows: Array[String]=[
  ".............BBBBB.......", "............BBBBBBB......", "............BBEBBBBBBBB..",
  "............BBBBBBB......", "...........BBBBBBB.......", ".........BBBBCCCCB.......",
  ".......BBBBWWCCCCCB......", ".....BBBBBWWWWCCCCB......", "....BBBBBWWWWWCCCCB......",
  "...BBBBBBBBBBCCCCB.......", "..BBBHBBBBBBCCCCB........", ".BBHHHBBBBBBBBBB.........",
  "BBHHHBBBB..L..L..........", "BHHHBBBB..LL..LL.........", "HHHBBBB..................",
  "HHBBBB...................", "HBBBB....................", "BBBB....................."
 ]
 _sprite(rows,{"B":"354f52","H":"5a8287","W":"e3e5d7","C":"cfd9c9","E":"c8d4c8" if not _blink() else "354f52","L":"65735d"},Vector2(78,48),3)

func _white_eye() -> void:
 _garden()
 var colors: Dictionary={"O":"576e4c","H":"98aa6b","E":"eae7c9","B":"9d9966","W":"879763","C":"d3d8a2","T":"879763","L":"708365"}
 _sprite(BIRD,colors,Vector2(82,54),3)
 if not _blink():_block(125,61,2,2,"40584b")
 _block(180,70,3,18,"7e9671")
 _block(170,65,24,6,"bcc69b")
 _block(176,60,12,16,"bcc69b")

func _egret() -> void:
 _riverside()
 var rows: Array[String]=[
  "..............CCCC.......", ".............CCCECCCCCCC.", ".............CCCC........",
  "............CCC..........", "...........CCC...........", "...........CCC...........",
  "............CCC..........", ".............CCC.........", "......CCCCCCCCCC.........",
  "....CCCCWWWWWWCC.........", "...CCCCWWWWWWCCC.........", "..CCCCWWWWWWCCC..........",
  ".CCCCCCCCCCCCC...........", "...CCCCCCCCCC............", ".......L..L..............",
  ".......L..L..............", ".......L..L..............", ".......L..L..............",
  "......LL..LL............."
 ]
 _sprite(rows,{"C":"efedda","W":"c4d3c7","E":"4c6a60","L":"777c60"},Vector2(80,32),3)
 _block(98,96,35,1,"cbdacf")
 _block(108,101,22,1,"cbdacf")

func _hedgehog() -> void:
 _garden(false,false)
 _block(0,94,240,26,"9aac88")
 _block(74,90,94,8,"7f9574")
 var rows: Array[String]=[
  ".....S.S..S.S.S..........", "...SSSSSSSSSSSSS.........", "..SSSHSHSHSHSHSSS........",
  ".SSSHSHSHSHSHSHSSSS......", "SSSHSHSHSHSHSHSHSHSS.....", "SSSHSHSHSHSHSHSHSHSSCC...",
  "SSSHSHSHSHSHSHSHSSCCCECB.", ".SSSHSHSHSHSHSHSSCCCCCC..", "..SSSSSSSSSSSSSSCCCCC....",
  "....LL.........LL........"
 ]
 _sprite(rows,{"S":"88795f","H":"b0a382","C":"d8c5a1","E":"d8c5a1" if _blink() else "495c47","B":"5d634d","L":"6c7055"},Vector2(79,60),3)
 _block(47,91,11,5,"b89b70")
 _block(49,86,4,8,"c9af7c")
 _block(182,91,15,4,"b2bd86")

func _cat() -> void:
 _block(0,0,240,120,"cad7c7")
 _block(0,74,240,46,"b9c6ae")
 _block(26,92,190,8,"998b72")
 _block(26,100,190,20,"c5b898")
 var rows: Array[String]=[
  "....OO.......OO.........", "....OCO.....OCO.........", "....OCCOOOOOCCO.........",
  "....OCCCCCCCCCO.........", "....OCWCCCCWCCO.........", "....OCECCCCECCO.........",
  ".....OCCCBBCCO..........", "......OCCCCCO...........", "......OCCCCCCO..........",
  ".....OCCCCCCCCO.........", ".....OCCWCCCCCCO........", ".....OCCCWCCCCCCO.......",
  ".....OCCCWCCCCCCO...OO..", ".....OCCCCCCCCCCO..OCO..", ".....OCCCCCCCCCCO..OCO..",
  ".....OCCCCCCCCCCO.OCCO..", "....OOCCCOCCCOCCCOCCO...", "....OOOOOOOOOOOOOOOO...."
 ]
 _sprite(rows,{"O":"7d7b63","C":"d5c49d","W":"b59c72","E":"d5c49d" if _blink() else "60775a","B":"b28b78"},Vector2(84,39),3)
 if _blink():
  _block(105,55,6,1,"60775a")
  _block(123,55,6,1,"60775a")
 _block(48,80,18,11,"9cae8b")
 _block(52,75,11,15,"9cae8b")

func _bat() -> void:
 _night_sky()
 _block(184,17,17,18,"d1d7ba")
 _block(190,13,15,17,"2d4558")
 var lift: float=_bob(3.0,3.0)
 var rows: Array[String]=[
  "....B.....................B....", "...BBB...................BBB...", "..BBBBB......B.B........BBBBB..",
  ".BBHHHBB.....BBB.......BBHHHBB.", "BBHHHHHBB...BBBBB.....BBHHHHHBB", "BBHHHHHHBBBBBBBBBBBBBBHHHHHHBB",
  ".BBHHHHHHHBBEBEBBBHHHHHHHHHBB.", "..BBHHHHHHBBBBBBBBHHHHHHHHBB..", "...BBBHHHHHBBBBBBHHHHHHBBB....",
  ".....BBHHHHBBBBBBHHHHBB......", ".......BBHHBBBBBBHHBB........", ".........BBBBBBBBBB..........",
  "...........BBBBBB............", "............B..B............."
 ]
 _sprite(rows,{"B":"53636f","H":"8b8990","E":"ddd7b7"},Vector2(75,35+lift),3)
 _mountain_base()

func _dragonfly() -> void:
 _riverside()
 var flap: float=absf(_bob(6.0,3.0))
 var lift: float=_bob(1.1,2.0)
 for side in [-1,1]:
  var x: float=120+side*25
  _block(x-22,35+lift+flap,44,7,"dce6d6")
  _block(x-17,31+lift+flap,34,5,"c4d9c9")
  _block(x-21,49+lift-flap,42,7,"dce6d6")
  _block(x-15,55+lift-flap,30,4,"c4d9c9")
 _block(117,29+lift,8,10,"678d7f")
 _block(119,39+lift,5,37,"ae7c66")
 _block(120,76+lift,3,11,"8b7160")
 for y in [44,53,62,71]:_block(119,y+lift,5,2,"d2b889")
 _block(115,29+lift,4,4,"45685f")
 _block(124,29+lift,4,4,"45685f")

func _ladybug() -> void:
 _garden(false,false)
 _block(49,70,146,17,"7c9b73")
 _block(66,60,116,36,"95ae7d")
 _block(85,55,76,48,"95ae7d")
 _block(58,78,131,3,"bac695")
 _block(104,34,32,7,"546a54")
 _block(110,29,20,9,"546a54")
 _block(98,43,44,33,"bc8069")
 _block(104,36,32,47,"bc8069")
 _block(118,37,4,45,"586a52")
 for xy: Vector2 in [Vector2(105,45),Vector2(129,45),Vector2(102,60),Vector2(130,60),Vector2(109,72),Vector2(126,72)]:_block(xy.x,xy.y,5,5,"5c6b53")
 for y in [44,57,70]:
  _block(93,y,6,3,"5c6b53")
  _block(141,y,6,3,"5c6b53")
 _block(106,26,3,7,"5c6b53")
 _block(131,26,3,7,"5c6b53")

func _stag_beetle() -> void:
 _garden(false,false)
 _block(40,79,164,28,"92876a")
 _block(41,85,161,3,"b0a17d")
 _block(51,99,138,3,"736e55")
 for side in [-1,1]:
  var x: float=120+side*16
  _block(x-3,27,7,22,"665e4d")
  _block(x+side*5-3,21,7,13,"665e4d")
  _block(x-side*4-3,24,7,5,"665e4d")
  for y in [58,71,84]:
   _block(x+side*5-4,y,12,3,"625f4e")
   _block(x+side*11,y-3,3,7,"625f4e")
 _block(110,43,23,16,"74674e")
 _block(105,60,33,29,"897454")
 _block(110,88,23,7,"897454")
 _block(120,59,3,34,"615e4b")
 _block(109,63,7,20,"ab9164")
 _block(128,63,5,20,"9e865e")
 _block(112,48,3,3,"c4b181")
 _block(128,48,3,3,"c4b181")

func _lanterns() -> void:
 _night_sky()
 # Low town lights sit beyond the bank; the lanterns rest on the river itself.
 for i in range(14):
  var town_x: float=4+i*17
  var height: float=8+(i*7)%12
  _block(town_x,50-height,12,height,"526c73")
  if i%3!=0:_block(town_x+4,53-height,3,4,"c0bc94")
 _block(0,50,240,5,"6d877c")
 _block(0,55,240,65,"527c84")
 _block(0,55,240,4,"7b9994")
 for i in range(15):
  _block(8+(i*43)%220,62+(i*17)%53,8+(i%3)*7,1,"789a9a")
 for i in range(7):
  var x: float=21+(i*31)%199+_bob(0.4+i*0.05,1)
  var y: float=66+(i*13)%35+_bob(0.6+i*0.12,1)
  var w: float=8 if i%2==0 else 12
  _block(x-4,y+7,w+8,2,"8da6a0")
  _block(x-2,y+4,w+4,4,"b99c75")
  _block(x,y-3,w,8,"d7bd8e")
  _block(x+2,y-1,w-4,5,"eee0b0")
  _block(x+w*0.5-1,y-5,2,5,"eee0b0")
  _block(x+2,y+8,w-4,2,"d0c092")
  _block(x,y+12,w,1,"b2b396")
  _block(x+3,y+16,maxf(2,w-6),1,"8fa9a0")

func _ghost_train() -> void:
 _night_sky()
 _mountain_base()
 var drift: float=_bob(0.7,3)
 _block(15,76,206,2,"7c9fa1")
 _block(23,81,188,1,"537a85")
 for i in range(4):
  var x: float=39+i*39+drift
  _block(x,50,35,23,"8daeb0")
  _block(x+3,46,29,4,"b4c9bf")
  _block(x+4,55,8,10,"d2d9ba")
  _block(x+17,55,8,10,"c4d5c1")
  _block(x+30,55,4,10,"678e97")
  _block(x+3,71,29,3,"c3d2be")
  _block(x+6,74,6,4,"76959a")
  _block(x+25,74,6,4,"76959a")
 _block(194+drift,54,6,17,"c8d7bf")
 _block(200+drift,62,6,6,"e2ddb2")
 for i in range(9):_block(29+i*19,86+(i*7)%16,6,1,"759a9b")

func _moon_gate() -> void:
 _night_sky()
 _block(0,92,240,28,"64838a")
 _block(102,33,38,5,"d6d8bb")
 _block(92,38,14,7,"d6d8bb")
 _block(136,38,14,7,"d6d8bb")
 _block(85,45,12,13,"b6c8b8")
 _block(145,45,12,13,"b6c8b8")
 _block(81,57,10,24,"b6c8b8")
 _block(151,57,10,24,"b6c8b8")
 _block(85,80,12,12,"9db8b1")
 _block(145,80,12,12,"9db8b1")
 _block(94,90,56,5,"9db8b1")
 _block(92,94,59,3,"8faeaa")
 _block(117,53,12,13,"e4dfb8")
 _block(122,49,11,12,"2d4558")
 for i in range(4):_block(99-i*3,101+i*4,45+i*5,1,"a9c1b5")
 for i in range(5):_block(108+(i*7)%29,49+(i*11)%31+_bob(0.7+i*0.1,1),2,2,"cdd5b8")

func _signal_echo() -> void:
 _night_sky()
 _block(18,87,65,33,"566e72")
 _block(13,83,76,6,"7d9190")
 for x in [28,47,66]:_block(x,96,8,12,"c9c49a")
 _block(50,67,4,17,"abbeb1")
 _block(44,60,13,8,"8eaaa6")
 _block(36,47,7,13,"b4c9ba")
 _block(41,55,12,8,"b4c9ba")
 _block(51,57,11,5,"b4c9ba")
 _block(57,48,5,12,"b4c9ba")
 _block(48,42,3,15,"d2d9b9")
 for i in range(3):
  var x: float=81+i*37
  var y: float=40-i*7
  var pulse: float=_bob(1.4,2)
  _pixel_ring(x,y,10+i*3+pulse,14+i*4+pulse,"9bbab1" if i<2 else "d1d7b8")
 _block(209,13,5,5,"dddcb8")
 _block(206,15,11,1,"dddcb8")

func _pixel_line(start: Vector2,finish: Vector2,color: String,width: float=1.0) -> void:
 var delta: Vector2=finish-start
 var steps: int=maxi(1,ceili(maxf(absf(delta.x),absf(delta.y))))
 for i in range(steps+1):
  var point: Vector2=start+delta*(float(i)/steps)
  _block(roundf(point.x),roundf(point.y),width,width,color)

func _aurora_crown() -> void:
 _night_sky()
 # A fan converges above the ridge, separate from the original horizontal aurora.
 var origin: Vector2=Vector2(121,88)
 var colors: Array[String]=["587d80","6c9790","82ac98","b0c7a2","8cae9d","6d9295","597d88"]
 for i in range(7):
  var x: float=15+i*31
  var height: float=14+absf(i-3)*5+_bob(0.6+i*0.06,2)
  draw_colored_polygon(PackedVector2Array([origin,Vector2(x,height+8),Vector2(x+17,height),Vector2(x+27,height+6)]),_col(colors[i]))
  _pixel_line(Vector2(120,80),Vector2(x+17,height+2),"a6c0a3" if i%2==0 else "759f96",1)
 for i in range(6):_block(45+i*28,18+(i*11)%20,2,2,"d6d9b7")
 _mountain_base()

func _ember_clouds() -> void:
 _block(0,0,240,120,"8c7b89")
 _block(0,37,240,39,"c29c92")
 _block(0,69,240,51,"d3b699")
 for layer in range(3):
  var drift: float=_bob(0.35+layer*0.06,2)
  var color: String=["a68b92","cd9f91","e2b697"][layer]
  for i in range(6):
   var x: float=-14+i*46+drift
   var y: float=15+layer*16+(i*7)%11
   _block(x,y,42,8,color)
   _block(x+8,y-5,25,7,color)
   _block(x+2,y+7,33,3,"c3a08f" if layer==2 else color)
 _block(0,84,240,36,"a99989")
 draw_colored_polygon(PackedVector2Array([Vector2(0,78),Vector2(29,66),Vector2(63,77),Vector2(91,84),Vector2(0,88)]),_col("827f7a"))
 draw_colored_polygon(PackedVector2Array([Vector2(171,85),Vector2(208,69),Vector2(240,73),Vector2(240,90)]),_col("827f7a"))
 for i in range(8):
  _block(92-i*3,87+i*4,45+i*7,1,"d9c29c")
  _block(11+(i*39)%213,89+(i*7)%28,12,1,"c3b596")
 for i in range(9):_block(37+(i*31)%177,46+(i*13)%34+_bob(0.6+i*0.1,1),1,2,"ead5ad")

func _meteor_shower() -> void:
 _night_sky()
 for i in range(8):
  var drift: float=fmod(_elapsed*(5.0+i*0.25),12.0) if animated else 0.0
  var head: Vector2=Vector2(39+i*25+drift,24+(i*17)%46+drift*0.5)
  var tail: Vector2=head-Vector2(20+(i%3)*9,12+(i%3)*5)
  _pixel_line(tail,head,"6e9098",1)
  _pixel_line(head-Vector2(12,7),head,"bdcdbd",1)
  _block(head.x,head.y,3,2,"e8dfb4")
 _mountain_base()
 _block(0,111,240,9,"3e606c")
 for i in range(4):_block(28+i*50,114,12,1,"8ea5a4")

func _deep_one() -> void:
 _block(0,0,240,120,"3c535e")
 _block(0,40,240,35,"526b72")
 for i in range(3):_block(8+i*82,25+i*5,49,4,"657c7d")
 draw_colored_polygon(PackedVector2Array([Vector2(0,72),Vector2(38,56),Vector2(77,71),Vector2(192,72),Vector2(217,58),Vector2(240,69),Vector2(240,91),Vector2(0,91)]),_col("455e63"))
 _block(0,78,240,42,"4d767a")
 var lift: float=_bob(0.5,1)
 # The distant, submerged form has a heavy crown and long irregular tentacles.
 _block(104,29+lift,32,11,"2d4e52")
 _block(98,39+lift,45,25,"2d4e52")
 _block(94,49+lift,54,17,"2d4e52")
 _block(85,62+lift,72,16,"2d4e52")
 _block(109,32+lift,7,5,"466869")
 _block(107,48+lift,6,2,"8b9d84")
 _block(129,48+lift,6,2,"8b9d84")
 for i in range(7):
  var start: Vector2=Vector2(95+i*8,65+lift)
  var side: float=-1.0 if i<3 else 1.0
  var stretch: float=25+absf(i-3)*8
  var bend: Vector2=start+Vector2(side*stretch,16+(i%2)*6)
  var end: Vector2=bend+Vector2(side*9,-12-(i%3)*3+_bob(0.6+i*0.08,2))
  _pixel_line(start,bend,"2f5155",5)
  _pixel_line(bend,end,"2f5155",3)
  _pixel_line(end,end+Vector2(-side*7,-3),"2f5155",2)
 _block(0,91,240,29,"527b7e")
 for i in range(15):
  _block(8+(i*37)%218,83+(i*11)%32,10+(i%4)*4,1,"729795")
 _block(27,101,14,3,"b5b394")
 _block(33,96,2,5,"d5c79c")

func _sunken_city() -> void:
 _block(0,0,240,120,"7d989b")
 _block(0,37,240,83,"94aaa6")
 _block(0,85,240,35,"628b8e")
 var rise: float=_bob(0.5,1)
 # Wide terraces and broken columns emerge through a low veil of river mist.
 for tier in range(5):
  var width: float=116-tier*18
  _block(121-width*0.5,76-tier*8+rise,width,9,"6e8c87")
  _block(121-width*0.5,76-tier*8+rise,width,2,"b6bda4")
 _block(109,34+rise,25,10,"77958d")
 _block(115,27+rise,13,8,"a5b6a0")
 _block(117,57+rise,8,27,"3f696d")
 for x in [45,58,177,193]:
  var top: float=47+(int(x)*7)%17+rise
  _block(x,top,7,38,"78958d")
  _block(x-2,top-4,11,5,"b3bea5")
  _block(x+2,top+4,2,20,"a2b19a")
 _block(22,81,71,4,"a7bcb2")
 _block(142,76,82,4,"a7bcb2")
 _block(0,88,240,5,"739797")
 for i in range(8):_block(81-i*3,96+i*3,82+i*6,1,"9fb7aa")
 for i in range(4):_block(68+i*35,24+(i*11)%19+_bob(0.7+i*0.1,2),4,3,"b8c6ae")

func _jellyfish_shape(cx: float,cy: float,scale_factor: float,phase: float) -> void:
 var lift: float=_bob(0.8+phase*0.05,2)
 var y: float=cy+lift
 _block(cx-11*scale_factor,y,22*scale_factor,5*scale_factor,"a7b8b7")
 _block(cx-20*scale_factor,y+5*scale_factor,40*scale_factor,8*scale_factor,"a7b8b7")
 _block(cx-27*scale_factor,y+13*scale_factor,54*scale_factor,13*scale_factor,"8fa8b0")
 _block(cx-30*scale_factor,y+23*scale_factor,60*scale_factor,7*scale_factor,"bed0c2")
 _block(cx-17*scale_factor,y+10*scale_factor,12*scale_factor,10*scale_factor,"c3cfbd")
 for tentacle in range(5):
  var previous: Vector2=Vector2(cx+(tentacle-2)*10*scale_factor,y+29*scale_factor)
  for segment in range(7):
   var x: float=cx+(tentacle-2)*10*scale_factor+roundf(sin(segment*0.8+tentacle+_elapsed*0.7+phase)*3)*scale_factor
   var point: Vector2=Vector2(x,y+(34+segment*5)*scale_factor)
   _pixel_line(previous,point,"9fbcb9" if tentacle%2==0 else "7b9eac",maxf(1,scale_factor))
   previous=point
  _block(previous.x,previous.y,2*scale_factor,2*scale_factor,"d1d7be")

func _sky_jellyfish() -> void:
 _night_sky()
 _jellyfish_shape(119,20,1.0,0.0)
 _jellyfish_shape(46,38,0.46,1.0)
 _jellyfish_shape(192,15,0.56,2.0)
 _block(0,112,240,8,"4f6f75")
 for i in range(5):_block(13+i*48,104+(i%2)*4,21,2,"567980")

func _twin_moons() -> void:
 _night_sky()
 _block(48,16,28,30,"d8d8b7")
 _block(43,22,38,18,"d8d8b7")
 _block(55,11,14,40,"d8d8b7")
 _block(51,22,7,7,"bdc6ae")
 _block(66,35,8,6,"bdc6ae")
 _block(156,32,18,21,"a5c1c0")
 _block(152,37,26,11,"a5c1c0")
 _block(161,29,8,27,"a5c1c0")
 _block(166,35,8,11,"829fa7")
 draw_colored_polygon(PackedVector2Array([Vector2(0,88),Vector2(35,70),Vector2(82,83),Vector2(120,65),Vector2(168,86),Vector2(218,73),Vector2(240,86),Vector2(240,120),Vector2(0,120)]),_col("4d6d77"))
 _block(0,91,240,29,"466d7c")
 for i in range(6):
  var ripple: float=_bob(0.7+i*0.1,1)
  _block(54-i*2+ripple,95+i*4,18+i*4,1,"b3c1ac")
  _block(158-i+ripple,94+i*4,11+i*2,1,"89abae")

func _floating_island(cx: float,cy: float,width: float,depth: float,phase: float) -> void:
 var y: float=cy+_bob(0.5+phase*0.08,2)
 draw_colored_polygon(PackedVector2Array([Vector2(cx-width*0.5,y),Vector2(cx+width*0.5,y),Vector2(cx+width*0.24,y+depth*0.55),Vector2(cx-width*0.06,y+depth),Vector2(cx-width*0.30,y+depth*0.47)]),_col("7d8f88"))
 draw_colored_polygon(PackedVector2Array([Vector2(cx,y+3),Vector2(cx+width*0.5,y),Vector2(cx+width*0.24,y+depth*0.55),Vector2(cx-width*0.06,y+depth)]),_col("637c79"))
 _block(cx-width*0.5,y-4,width,5,"9eaf86")
 _block(cx-width*0.37,y-7,width*0.64,4,"b4c49a")
 var tree_x: float=cx+width*0.12
 _block(tree_x,y-22,3,18,"7a8266")
 _block(tree_x-8,y-26,20,10,"7e9c7b")
 _block(tree_x-4,y-31,12,12,"8eaa83")
 if width>60:
  _block(cx-width*0.22,y+2,3,depth*0.8,"abc7ba")
  _block(cx-width*0.22,y+depth*0.8+5,2,6,"abc7ba")

func _floating_isles() -> void:
 _block(0,0,240,120,"afc6c5")
 _block(0,74,240,46,"c9d4c8")
 for xy: Vector2 in [Vector2(11,61),Vector2(159,65),Vector2(79,17)]:
  _block(xy.x,xy.y,52,5,"e0e2d2")
  _block(xy.x+9,xy.y-4,29,5,"e0e2d2")
 _floating_island(51,48,47,29,0)
 _floating_island(131,60,77,44,1)
 _floating_island(202,38,42,25,2)
 _block(9,109,83,3,"e0e2d2")
 _block(163,102,71,3,"e0e2d2")

func _bioluminescent_tide() -> void:
 _block(0,0,240,120,"2e485b")
 for i in range(10):_block(11+(i*37)%220,8+(i*13)%25,1,1,"a8bfba")
 draw_colored_polygon(PackedVector2Array([Vector2(0,39),Vector2(29,31),Vector2(54,36),Vector2(87,44),Vector2(143,43),Vector2(177,35),Vector2(204,32),Vector2(240,40),Vector2(240,120),Vector2(0,120)]),_col("3e666f"))
 for band in range(5):
  for x in range(0,240,4):
   var y: float=53+band*13+roundf(sin(x*0.033+band*0.8+_elapsed*0.35)*(3+band*0.4))
   _block(x,y-2,4,5,"447a82")
   _block(x,y,4,2,"83b5b2" if band%2==0 else "6da8ac")
   if (x/4+band)%5==0:_block(x,y,2,1,"b3d0bf")
 for i in range(29):
  var x: float=7+(i*37)%228
  var y: float=52+(i*19)%63
  var color: String="a4ccc0" if not animated or sin(_elapsed+i)>0.0 else "6b9eaa"
  _block(x,y,1+(i%2),1,color)

func _constellation_stag() -> void:
 _night_sky()
 var nodes: Array[Vector2]=[
  Vector2(78,63),Vector2(108,52),Vector2(145,53),Vector2(153,70),Vector2(113,73),Vector2(84,77),
  Vector2(157,34),Vector2(167,27),Vector2(184,34),Vector2(183,42),Vector2(169,44),
  Vector2(79,101),Vector2(68,104),Vector2(108,91),Vector2(104,104),
  Vector2(143,102),Vector2(151,104),Vector2(166,84),Vector2(168,101),Vector2(177,102),
  Vector2(164,15),Vector2(155,8),Vector2(160,21),Vector2(149,16),
  Vector2(175,17),Vector2(183,9),Vector2(178,22),Vector2(191,18),Vector2(68,58)
 ]
 draw_colored_polygon(PackedVector2Array([nodes[0],nodes[1],nodes[2],nodes[6],nodes[7],nodes[8],nodes[9],nodes[10],nodes[3],nodes[4],nodes[5]]),_col("426876"))
 var edges: Array[Vector2i]=[
  Vector2i(0,1),Vector2i(1,2),Vector2i(2,3),Vector2i(3,4),Vector2i(4,5),Vector2i(5,0),Vector2i(0,28),
  Vector2i(2,6),Vector2i(6,7),Vector2i(7,8),Vector2i(8,9),Vector2i(9,10),Vector2i(10,3),Vector2i(6,10),
  Vector2i(5,11),Vector2i(11,12),Vector2i(4,13),Vector2i(13,14),Vector2i(3,15),Vector2i(15,16),Vector2i(3,17),Vector2i(17,18),Vector2i(18,19),
  Vector2i(7,20),Vector2i(20,21),Vector2i(7,22),Vector2i(22,23),Vector2i(7,24),Vector2i(24,25),Vector2i(7,26),Vector2i(26,27)
 ]
 for edge: Vector2i in edges:_pixel_line(nodes[edge.x],nodes[edge.y],"85acb1",1)
 for i in range(nodes.size()):
  var bright: bool=not animated or sin(_elapsed*1.1+i*0.8)>-0.5
  var point: Vector2=nodes[i]
  _block(point.x-1,point.y-1,3,3,"d9ddbe" if bright else "a0bdba")
  if i in [1,7,11,18] and bright:
   _block(point.x-3,point.y,7,1,"c3d3bd")
   _block(point.x,point.y-3,1,7,"c3d3bd")
 _block(178,35,2,2,"eee1b5")
 _block(0,114,240,6,"42646d")

func _keepsake(id: String) -> void:
 if id=="parcel":
  _block(23,42,74,53,"b8a383")
  _block(19,36,82,13,"d2bd98")
  _block(53,36,12,59,"85987a")
  _block(30,20,23,16,"9da987")
  _block(65,20,23,16,"9da987")
  _block(40,26,13,5,"d9d8ba")
  _block(65,26,13,5,"d9d8ba")
  _block(50,31,18,8,"85987a")
  _block(29,55,15,3,"c8b18d")
  return
 if id=="feather":
  for i in range(9):
   var x: float=27+i*6
   var y: float=76-i*6
   _block(x,y,19,8,"9cac83")
   _block(x+4,y-5,15,5,"bbc6a0")
  for i in range(11):_block(23+i*6,88-i*6,6,3,"7f896b")
 elif id=="yarn":
  _block(30,36,58,49,"bcae8e")
  _block(39,28,39,65,"bcae8e")
  for i in range(5):_block(34,39+i*10,48,3,"e0cfaa")
  _block(43,31,4,57,"d6c49f")
  _block(68,31,4,57,"d6c49f")
  _block(85,76,19,4,"bcae8e")
  _block(100,78,4,13,"bcae8e")
 elif id=="shell":
  _block(37,44,46,40,"c2a878")
  _block(44,82,32,10,"c2a878")
  _block(30,34,60,15,"877e5f")
  _block(36,29,48,7,"9f906a")
  _block(57,18,7,14,"877e5f")
  _block(44,52,6,25,"dfc390")
 elif id in ["stone","stone_blue","stone_green"]:
  var stone: String="92aaa9" if id=="stone" else ("738b9c" if id=="stone_blue" else "88a18c")
  _block(31,45,61,32,stone)
  _block(41,36,43,49,stone)
  _block(44,45,29,8,"bfcec0")
  _block(74,63,10,8,"6f8f89")
 elif id=="twig":
  for i in range(11):_block(28+i*5,88-i*5,6,8,"9c8869")
  for i in range(5):
   _block(53-i*5,58-i*5,6,5,"b5a07a")
   _block(66+i*6,62-i*2,7,5,"b5a07a")
  _block(34,27,6,8,"c8ba93")
 elif id=="token":
  _block(31,37,61,48,"a8b6a9")
  _block(39,29,45,64,"a8b6a9")
  _block(37,41,49,40,"d5d8be")
  _block(43,35,37,53,"d5d8be")
  _block(49,46,24,5,"aab9a8")
  _block(58,42,5,33,"aab9a8")
 elif id=="petal":
  _block(36,34,47,47,"d4b8a5")
  _block(28,43,62,29,"d4b8a5")
  _block(42,27,34,62,"d4b8a5")
  _block(53,44,11,39,"e6ceba")
  _block(58,80,5,15,"b4b88c")
 elif id=="seed":
  _block(39,35,43,49,"b5a377")
  _block(45,28,30,64,"b5a377")
  _block(44,43,7,7,"7d8060")
  _block(65,49,7,7,"7d8060")
  _block(53,69,7,7,"7d8060")
  _block(54,34,5,20,"d8c797")
 else:
  _block(25,54,70,18,"95aa7d")
  _block(35,39,56,43,"aaba86")
  _block(47,30,32,61,"aaba86")
  _block(56,37,5,54,"d4d6a6")
  for i in range(3):
   _block(36+i*6,49+i*11,22-i*4,3,"c7d19c")
   _block(62,48+i*12,21-i*4,3,"c7d19c")
  _block(54,89,6,15,"7f946d")

func _update_detailed_portrait() -> void:
 if not is_inside_tree():return
 if not DetailedVisitor.is_creature(entry_id):
  if is_instance_valid(_portrait):_portrait.hide()
  var path: String="res://assets/collection/v2/"+entry_id+".png"
  _postcard=load(path) as Texture2D if ResourceLoader.exists(path) else null
  return
 _postcard=null
 if not is_instance_valid(_portrait):
  _portrait=DetailedVisitor.new()
  _portrait.name="DetailedVisitor"
  add_child(_portrait)
 _portrait.show()
 _portrait.actor=DetailedVisitor.portrait_actor(entry_id,_elapsed if animated else 1.5)
 _portrait.context={"light":Color.WHITE,"alpha":1.0,"activity":0.7}
 var area: Rect2=DetailedVisitor.bounds_for_actor(_portrait.actor)
 var fit: float=minf((size.x-16.0)/maxf(1.0,area.size.x),(size.y-14.0)/maxf(1.0,area.size.y))
 _portrait.scale=Vector2.ONE*fit
 _portrait.position=size*0.5-area.get_center()*fit
 if not discovered:
  var mask: ShaderMaterial=ShaderMaterial.new()
  mask.shader=Silhouette
  _portrait.material=mask
 else:_portrait.material=null
 _portrait.queue_redraw()

func _draw_portrait_habitat() -> void:
 var base: Color=Color("e4e4d4") if discovered else Color("c3c9ba")
 draw_rect(Rect2(Vector2.ZERO,size),base)
 # Subtle field-note wash; the visitor, not a blocky landscape, fills the card.
 for band: int in range(8):
  var color: Color=Color("c1d0c4").lerp(base,float(band)/8.0)
  if not discovered:color=base
  draw_rect(Rect2(0,band*size.y/8.0,size.x,size.y/8.0+1),color)
 if is_instance_valid(_portrait) and not bool(_portrait.actor.get("fly",false)):
  var foot: Vector2=_portrait.position
  var y: float=clampf(foot.y+2.0,10.0,size.y-6.0)
  draw_line(Vector2(8,y+1),Vector2(size.x-8,y+4),Color("8c8d71"),4.0)
  draw_line(Vector2(8,y),Vector2(size.x-8,y+3),Color("a6a389"),1.0)
