extends RefCounted
## Original native 32 px pixel icons. Textures remain crisp at every fieldkit size.
static var _cache: Dictionary = {}
const INK = Color("384235")
const PAPER = Color("faf6e8")
const OLIVE = Color("7f9255")
const BLUE = Color("6d8796")
const GOLD = Color("d4a65c")

static func _rect(im: Image,x: int,y: int,w: int,h: int,c: Color) -> void:
 for py: int in range(maxi(0,y),mini(32,y+h)):
  for px: int in range(maxi(0,x),mini(32,x+w)): im.set_pixel(px,py,c)

static func _line(im: Image,a: Vector2i,b: Vector2i,c: Color,width: int = 1) -> void:
 var distance: int = maxi(absi(b.x-a.x),absi(b.y-a.y))
 for i: int in range(distance+1):
  var t: float = float(i)/maxf(1.0,float(distance))
  _rect(im,roundi(lerpf(a.x,b.x,t)),roundi(lerpf(a.y,b.y,t)),width,width,c)

static func _stamp(im: Image,rows: Array,colors: Dictionary,offset: Vector2i = Vector2i(4,8)) -> void:
 for y: int in range(rows.size()):
  var row: String = str(rows[y])
  for x: int in range(row.length()):
   var key: String = row.substr(x,1)
   if colors.has(key): _rect(im,x+offset.x,y+offset.y,1,1,colors[key])

static func _star(im: Image,center: Vector2i,r: int,c: Color) -> void:
 for y: int in range(-r,r+1):
  var half: int = maxi(0,roundi((r-absi(y))*0.45))
  _rect(im,center.x-half,center.y+y,half*2+1,1,c)
 _rect(im,center.x-r,center.y-1,r*2+1,3,c)
 _rect(im,center.x-1,center.y-2,2,4,PAPER)

static func texture(id: String) -> Texture2D:
 if _cache.has(id): return _cache[id]
 var im: Image = Image.create(32,32,false,Image.FORMAT_RGBA8)
 im.fill(Color.TRANSPARENT)
 var key: String = id
 if key.begins_with("scene_"): key = key.trim_prefix("scene_")
 if key in ["aurora","star_whale","time_ripple","tree_spirit","lanterns","ghost_train","moon_gate","signal_echo","aurora_crown","ember_clouds","meteor_shower","deep_one","sunken_city","sky_jellyfish","twin_moons","floating_isles","bioluminescent_tide","constellation_stag","supernova"]: key = "sparkle"
 if key in ["guide","birds"]: key = "book" if key == "guide" else "bird"
 if key in ["animal","animals"]: key = "squirrel"
 if key in ["insect","insects"]: key = "butterfly"
 if key in ["rare","wonders"]: key = "sparkle"
 match key:
  "observe","binoculars":
   _rect(im,5,6,8,5,INK); _rect(im,19,6,8,5,INK)
   _rect(im,3,11,12,16,INK); _rect(im,17,11,12,16,INK)
   _rect(im,5,12,8,8,OLIVE); _rect(im,19,12,8,8,OLIVE)
   _rect(im,13,13,6,5,INK); _rect(im,6,8,5,3,Color("b6bea5")); _rect(im,20,8,5,3,Color("b6bea5"))
   _rect(im,5,21,8,5,BLUE); _rect(im,19,21,8,5,BLUE)
   _rect(im,6,21,3,2,PAPER); _rect(im,20,21,3,2,PAPER)
  "sunflower":
   _rect(im,8,5,16,4,INK); _rect(im,7,9,18,19,INK)
   _rect(im,9,6,14,3,Color("bda67a")); _rect(im,9,10,14,16,Color("e1cca3"))
   _rect(im,11,13,10,9,GOLD); _rect(im,13,11,6,13,GOLD)
   _rect(im,13,15,6,5,INK); _rect(im,15,16,2,2,Color("a2804f"))
   _rect(im,9,25,14,1,Color("b49866"))
  "feed","millet":
   _rect(im,4,20,24,5,INK); _rect(im,7,25,18,3,INK)
   _rect(im,6,19,20,4,Color("b7c2bd")); _rect(im,9,24,14,2,BLUE)
   for pos: Vector2i in [Vector2i(8,16),Vector2i(13,14),Vector2i(18,17),Vector2i(22,14),Vector2i(13,18),Vector2i(18,12)]:
    _rect(im,pos.x,pos.y,3,3,GOLD); _rect(im,pos.x,pos.y,1,2,INK)
   _line(im,Vector2i(24,13),Vector2i(29,6),INK,3)
   _line(im,Vector2i(24,13),Vector2i(28,7),Color("a68562"),1)
  "berries":
   _line(im,Vector2i(14,16),Vector2i(20,5),OLIVE,2)
   _rect(im,18,5,8,3,OLIVE); _rect(im,11,7,7,3,Color("a5b874"))
   for pos: Vector2i in [Vector2i(7,16),Vector2i(15,13),Vector2i(17,21)]:
    _rect(im,pos.x,pos.y,8,7,INK); _rect(im,pos.x+1,pos.y,6,7,Color("a86c64")); _rect(im,pos.x+2,pos.y+1,2,2,Color("e2aa88"))
  "book":
   _rect(im,3,7,26,20,INK); _rect(im,4,6,11,19,OLIVE); _rect(im,17,6,11,19,OLIVE)
   _rect(im,6,5,9,18,PAPER); _rect(im,17,5,9,18,Color("e4dfc8")); _rect(im,15,7,2,18,INK)
   for y: int in [10,14,18]:
    _rect(im,8,y,5,1,Color("a1ab88")); _rect(im,19,y,5,1,Color("a1ab88"))
   _rect(im,20,5,3,8,GOLD)
  "sparkle","star":
   _star(im,Vector2i(15,17),10,INK); _star(im,Vector2i(15,17),8,GOLD)
   _star(im,Vector2i(25,7),3,BLUE); _star(im,Vector2i(6,6),2,OLIVE)
  "focus","headphones":
   _rect(im,8,4,16,3,INK); _rect(im,5,7,3,15,INK); _rect(im,24,7,3,15,INK)
   _rect(im,8,7,3,6,OLIVE); _rect(im,21,7,3,6,OLIVE)
   _rect(im,3,17,8,11,INK); _rect(im,21,17,8,11,INK)
   _rect(im,5,18,4,8,BLUE); _rect(im,23,18,4,8,BLUE)
   _rect(im,6,18,2,3,Color("c2d3cf")); _rect(im,24,18,2,3,Color("c2d3cf"))
  "sun","scenery","dawn","dusk":
   _rect(im,10,10,12,12,INK); _rect(im,12,8,8,16,INK); _rect(im,8,12,16,8,INK)
   _rect(im,11,11,10,10,GOLD); _rect(im,13,9,6,14,GOLD); _rect(im,9,13,14,6,GOLD)
   _rect(im,13,11,3,3,PAPER)
   for a: Vector2i in [Vector2i(14,2),Vector2i(14,27),Vector2i(2,14),Vector2i(27,14)]: _rect(im,a.x,a.y,3,3,GOLD)
   if key in ["scenery","dawn","dusk"]:
    _rect(im,4,23,25,2,BLUE); _rect(im,7,27,20,2,Color("a0b4ac"))
  "cloud","rain","snow","fog","storm":
   _rect(im,5,10,22,10,INK); _rect(im,10,6,11,5,INK)
   _rect(im,7,11,18,7,Color("bdc8bf")); _rect(im,11,8,8,7,Color("dce2d7"))
   if key == "rain":
    for x: int in [8,16,24]: _line(im,Vector2i(x,23),Vector2i(x-2,28),BLUE,2)
   elif key == "snow":
    for x: int in [7,16,25]:
     _rect(im,x,24,1,5,BLUE); _rect(im,x-2,26,5,1,BLUE)
   elif key == "storm":
    _line(im,Vector2i(18,18),Vector2i(13,24),GOLD,3); _line(im,Vector2i(18,23),Vector2i(13,29),GOLD,3)
   elif key == "fog":
    _rect(im,4,24,24,2,BLUE); _rect(im,8,28,18,1,BLUE)
  "moon","night":
   _rect(im,10,4,12,24,INK); _rect(im,6,8,17,16,INK)
   _rect(im,10,6,11,20,Color("e1d6a3")); _rect(im,8,10,13,12,Color("e1d6a3"))
   _rect(im,17,3,10,17,Color.TRANSPARENT); _rect(im,14,5,9,11,Color.TRANSPARENT)
   _star(im,Vector2i(26,7),3,GOLD); _star(im,Vector2i(24,24),2,BLUE)
  "audio","speaker","sound":
   _rect(im,4,13,7,9,INK); _rect(im,11,10,3,15,INK); _rect(im,14,7,3,21,INK)
   _rect(im,6,15,5,5,OLIVE); _rect(im,12,12,3,11,OLIVE)
   _rect(im,21,11,2,13,BLUE); _rect(im,25,8,2,19,BLUE)
  "wind":
   _rect(im,4,10,20,2,BLUE); _rect(im,24,6,2,6,BLUE); _rect(im,21,5,4,2,BLUE)
   _rect(im,7,17,23,2,OLIVE); _rect(im,4,24,17,2,BLUE)
   _rect(im,20,24,2,5,BLUE); _rect(im,17,28,4,2,BLUE)
  "river":
   for y: int in [8,15,22]:
    _rect(im,3,y,10,2,BLUE); _rect(im,13,y+2,11,2,BLUE); _rect(im,24,y,5,2,BLUE)
  "close":
   _line(im,Vector2i(8,8),Vector2i(22,22),INK,3); _line(im,Vector2i(22,8),Vector2i(8,22),INK,3)
  "plus":
   _rect(im,14,7,3,19,INK); _rect(im,6,15,20,3,INK)
  "minus": _rect(im,7,15,18,3,INK)
  "check":
   _line(im,Vector2i(5,17),Vector2i(12,24),OLIVE,3); _line(im,Vector2i(12,24),Vector2i(26,8),OLIVE,3)
  "play":
   for x: int in range(10,25):
    var half: int = 10-roundi(float(x-10)*0.67)
    _rect(im,x,16-half,1,half*2+1,OLIVE if x > 10 else INK)
  "pause":
   _rect(im,8,6,6,21,INK); _rect(im,19,6,6,21,INK); _rect(im,9,7,4,19,GOLD); _rect(im,20,7,4,19,GOLD)
  "search":
   _rect(im,5,5,17,17,INK); _rect(im,7,7,13,13,BLUE); _rect(im,9,9,8,8,Color("d7e4d5")); _line(im,Vector2i(21,21),Vector2i(28,28),INK,4)
  "lock":
   _rect(im,9,4,14,14,INK); _rect(im,12,7,8,9,PAPER); _rect(im,6,14,20,15,INK); _rect(im,8,16,16,11,GOLD); _rect(im,15,19,3,6,INK)
  "branch":
   _line(im,Vector2i(4,28),Vector2i(24,5),Color("8d7655"),3)
   for pos: Vector2i in [Vector2i(5,11),Vector2i(17,16),Vector2i(19,4)]:
    _rect(im,pos.x,pos.y,9,4,OLIVE); _rect(im,pos.x+2,pos.y-2,5,2,Color("a8b971"))
  "clock":
   _rect(im,6,5,20,23,INK); _rect(im,4,8,24,17,INK); _rect(im,7,7,18,19,PAPER); _rect(im,6,10,20,13,PAPER)
   _line(im,Vector2i(16,10),Vector2i(16,17),INK,2); _line(im,Vector2i(16,17),Vector2i(22,20),BLUE,2)
  "squirrel":
   _stamp(im,["...OOOO.................","..OHHHHO................",".OHHHHHHO...............","OHHH..OHHO..............","OHH....OHHO.........OO..","OHH....OHHO........OHHO.",".OHHHHHHHO......OOOHHHO.","..OHHHHHO.....OOHHHHHEO.","...OHHHO.....OHHHHHHHHO.","....OHHHO...OHHHHHCCOO..",".....OHHHOOOHHHHHCCCO...","......OHHHHHHHHHCCCCO...",".......OHHHHHHHHCCCO....","........OOHHHHHHHOO.....","..........OOOOOOOOO....."],{"O":INK,"H":Color("b28a5a"),"C":Color("e0c79d"),"E":PAPER},Vector2i(3,8))
  "cat":
   _stamp(im,["..............OO....OO..","..............OHO..OHO..","..............OHHOOHHO..","..............OHHHHHHO..","..............OHEHHEHO..","..OO..........OHHHHHHO..",".OHHO......OOOOHCCCHOO..",".OHHO....OOHHHHCCCCO....",".OHHO...OHHHHHHCCCCO....","..OHHO..OHHHHHHHCCCO....","...OHHOOHHHHHHHHCCO.....","....OHHHHHHHHHHHHHO.....",".....OOOOOOOOOOOOOO.....",".........OO....OO......."],{"O":INK,"H":Color("a6a995"),"C":PAPER,"E":Color("e4bb76")},Vector2i(3,9))
  "hedgehog":
   _stamp(im,["......O..O..O...........","....OOHOOHOOHOO.........","...OHHHHHHHHHHHO........","..OHHHHHHHHHHHHHO.......",".OHHHHHHHHHHHHHHHOO.....","OHHHHHHHHHHHHHHCCCCOO...","OHHHHHHHHHHHHHCCECCCCO..",".OHHHHHHHHHHHCCCCCCCO...","..OOOOOOOOOOOOOOOOOO....","....OO.......OO........."],{"O":INK,"H":Color("9f8b6b"),"C":Color("d8c69c"),"E":INK},Vector2i(4,14))
  "bat":
   _stamp(im,["...........O..O...........","..........OHOOHO..........","...OOO....OHEEHO....OOO...","..OHHHOO..OHHHHO..OOHHHO..",".OHHHHHHOOHHHHHHOOHHHHHHO.","OHHHHHHHHHHHHHHHHHHHHHHHHO","OOOHHHHHHHHHHHHHHHHHHHHOOO","...OOOHHHHHHHHHHHHHHOOO...","......OOOOOHHHHOOOOO......","...........OOOO..........."],{"O":INK,"H":BLUE,"E":PAPER},Vector2i(3,10))
  "butterfly","luna_moth":
   var wing: Color = Color("91b08b") if key == "luna_moth" else GOLD
   _stamp(im,["..OOO......OOO..",".OHHHO....OHHHO.","OHHHHHO..OHHHHHO","OHHHWHO..OHWHHHO",".OHHHHOOOOHHHHO.","..OHHHHOOHHHHO..","...OOOOOOOOOO...","..OHHHHO OHHHO..","..OHHHO..OHHHO..","...OOO....OOO..."],{"O":INK,"H":wing,"W":PAPER},Vector2i(8,10))
   _line(im,Vector2i(14,10),Vector2i(12,6),INK); _line(im,Vector2i(17,10),Vector2i(20,6),INK)
   _rect(im,15,12,2,12,INK)
   if key == "luna_moth":
    _line(im,Vector2i(11,19),Vector2i(9,26),wing,2); _line(im,Vector2i(20,19),Vector2i(22,26),wing,2)
  "dragonfly":
   _stamp(im,["..OOOO......OOOO..",".OWWWWO....OWWWWO.","..OWWWWO..OWWWWO..","...OWWWWOOOWWWO...","....OOOOHHOOOO....","...OWWWWOOOWWWO...","..OWWWWO..OWWWWO..","...OOOO....OOOO...","........HH........","........HH........","........HH........","........OO........"],{"O":INK,"H":Color("9b7360"),"W":Color("b1cbd0")},Vector2i(7,10))
   _rect(im,14,7,5,4,INK); _rect(im,15,8,1,1,PAPER); _rect(im,18,8,1,1,PAPER)
  "ladybug":
   _rect(im,12,7,8,6,INK); _rect(im,7,12,18,14,INK); _rect(im,10,26,12,2,INK)
   _rect(im,9,12,14,13,Color("bc6d56")); _rect(im,15,12,2,14,INK)
   for pos: Vector2i in [Vector2i(10,15),Vector2i(19,15),Vector2i(11,21),Vector2i(18,21)]: _rect(im,pos.x,pos.y,3,3,INK)
   _rect(im,12,8,2,2,PAPER); _rect(im,18,8,2,2,PAPER)
   _line(im,Vector2i(7,16),Vector2i(4,14),INK); _line(im,Vector2i(24,16),Vector2i(27,14),INK)
   _line(im,Vector2i(7,23),Vector2i(4,25),INK); _line(im,Vector2i(24,23),Vector2i(27,25),INK)
  "jewel_beetle","stag_beetle":
   var shell: Color = OLIVE if key == "jewel_beetle" else Color("947b55")
   _rect(im,12,9,8,6,INK); _rect(im,9,14,14,13,INK); _rect(im,12,27,8,2,INK)
   _rect(im,11,14,10,12,shell); _rect(im,15,14,2,14,INK); _rect(im,12,16,2,6,Color("c1d1a2"))
   for y: int in [15,20,25]:
    _line(im,Vector2i(9,y),Vector2i(5,y+2),INK); _line(im,Vector2i(22,y),Vector2i(26,y+2),INK)
   if key == "stag_beetle":
    _line(im,Vector2i(12,11),Vector2i(10,4),INK,2); _line(im,Vector2i(20,11),Vector2i(22,4),INK,2)
    _rect(im,10,4,4,2,INK); _rect(im,20,4,4,2,INK)
   else:
    _line(im,Vector2i(13,9),Vector2i(10,6),INK); _line(im,Vector2i(19,9),Vector2i(22,6),INK)
  "fireflies":
   _star(im,Vector2i(8,11),4,GOLD); _star(im,Vector2i(24,9),3,OLIVE)
   _rect(im,13,16,6,8,INK); _rect(im,14,21,4,6,GOLD); _rect(im,15,22,2,3,PAPER)
   _rect(im,9,16,4,4,Color("acbfac")); _rect(im,19,16,4,4,Color("acbfac"))
  "ufo":
   _rect(im,11,7,10,8,INK); _rect(im,12,9,8,6,BLUE); _rect(im,13,9,3,2,PAPER)
   _rect(im,5,15,22,4,INK); _rect(im,2,19,28,3,INK); _rect(im,6,17,20,3,Color("a9b4a1"))
   for x: int in [7,14,21]: _rect(im,x,19,3,2,GOLD)
   _rect(im,10,25,2,3,OLIVE); _rect(im,20,25,2,3,OLIVE)
  "meteor":
   _line(im,Vector2i(24,6),Vector2i(12,19),GOLD,3); _line(im,Vector2i(29,7),Vector2i(15,22),Color("c5b887"),2)
   _star(im,Vector2i(10,23),6,INK); _star(im,Vector2i(10,23),4,GOLD)
  _:
   var feather: Color = Color("a38c64")
   var chest: Color = Color("d8c69c")
   var head: Color = Color("92734f")
   match key:
    "tit": feather = BLUE; chest = Color("d8c36d"); head = INK
    "robin": feather = Color("9b8a69"); chest = Color("c7835e")
    "kingfisher": feather = Color("568997"); chest = Color("d4a65c"); head = BLUE
    "white_eye": feather = OLIVE; chest = Color("d5d7ae"); head = OLIVE
    "magpie","swallow": feather = Color("536474"); chest = PAPER; head = INK
    "egret": feather = Color("c6d3c9"); chest = PAPER; head = PAPER
    "woodpecker": feather = INK; chest = PAPER; head = Color("ae6f58")
    "owl": feather = Color("a79072"); chest = Color("d3c4a5")
   _stamp(im,["...........OOOO....","..........OHHHHO...","..........OHHEHOO..",".........OHHHHHOBB.","....OOOOOHHHHOO....","...OWWWWWWWCCCO....","..OWWWWWWWCCCCCO...",".OTWWWWWWWCCCCO....","OTTWWWWWCCCCOO.....","TTTOOOOOOOOO.......",".....L..L..........","....LL..LL........."],{"O":INK,"H":head,"E":PAPER,"B":GOLD,"W":feather,"C":chest,"T":feather.darkened(.2),"L":INK},Vector2i(6,9))
   _rect(im,8,23,19,2,Color("9e8c67")); _rect(im,24,21,4,2,OLIVE)
 var result: Texture2D = ImageTexture.create_from_image(im)
 _cache[id] = result
 return result
