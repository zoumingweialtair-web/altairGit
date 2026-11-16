extends RefCounted
## Fine-grained native bird illustration. Every moving part shares the same plumage and anatomy.
const IDS: Array[String] = ["sparrow","tit","robin","woodpecker","owl","kingfisher","swallow","magpie","white_eye","egret"]
const PALETTES: Dictionary = {
 "sparrow":["9b7955","6b5542","cbb28a","ded0aa","776452","926447","a9936d"],
 "tit":["68858a","3b5260","a8b7aa","d4c672","577681","293b3c","d1bb85"],
 "robin":["948266","665943","c6b18a","dba16d","7e755d","b77c51","b5a67f"],
 "woodpecker":["414c4a","293532","7d8e7c","e3dcc4","3d4b49","b95144","9c9982"],
 "owl":["9b9070","635f4c","ccc1a0","d2c5a1","83785e","9e9274","a49b74"],
 "kingfisher":["448e95","315866","8bc0b4","d69b60","347486","357e87","738c85"],
 "swallow":["3d5965","263943","72909a","d9d5bd","345563","354c57","767b70"],
 "magpie":["3e5b60","273a3d","789a91","e4dfc8","3d6570","344f53","7c8c82"],
 "white_eye":["8a9a57","5d6f44","c6cd8a","e5dfae","7e914e","9dab60","a9ae81"],
 "egret":["e5e4cf","99afa9","fff4da","f2edda","c7d4c9","e6e5cf","bfa572"]
}
static func bounds(id: String, flying: bool = false) -> Rect2:
 if flying:
  if id=="egret":return Rect2(-122,-140,205,210)
  return Rect2(-85,-110,158,177)
 match id:
  "egret":return Rect2(-42,-92,93,99)
  "owl":return Rect2(-39,-70,80,76)
  "magpie":return Rect2(-68,-53,113,59)
  "woodpecker":return Rect2(-59,-58,93,80)
  _:return Rect2(-52,-53,98,59)

static func draw_bird(canvas: Node2D, actor: Dictionary, context: Dictionary = {}) -> void:
 if str(actor.get("id","")) not in IDS:return
 var painter: Painter=Painter.new(canvas,actor,context)
 painter.paint()
 canvas.draw_set_transform(Vector2.ZERO)

class Painter:
 extends RefCounted
 var c: Node2D
 var a: Dictionary
 var id: String
 var t: float
 var alpha: float
 var light: Color
 var activity: float
 var palette: Array
 var back: Color
 var shade: Color
 var bright: Color
 var breast: Color
 var wing: Color
 var head: Color
 var beak: Color
 var ink: Color=Color("34463f")
 var group: Transform2D=Transform2D.IDENTITY
 var flying: bool
 var mode: String
 var pose: String
 var landing: float
 var reach: float
 var fan: float
 var head_offset: Vector2=Vector2.ZERO
 var head_angle: float=0.0

 func _init(canvas: Node2D,actor: Dictionary,context: Dictionary) -> void:
  c=canvas;a=actor;id=str(a["id"])
  t=float(a.get("motion_age",a.get("age",0.0)))
  alpha=float(context.get("alpha",a.get("alpha",1.0)))
  light=context.get("light",Color.WHITE)
  activity=float(context.get("activity",1.0))
  palette=PALETTES[id]
  back=Color(palette[0]);shade=Color(palette[1]);bright=Color(palette[2]);breast=Color(palette[3]);wing=Color(palette[4]);head=Color(palette[5]);beak=Color(palette[6])
  flying=bool(a.get("fly",false));mode=str(a.get("flight_mode","flap" if flying else "perch"));pose=str(a.get("pose","perch"))
  landing=clampf(float(a.get("perch_blend",a.get("land_blend",0.0 if flying else 1.0))),0,1)
  if not flying:landing=1.0
  reach=clampf(float(a.get("feet_reach",landing)),0,1)
  fan=clampf(float(a.get("tail_spread",0.65 if mode in ["brake","land"] else 0.1)),0,1)

 func color(value: Color) -> Color:
  return Color(value.r*light.r,value.g*light.g,value.b*light.b,value.a*alpha)

 func point(v: Vector2) -> Vector2:
  return (group*v).round()

 func poly(points: Array,color_value: Color,outline: bool = false) -> void:
  var verts: PackedVector2Array=PackedVector2Array()
  for p: Vector2 in points:verts.append(point(p))
  if Geometry2D.triangulate_polygon(verts).is_empty():return
  c.draw_colored_polygon(verts,color(color_value))
  if outline:
   verts.append(verts[0])
   c.draw_polyline(verts,color(shade.darkened(0.12)),1.0,false)

 func ellipse(center: Vector2,radius: Vector2,color_value: Color,angle: float = 0.0,outline: bool = false) -> void:
  var points: Array=[]
  for n: int in range(28):
   var theta: float=TAU*float(n)/28.0
   points.append(center+Vector2(cos(theta)*radius.x,sin(theta)*radius.y).rotated(angle))
  poly(points,color_value,outline)

 func line(points: Array,col: Color,width: float = 1.0) -> void:
  var verts: PackedVector2Array=PackedVector2Array()
  for p: Vector2 in points:verts.append(point(p))
  c.draw_polyline(verts,color(col),width,false)

 func curve(p0: Vector2,p1: Vector2,p2: Vector2,col: Color,width: float = 1.0) -> void:
  var points: Array=[]
  for n: int in range(9):
   var u: float=float(n)/8.0
   points.append(p0*(1-u)*(1-u)+p1*2*u*(1-u)+p2*u*u)
  line(points,col,width)

 func dot(p: Vector2,col: Color,size: Vector2 = Vector2.ONE) -> void:
  c.draw_rect(Rect2(point(p),size),color(col))

 func feather(base: Vector2,tip: Vector2,width: float,col: Color,quill: bool = true) -> void:
  var direction: Vector2=(tip-base).normalized()
  if direction.length_squared()<0.5:return
  var normal: Vector2=Vector2(-direction.y,direction.x)
  poly([base-normal*width*0.45,base+direction*(base.distance_to(tip)*0.3)-normal*width*0.55,tip-normal*0.55,tip+direction*0.6,tip+normal*0.75,base+direction*(base.distance_to(tip)*0.27)+normal*width*0.5,base+normal*width*0.25],col)
  if quill:line([base+direction*2,tip-direction*1.6],col.lightened(0.16),1)

 func paint() -> void:
  var pos: Vector2=a.get("pos",Vector2.ZERO)
  var facing: float=float(a.get("facing",1.0))
  var angle: float=float(a.get("body_tilt",0.0))*facing
  if id in ["woodpecker"] and not flying:angle=0.0
  c.draw_set_transform(pos,angle,Vector2(facing*clampf(float(a.get("turn_scale",1.0)),0.35,1.0),1))
  if id=="egret":egret();return
  if id=="owl":owl();return
  if id=="woodpecker" and not flying:woodpecker();return
  var cycle: float=fmod(t+float(id.length())*.29,6.8)
  if not flying:
   head_offset=Vector2(sin(t*.63)*0.65,0)
   head_angle=sin(t*.73)*0.045
   if pose in ["peck","feed"]:
    var peck: float=pow(maxf(0,sin(t*7.2)),4)
    head_offset=Vector2(3*peck,8*peck)
    head_angle=0.62*peck
   elif pose=="preen":
    head_offset=Vector2(-7,3+sin(t*3)*.5)
    head_angle=1.1+sin(t*3)*.12
   elif cycle>5.1:
    head_angle=-.1
    head_offset=Vector2(1,-1)
  if flying:flight_wing(true)
  tail()
  feet()
  body()
  if flying and landing<0.94:flight_wing(false)
  else:folded_wing()
  passerine_head()
  if not flying and pose=="preen":
   feather(Vector2(-8,-27),Vector2(-17,-32),2.1,bright)

 func body() -> void:
  var shape: float=0.87 if id in ["swallow","kingfisher"] else 1.0
  ellipse(Vector2(-5,-17),Vector2(20,13)*Vector2(1,shape),shade,0.10,true)
  ellipse(Vector2(-5,-19),Vector2(19,12)*Vector2(1,shape),back,0.13)
  ellipse(Vector2(3,-14),Vector2(14,10)*Vector2(1,shape),breast,-0.30)
  ellipse(Vector2(7,-17),Vector2(10,7),breast.lightened(.1),-0.42)
  curve(Vector2(-17,-25),Vector2(-6,-32),Vector2(7,-27),bright,1)
  if id=="tit":
   poly([Vector2(10,-25),Vector2(8,-22),Vector2(5,-12),Vector2(1,-6),Vector2(-2,-7),Vector2(2,-18),Vector2(5,-27)],shade)
  elif id=="robin":
   ellipse(Vector2(10,-23),Vector2(8,10),Color("c9814f"),-.28)
   ellipse(Vector2(11,-24),Vector2(6,8),Color("e0a469"),-.28)
   curve(Vector2(2,-23),Vector2(7,-10),Vector2(11,-12),Color("f0bd84"),1)
  elif id=="magpie":
   poly([Vector2(-5,-26),Vector2(7,-27),Vector2(11,-16),Vector2(5,-8),Vector2(-5,-9),Vector2(-9,-18)],breast)
  elif id=="kingfisher":
   curve(Vector2(-18,-24),Vector2(-8,-30),Vector2(1,-28),Color("7fc5c0"),2)
   poly([Vector2(7,-28),Vector2(13,-25),Vector2(12,-20),Vector2(7,-21)],Color("e9e6c9"))
  for n: int in range(12):
   var p: Vector2=Vector2(-11+(n%4)*5,-21+int(n/4)*5)
   var col: Color=back.lerp(bright,.45) if n%3==0 else breast.darkened(.12)
   if p.x>0:col=breast.darkened(.13)
   curve(p,p+Vector2(1,1.5),p+Vector2(3,1),col,1)
  for n: int in range(4):
   feather(Vector2(-2+n*3,-7),Vector2(-3+n*3,-4.4+sin(float(n))*1),1.5,breast.darkened(.08),false)

 func tail() -> void:
  var wag: float=sin(t*1.25)*1.1*activity if not flying else 0.0
  var length: float=39 if id=="magpie" else (27 if id=="swallow" else 21)
  var tail_root: Vector2=Vector2(-19,-12)
  var tail_tip: Vector2=Vector2(-22-length,-6+wag)
  if flying:tail_tip.y=-9+fan*9
  if id=="swallow":
   feather(tail_root+Vector2(0,-2),tail_tip+Vector2(-6,-8-fan*8),4,shade)
   feather(tail_root+Vector2(0,2),tail_tip+Vector2(-3,4+fan*10),4,wing)
   poly([tail_root+Vector2(-2,-4),tail_tip+Vector2(6,-1),tail_root+Vector2(-2,4)],back)
  else:
   for n: int in range(5):
    var f: float=float(n)-2
    var tip: Vector2=tail_tip+Vector2(absf(f)*2.3,f*(1.2+fan*3.2))
    feather(tail_root+Vector2(0,f*.85),tip,3.8,shade.lerp(wing,float(n)/5.0))
    if id in ["tit","magpie"] and n in [0,4]:line([tip+Vector2(7,-.2),tip],bright,1)

 func feet() -> void:
  var leg: Color=Color("7a7460")
  var feet_y: float=0.0 if not flying else lerpf(-11,2,reach)
  for n: int in range(2):
   var x: float=-6+float(n)*10
   var root: Vector2=Vector2(x,-7)
   var ankle: Vector2=Vector2(x-1,feet_y-1)
   line([root,ankle,Vector2(x+4,feet_y)],leg,1.3)
   line([ankle,Vector2(x-5,feet_y),Vector2(x-5,feet_y+1)],shade,1)
   line([ankle,Vector2(x+1,feet_y+1),Vector2(x+3,feet_y+1)],bright.darkened(.2),1)

 func folded_wing() -> void:
  var shrug: float=sin(t*1.7)*.25*activity
  poly([Vector2(-14,-28+shrug),Vector2(-3,-28+shrug),Vector2(5,-22),Vector2(0,-15),Vector2(-21,-7),Vector2(-26,-10),Vector2(-21,-24)],shade,true)
  for n: int in range(7):
   var r: float=float(n)
   var root: Vector2=Vector2(-11+r*2.0,-25+r*.35+shrug)
   var tip: Vector2=Vector2(-25+r*3.1,-9-r*.7)
   var col: Color=wing.lerp(back,.22+float(n%3)*.13)
   feather(root,tip,4.0,col)
  for row: int in range(3):
   for n: int in range(5-row):
    var p: Vector2=Vector2(-17+n*4+row*2,-25+row*4+shrug)
    ellipse(p,Vector2(3.0,1.7),back.lightened(float((n+row)%3)*.035),.3)
    curve(p+Vector2(-2,-1),p+Vector2(0,-1.7),p+Vector2(2,-.5),bright.darkened(.10),1)
  if id in ["sparrow","tit","magpie","woodpecker"]:
   curve(Vector2(-16,-22),Vector2(-8,-20),Vector2(-2,-18),bright,1.6)
   curve(Vector2(-18,-17),Vector2(-13,-14),Vector2(-8,-13),bright.darkened(.08),1)
  if id=="kingfisher":
   for n: int in range(7):dot(Vector2(-18+(n%4)*4,-23+int(n/4)*5),Color("85cecd"))

 func flight_wing(far: bool) -> void:
  var frequency: float=6.4
  if id in ["owl","egret"]:frequency=2.6
  elif id in ["swallow","kingfisher"]:frequency=5.4
  var q: float=float(a.get("wing_phase",fmod(t*frequency,1.0)))
  var down: bool=q<0.43
  var u: float=q/.43 if down else (q-.43)/.57
  var angle: float=lerpf(-1.15,1.05,smoothstep(0,1,u)) if down else lerpf(1.05,-1.15,smoothstep(0,1,u))
  var extension: float=1.0 if down else 1.0-sin(u*PI)*.34
  var power: float=clampf(float(a.get("wing_power",a.get("wing_strength",1.0))),.15,1.0)
  if mode=="glide":angle=-.19+sin(t*2.0)*.045;extension=1.12
  if mode in ["brake","land"]:power=1.0
  angle*=power
  var scale: float=(.78 if far else 1.0)*(1.5 if id=="egret" else (1.26 if id=="owl" else 1.0))
  var offset: Vector2=Vector2(0,-17 if id=="egret" else (-8 if id=="owl" else 0))
  var root: Vector2=Vector2(-3,-23)+Vector2(4 if far else 0,-1 if far else 0)+offset
  var elbow: Vector2=root+Vector2(-12*extension,sin(angle)*18)*scale
  var wrist: Vector2=root+Vector2(-28*extension,sin(angle)*32)*scale
  var tipbase: Vector2=root+Vector2(-40*extension,sin(angle)*48)*scale
  var blend: float=landing if mode in ["land","perch"] else 0.0
  elbow=elbow.lerp(Vector2(-10,-25)+offset,blend)
  wrist=wrist.lerp(Vector2(-19,-16)+offset,blend)
  tipbase=tipbase.lerp(Vector2(-26,-9)+offset,blend)
  var wc: Color=wing.darkened(.13) if far else wing
  var darkest: Color=shade.darkened(.05) if far else shade
  poly([root+Vector2(4,3),elbow+Vector2(3,-3),wrist+Vector2(-1,-2),tipbase+Vector2(-3,1),wrist+Vector2(6,7),elbow+Vector2(7,7),root+Vector2(6,7)],wc,true)
  var spread: float=1.0-blend*.72
  var direction: Vector2=(tipbase-wrist).normalized()
  var normal: Vector2=Vector2(-direction.y,direction.x)
  for n: int in range(8):
   var f: float=float(n)/7.0
   var base: Vector2=wrist.lerp(elbow,f*.6)+normal*f*3
   var tip: Vector2=tipbase+Vector2(f*14,0)+normal*(f-.5)*(11+fan*5)*spread
   tip=tip.lerp(Vector2(-26+n*2.7,-9-n*.5)+offset,blend)
   feather(base,tip,(4.1+f)*scale,darkest.lerp(wc,f*.65),not far)
  for n: int in range(5):
   var p: Vector2=root.lerp(wrist,float(n)/6.0)
   var target: Vector2=p+normal*(6.0*scale)
   feather(p,target,5.2*scale,wc.lightened(.05+float(n%2)*.04),not far)
  line([root,elbow,wrist],bright.darkened(.1 if far else 0.0),1)
  if id in ["tit","magpie","woodpecker"]:
   line([root.lerp(elbow,.6)+normal*3,elbow+normal*4,wrist.lerp(elbow,.35)+normal*4],breast,1.5)

 func passerine_head() -> void:
  var old: Transform2D=group
  var head_center: Vector2=Vector2(13,-30)+head_offset
  if id=="swallow":head_center=Vector2(16,-24)+head_offset
  if id=="kingfisher":head_center=Vector2(14,-29)+head_offset
  group=Transform2D(head_angle,head_center)
  var h: Color=back if id in ["sparrow","robin","white_eye"] else (shade if id=="woodpecker" else head)
  ellipse(Vector2.ZERO,Vector2(11,10),shade,0,true)
  ellipse(Vector2(-.4,-1),Vector2(10,9),h)
  ellipse(Vector2(3,2),Vector2(7.5,6),breast)
  if id=="sparrow":
   poly([Vector2(-9,-4),Vector2(-5,-9),Vector2(4,-9),Vector2(7,-6),Vector2(0,-5)],head)
   ellipse(Vector2(1,3),Vector2(5.8,4.2),Color("eee2bd"))
   poly([Vector2(6,2),Vector2(10,3),Vector2(6,8),Vector2(0,8),Vector2(2,5)],shade)
   dot(Vector2(-1,3),shade,Vector2(2,2))
   curve(Vector2(-5,-4),Vector2(0,-5),Vector2(6,-4),bright,1)
  elif id=="woodpecker":
   ellipse(Vector2(1,2),Vector2(7,6),breast)
   poly([Vector2(-8,-6),Vector2(-5,-12),Vector2(2,-11),Vector2(4,-7),Vector2(-3,-6)],head)
   line([Vector2(-7,2),Vector2(2,4),Vector2(6,7)],shade,2)
  elif id=="tit":
   ellipse(Vector2(2,2),Vector2(6.0,4.5),Color("ece8cf"),-.15)
   poly([Vector2(-2,7),Vector2(5,7),Vector2(9,5),Vector2(5,11),Vector2(-1,10)],shade)
  elif id=="robin":
   ellipse(Vector2(4,3),Vector2(7.0,6.4),Color("d48b54"))
   ellipse(Vector2(5,2),Vector2(4,4.2),Color("e5ae77"))
  elif id=="white_eye":
   ellipse(Vector2(4,0),Vector2(4,3.5),Color("f7edd1"))
   curve(Vector2(0,-5),Vector2(5,-6),Vector2(8,-3),bright,1)
  elif id=="kingfisher":
   ellipse(Vector2(-1,-3),Vector2(9,6),back)
   line([Vector2(-6,1),Vector2(1,2),Vector2(7,1)],shade,2)
   poly([Vector2(-4,4),Vector2(1,4),Vector2(-1,8),Vector2(-5,7)],Color("f1e5c5"))
   for n: int in range(5):dot(Vector2(-6+n*3,-6+float(n%2)),bright)
  elif id=="swallow":
   ellipse(Vector2(6,5),Vector2(4,3),Color("b88767"))
  elif id=="magpie":
   curve(Vector2(-5,-7),Vector2(2,-10),Vector2(7,-5),bright.darkened(.12),1)
  var eye: Vector2=Vector2(5,-1)
  var blinking: bool=fmod(t+float(id.length())*.31,5.4)>5.26
  if blinking:curve(eye+Vector2(-2,0),eye+Vector2(0,1),eye+Vector2(2,0),ink,1)
  else:
   ellipse(eye,Vector2(2.4,2.5),Color("263a36"))
   dot(eye+Vector2(0,-1),Color("fff7df"))
   dot(eye+Vector2(1,1),Color("627263"))
  var length: float=17 if id=="kingfisher" else (9 if id=="magpie" else 8)
  var opening: float=2.2 if pose=="sing" and sin(t*8)>0.1 else 0.0
  poly([Vector2(9,-1),Vector2(10+length,1),Vector2(10,3-opening)],beak.darkened(.22),true)
  line([Vector2(10,0),Vector2(9+length,1)],beak.lightened(.2),1)
  if opening>0:
   poly([Vector2(10,4),Vector2(10+length*.75,4),Vector2(9,6)],beak)
  for n: int in range(5):
   var p: Vector2=Vector2(-7+n*2,-7-absf(sin(float(n)))*1.5)
   line([p,p+Vector2(2,1)],bright.darkened(.05),1)
  group=old

 func owl() -> void:
  if flying:
   owl_flight()
   return
  for n: int in range(5):feather(Vector2(-9+n*4,-15),Vector2(-11+n*5,-1),5,shade)
  ellipse(Vector2(0,-25),Vector2(22,24),shade,0,true)
  ellipse(Vector2(0,-27),Vector2(20,23),back)
  ellipse(Vector2(0,-23),Vector2(13,20),breast)
  for side: int in [-1,1]:
   for n: int in range(6):
    feather(Vector2(side*(12+n*.5),-41+n*3),Vector2(side*(22-n*1.3),-11+n*1.2),5,wing.lightened(float(n%2)*.04))
  for x: float in [-8.0,8.0]:
   for toe: int in range(3):curve(Vector2(x,-3),Vector2(x-4+toe*3,0),Vector2(x-3+toe*3,2),Color("b4a77d"),1.5)
  for row: int in range(5):
   for n: int in range(4):
    var p: Vector2=Vector2(-9+n*6+(row%2)*2,-31+row*5)
    feather(p,p+Vector2(0,3),1.6,shade.lightened(.12),false)
    dot(p+Vector2(2,0),bright)
  var head_y: float=-47+sin(t*.5)*.35
  var old: Transform2D=group
  group=Transform2D(sin(t*.4)*.045,Vector2(0,head_y))
  ellipse(Vector2.ZERO,Vector2(24,18),shade,0,true)
  ellipse(Vector2(0,-1),Vector2(22,17),back)
  for side: int in [-1,1]:
   ellipse(Vector2(side*10,0),Vector2(11,13),bright,side*.08)
   ellipse(Vector2(side*10,1),Vector2(8.8,10.8),breast.lightened(.1))
   curve(Vector2(side*19,-7),Vector2(side*24,3),Vector2(side*10,12),back,1)
   for n: int in range(7):
    var theta: float=-1.8+n*.5
    var p: Vector2=Vector2(side*10,0)+Vector2(cos(theta)*10,sin(theta)*12)
    line([p,p-Vector2(cos(theta)*2,sin(theta)*2)],back.lightened(.1),1)
   var eye: Vector2=Vector2(side*9,-1)
   if fmod(t+2.0,6.2)>5.95:
    curve(eye+Vector2(-5,0),eye+Vector2(0,2),eye+Vector2(5,0),shade,1.5)
   else:
    ellipse(eye,Vector2(5,5.3),Color("b8ac63"))
    ellipse(eye+Vector2(sin(t*.45)*.8,0),Vector2(2.9,3.7),Color("293c36"))
    dot(eye+Vector2(-1,-2),Color("fff1ca"),Vector2(2,1))
   curve(Vector2(side*19,-9),Vector2(side*10,-14),Vector2(side*3,-7),shade,2)
  poly([Vector2(-3,3),Vector2(3,3),Vector2(1,10),Vector2(-1,11)],Color("8b8660"))
  line([Vector2(0,4),Vector2(0,9)],bright,1)
  for n: int in range(9):feather(Vector2(-16+n*4,-16),Vector2(-16+n*4,-19+sin(float(n))*1),1.7,bright,false)
  group=old

 func woodpecker() -> void:
  # Upright zygodactyl grip; tail rests against bark rather than hanging in air.
  var turn: float=float(a.get("climb_angle",0.0))
  var old: Transform2D=group
  group=Transform2D(turn,Vector2(-14,11))
  for n: int in range(3):feather(Vector2(-5+n*4,-11),Vector2(-14+n*4,8),4,shade)
  ellipse(Vector2(0,-27),Vector2(12,23),shade,-.12,true)
  ellipse(Vector2(4,-28),Vector2(9,20),breast,-.13)
  for n: int in range(7):
   feather(Vector2(-4+n*.9,-45+n*2),Vector2(-13+n*2,-10),4,wing)
  for row: int in range(5):
   for n: int in range(2):
    ellipse(Vector2(-8+n*6,-36+row*5),Vector2(1.8,1),bright)
  for x: float in [-2.0,5.0]:
   line([Vector2(x,-14),Vector2(x+7,-11),Vector2(x+12,-12)],beak.darkened(.2),1.5)
   line([Vector2(x+7,-11),Vector2(x+10,-8)],beak.darkened(.2),1)
  var peck: float=pow(maxf(0,sin(t*9.0)),4) if pose=="peck" else 0.0
  var listen_turn: float=sin(t*0.61)*0.075 if pose!="peck" else 0.0
  group=Transform2D(-.12+peck*.34+listen_turn,Vector2(-7+peck*3+sin(t*0.43),-39+peck*2))
  ellipse(Vector2.ZERO,Vector2(11,12),shade,0,true)
  ellipse(Vector2(2,1),Vector2(8,10),breast)
  poly([Vector2(-8,-8),Vector2(-3,-14),Vector2(4,-12),Vector2(6,-8),Vector2(-2,-6)],head)
  line([Vector2(-7,0),Vector2(2,1),Vector2(8,4)],shade,2)
  if fmod(t+0.7,5.1)>4.9:
   line([Vector2(3,-2),Vector2(5,-1),Vector2(7,-2)],Color("243b34"),1.0)
  else:
   ellipse(Vector2(5,-2),Vector2(2,2),Color("243b34"))
   dot(Vector2(5,-3),Color("fff6dc"))
  poly([Vector2(10,-2),Vector2(25,0),Vector2(11,3)],beak.darkened(.2),true)
  line([Vector2(11,-1),Vector2(22,0)],bright,1)
  group=old

 func owl_flight() -> void:
  flight_wing(true)
  for n: int in range(5):feather(Vector2(-16,-24+n*2),Vector2(-39+absf(n-2)*2,-20+n*3),5,shade.lightened(n*.025))
  ellipse(Vector2(-3,-27),Vector2(24,16),shade,.15,true)
  ellipse(Vector2(-2,-28),Vector2(22,15),back,.15)
  ellipse(Vector2(6,-23),Vector2(14,11),breast,.1)
  for row: int in range(3):
   for n: int in range(6):
    var p: Vector2=Vector2(-15+n*5,-35+row*7)
    feather(p,p+Vector2(-1,3.5),2,shade.lightened(.18),false)
    dot(p+Vector2(2,0),bright)
  for n: int in range(2):
   var y: float=lerpf(-15,0,reach)
   line([Vector2(n*7,-17),Vector2(n*7-3,y),Vector2(n*7+3,y+1)],beak,1.5)
  flight_wing(false)
  var old: Transform2D=group
  group=Transform2D(-.04,Vector2(17,-37))
  ellipse(Vector2.ZERO,Vector2(15,16),shade,0,true)
  ellipse(Vector2(-1,-1),Vector2(14,15),back)
  ellipse(Vector2(4,0),Vector2(10,13),bright)
  ellipse(Vector2(5,0),Vector2(8,11),breast.lightened(.12))
  ellipse(Vector2(7,-2),Vector2(4.5,5),Color("b8ac63"))
  ellipse(Vector2(8,-2),Vector2(2.5,3.8),ink)
  dot(Vector2(8,-4),Color("fff3cf"))
  curve(Vector2(-2,-10),Vector2(6,-15),Vector2(12,-7),shade,2)
  poly([Vector2(12,2),Vector2(18,4),Vector2(14,8)],beak,true)
  for n: int in range(6):
   var p: Vector2=Vector2(-10+(n%2)*4,-9+int(n/2)*6)
   feather(p,p+Vector2(-1,3),2,bright,false)
  group=old

 func egret() -> void:
  var tucked: float=(1.0-landing) if flying else 0.0
  if flying:flight_wing(true)
  var stride: float=sin(t*1.1)*.45 if not flying else 0.0
  var leg: Color=Color("72765e")
  for n: int in range(2):
   var x: float=-7+n*9
   if flying and reach<.6:
    line([Vector2(x,-38),Vector2(-24-n*5,-25),Vector2(-45-n*5,-23)],leg,1.5)
    line([Vector2(-44-n*5,-23),Vector2(-49-n*5,-21)],leg,1)
   else:
    line([Vector2(x,-38),Vector2(x+2+stride*(n*2-1),-18),Vector2(x-1,0),Vector2(x+9,1)],leg,1.5)
    line([Vector2(x-1,0),Vector2(x-5,2)],leg,1)
  for n: int in range(4):feather(Vector2(-18,-43+n),Vector2(-35,-39+n*2),4,wing)
  ellipse(Vector2(-5,-43),Vector2(24,12),shade,.18,true)
  ellipse(Vector2(-4,-45),Vector2(23,11),back,.18)
  if flying and landing<.9:flight_wing(false)
  else:
   for n: int in range(9):
    feather(Vector2(-3+n*.4,-52+n*.4),Vector2(-30+n*3,-38+n*.2),5,wing.lightened(float(n%3)*.03))
   curve(Vector2(-22,-50),Vector2(-8,-57),Vector2(9,-49),bright,1.5)
  var neck_drop: float=tucked*23.0
  # A connected S neck folds against the chest in flight; the head stays forward.
  poly([Vector2(12,-43),Vector2(19,-49),Vector2(18,-59+neck_drop*.38),Vector2(12,-65+neck_drop*.55),Vector2(13,-73+neck_drop*.9),Vector2(24,-78+neck_drop),Vector2(27,-73+neck_drop),Vector2(20,-70+neck_drop*.9),Vector2(20,-66+neck_drop*.72),Vector2(25,-59+neck_drop*.5),Vector2(25,-50+neck_drop*.24),Vector2(19,-40)],shade,true)
  poly([Vector2(13,-43),Vector2(21,-49),Vector2(20,-58+neck_drop*.38),Vector2(15,-64+neck_drop*.55),Vector2(15,-72+neck_drop*.9),Vector2(24,-76+neck_drop),Vector2(26,-73+neck_drop),Vector2(18,-69+neck_drop*.9),Vector2(17,-65+neck_drop*.72),Vector2(23,-58+neck_drop*.5),Vector2(23,-50+neck_drop*.24),Vector2(18,-42)],back)
  curve(Vector2(17,-44),Vector2(25,-53+neck_drop*.2),Vector2(18,-62+neck_drop*.55),bright,2)
  var turn: float=sin(t*.4)*.035
  var old: Transform2D=group
  group=Transform2D(turn,Vector2(24,-77+neck_drop))
  ellipse(Vector2.ZERO,Vector2(10,7),back,0,true)
  ellipse(Vector2(1,-2),Vector2(8,4),bright)
  poly([Vector2(8,-1),Vector2(28,2),Vector2(8,4)],beak,true)
  line([Vector2(9,0),Vector2(26,2)],Color("e1ca8b"),1)
  ellipse(Vector2(4,0),Vector2(2.2,2.4),Color("9da069"))
  dot(Vector2(4,0),shade,Vector2(1,2))
  dot(Vector2(4,-1),bright)
  for n: int in range(3):curve(Vector2(-5,-3+n*2),Vector2(-14,-5+n*3),Vector2(-21,-1+n*2),back,1)
  group=old
