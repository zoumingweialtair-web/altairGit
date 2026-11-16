extends RefCounted
## Little round weirdos: clear silhouettes, calm color blocks and tiny deadpan faces.
## Feet remain at the contact origin; wings still follow the live flight state.
const IDS: Array[String]=["sparrow","tit","robin","woodpecker","owl","kingfisher","swallow","magpie","white_eye","egret"]
const PALETTES: Dictionary={
 "sparrow":["af815a","765343","d1a979","f1dfb8","956b4e","76503d","d3a15f"],
 "tit":["759c9a","415959","abc1ab","ecd880","537779","354d50","cba45f"],
 "robin":["a39072","74634d","c5b18c","e4a36b","8d8065","a18d6c","c7a16b"],
 "woodpecker":["576465","384849","89968a","eee8d0","43575b","c57058","b6a675"],
 "owl":["b3a17d","7c7059","d4c59d","f1e3bf","948365","b2a17b","c9a961"],
 "kingfisher":["62a6ab","376f7d","a5d3c7","edb17a","4d8d9b","62a6ab","84917c"],
 "swallow":["587a89","344e5b","9ab4b6","f0e7cd","456575","536f80","b58b69"],
 "magpie":["5e7b7e","364f54","9eb8ac","f0ebd6","496d79","4b6970","b1a17b"],
 "white_eye":["a4b76c","71864b","cfda98","f0e9b9","93a85e","a9ba70","bea266"],
 "egret":["eeeedd","839d94","fff9e8","fff6dd","d1dfd5","efefdf","d7b66d"]
}
static func bounds(id: String, flying: bool=false) -> Rect2:
 if flying:
  return Rect2(-114,-134,202,203) if id=="egret" else Rect2(-88,-113,161,182)
 match id:
  "egret":return Rect2(-39,-104,92,109)
  "owl":return Rect2(-37,-67,77,73)
  "magpie":return Rect2(-67,-61,108,67)
  "woodpecker":return Rect2(-46,-62,76,82)
  _:return Rect2(-47,-62,90,68)

static func draw_bird(canvas: Node2D,actor: Dictionary,context: Dictionary={}) -> void:
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
 var back: Color
 var shade: Color
 var bright: Color
 var breast: Color
 var wing: Color
 var cap: Color
 var beak: Color
 var ink: Color=Color("3e4540")
 var group: Transform2D=Transform2D.IDENTITY
 var flying: bool
 var mode: String
 var pose: String
 var landing: float
 var reach: float
 var fan: float
 var bob: float
 var face_angle: float
 var face_shift: Vector2

 func _init(canvas: Node2D,actor: Dictionary,context: Dictionary) -> void:
  c=canvas;a=actor;id=str(a["id"])
  t=float(a.get("motion_age",a.get("age",0.0)))
  alpha=float(context.get("alpha",a.get("alpha",1.0)))
  light=context.get("light",Color.WHITE)
  activity=float(context.get("activity",1.0))
  var p: Array=PALETTES[id]
  back=Color(p[0]);shade=Color(p[1]);bright=Color(p[2]);breast=Color(p[3]);wing=Color(p[4]);cap=Color(p[5]);beak=Color(p[6])
  flying=bool(a.get("fly",false));mode=str(a.get("flight_mode","flap" if flying else "perch"));pose=str(a.get("pose","perch"))
  landing=clampf(float(a.get("perch_blend",a.get("land_blend",0.0 if flying else 1.0))),0,1)
  if not flying:landing=1.0
  reach=clampf(float(a.get("feet_reach",landing)),0,1)
  fan=clampf(float(a.get("tail_spread",0.5 if mode in ["brake","land"] else 0.1)),0,1)
  bob=sin(t*2.0)*0.7*activity if not flying else 0.0
  if pose=="crouch":bob+=2.4
  # A long blank stare punctuated by a quick puzzled head tilt, then settling.
  var beat: float=fposmod(t+float(IDS.find(id))*.53,6.8)
  var double_take: float=smoothstep(3.8,4.0,beat)*(1.0-smoothstep(4.7,5.2,beat))
  face_angle=(sin(t*.58)*.025+double_take*.17)*activity if not flying else 0.0
  face_shift=Vector2(double_take*1.0,bob)
  if not flying and pose in ["peck","feed"]:
   var dip: float=pow(maxf(0.0,sin(t*7.5)),3.0)
   face_shift+=Vector2(3.0*dip,7.0*dip)
   face_angle+=dip*.38
  elif not flying and pose=="preen":
   face_shift+=Vector2(-4,3.0)
   face_angle=-.36+sin(t*3.5)*.08

 func col(v: Color) -> Color:return Color(v.r*light.r,v.g*light.g,v.b*light.b,v.a*alpha)
 func pt(v: Vector2) -> Vector2:return (group*v).round()
 func poly(points: Array,tint: Color,outline: bool=false) -> void:
  var shape: PackedVector2Array=[]
  for p: Vector2 in points:shape.append(pt(p))
  if Geometry2D.triangulate_polygon(shape).is_empty():return
  c.draw_colored_polygon(shape,col(tint))
  if outline:
   shape.append(shape[0]);c.draw_polyline(shape,col(shade),1.4,false)
 func ellipse(center: Vector2,radius: Vector2,tint: Color,angle: float=0.0,outline: bool=false) -> void:
  var points: Array=[]
  for n: int in range(36):
   var theta: float=TAU*float(n)/36.0
   points.append(center+Vector2(cos(theta)*radius.x,sin(theta)*radius.y).rotated(angle))
  poly(points,tint,outline)
 func line(points: Array,tint: Color,width: float=1.0) -> void:
  var shape: PackedVector2Array=[]
  for p: Vector2 in points:shape.append(pt(p))
  c.draw_polyline(shape,col(tint),width,false)
 func curve(start: Vector2,control: Vector2,end: Vector2,tint: Color,width: float=1.0) -> void:
  var points: Array=[]
  for n: int in range(13):
   var u: float=float(n)/12.0
   points.append(start*(1.0-u)*(1.0-u)+control*2.0*u*(1.0-u)+end*u*u)
  line(points,tint,width)
 func dot(center: Vector2,tint: Color,size: Vector2=Vector2.ONE) -> void:c.draw_rect(Rect2(pt(center),size),col(tint))

 func paint() -> void:
  var face: float=float(a.get("facing",1.0))
  var tilt: float=float(a.get("body_tilt",0.0))*face
  c.draw_set_transform(a.get("pos",Vector2.ZERO),tilt,Vector2(face*clampf(float(a.get("turn_scale",1.0)),.35,1.0),1.0))
  if id=="egret":egret();return
  if id=="woodpecker" and not flying:woodpecker();return
  if id=="owl":owl();return
  if flying:flight_wing(true)
  tail()
  feet()
  dumpling_body()
  if flying and landing<.94:flight_wing(false)
  else:folded_wing()
  face_patch()

 func dumpling_body() -> void:
  var squash: float=0.88 if flying else (1.0-sin(t*2.0)*.012*activity)
  var center: Vector2=Vector2(-1,-27+bob)
  var width: float=25.0 if id not in ["swallow","magpie"] else 23.0
  ellipse(center,Vector2(width,25.0*squash),back,0,true)
  # A large, simple pudding belly replaces the former many tiny feather marks.
  ellipse(center+Vector2(7,7),Vector2(18,17*squash),breast,-.1)
  ellipse(center+Vector2(-8,-16),Vector2(9,3),bright,-.25)
  if id=="tit":poly([Vector2(9,-28+bob),Vector2(13,-27+bob),Vector2(12,-10+bob),Vector2(8,-7+bob)],shade)
  elif id=="robin":ellipse(Vector2(11,-25+bob),Vector2(17,17),Color("e7a06c"))
  elif id=="kingfisher":ellipse(Vector2(10,-23+bob),Vector2(15,16),breast)
  elif id=="magpie":ellipse(Vector2(8,-22+bob),Vector2(15,17),breast)
  # Three soft tummy ticks are deliberate graphic punctuation, not hatching.
  if id in ["sparrow","robin"]:
   for x: float in [-2.0,4.0,10.0]:line([Vector2(x,-10+bob),Vector2(x+1,-8+bob)],breast.darkened(.09),1)
  if id in ["tit","white_eye","kingfisher"]:
   var tuft: float=sin(t*2.5)*.8*activity
   curve(Vector2(-8,-50+bob),Vector2(-7,-57+bob),Vector2(-4+tuft,-56+bob),shade,1.6)
   curve(Vector2(-6,-51+bob),Vector2(-2,-56+bob),Vector2(1+tuft,-53+bob),back,2)

 func tail() -> void:
  var wag: float=sin(t*2.3)*1.3*activity if not flying else 0.0
  var root: Vector2=Vector2(-21,-15+bob)
  var tip: Vector2=Vector2(-37,-9+wag)
  if id=="magpie":tip=Vector2(-62,-1+wag)
  if id=="swallow":
   poly([root+Vector2(0,-4),Vector2(-45,-17-fan*6),Vector2(-36,-6),Vector2(-44,2+fan*5),root+Vector2(2,5)],wing,true)
   return
  for n: int in range(3):
   var f: float=float(n-1)
   var end: Vector2=tip+Vector2(absf(f)*3,f*(3.0+fan*5.0))
   ellipse((root+end)*.5,Vector2(root.distance_to(end)*.55,3.3),wing.lerp(shade,float(n)*.13),(end-root).angle(),true)
  if id=="magpie":line([root+Vector2(-7,-1),tip+Vector2(4,-2)],bright,1.5)

 func feet() -> void:
  var foot_y: float=0.0 if not flying else lerpf(-13.0,1.0,reach)
  for x: float in [-6.0,7.0]:
   var ankle: Vector2=Vector2(x,foot_y-1.0)
   line([Vector2(x-1,-7+bob),ankle,Vector2(x+4,foot_y)],shade,1.5)
   line([ankle,Vector2(x-3,foot_y+1.0)],shade,1.3)

 func folded_wing() -> void:
  var shrug: float=sin(t*1.8)*.5*activity
  var center: Vector2=Vector2(-14,-24+bob+shrug)
  ellipse(center,Vector2(10,15),wing,.36,true)
  curve(center+Vector2(-5,-8),center+Vector2(2,-12),center+Vector2(6,-6),bright,1.5)
  # A mitten silhouette with only two rounded feather divisions.
  curve(center+Vector2(-5,5),center+Vector2(-1,10),center+Vector2(3,6),shade,1)
  curve(center+Vector2(-3,9),center+Vector2(0,13),center+Vector2(3,9),shade,1)
  if id in ["sparrow","tit","woodpecker","magpie"]:
   curve(center+Vector2(-7,-1),center+Vector2(-1,2),center+Vector2(5,-1),breast,2.0)

 func flight_wing(far: bool) -> void:
  var q: float=fposmod(float(a.get("wing_phase",t*5.0)),1.0)
  var down: bool=q<.43
  var u: float=q/.43 if down else (q-.43)/.57
  var stroke: float=lerpf(-1.0,1.0,smoothstep(0.0,1.0,u)) if down else lerpf(1.0,-1.0,smoothstep(0.0,1.0,u))
  var stretch: float=1.0 if down else 1.0-sin(u*PI)*.3
  var power: float=clampf(float(a.get("wing_power",a.get("wing_strength",1.0))),.15,1.0)
  if mode=="glide":stroke=-.19+sin(t*2.0)*.035;stretch=1.07
  if mode in ["brake","land"]:power=1.0
  stroke*=power
  var size: float=(.80 if far else 1.0)*(1.38 if id=="egret" else (1.15 if id=="owl" else 1.0))
  var offset: Vector2=Vector2(0,-18 if id=="egret" else 0)
  var root: Vector2=Vector2(-11,-33)+offset+Vector2(6 if far else 0,-3 if far else 0)
  var elbow: Vector2=root+Vector2(-13*stretch,stroke*15)*size
  var wrist: Vector2=root+Vector2(-27*stretch,stroke*30)*size
  var tip: Vector2=root+Vector2(-40*stretch,stroke*46)*size
  var fold: float=landing if mode in ["land","perch"] else 0.0
  elbow=elbow.lerp(Vector2(-15,-27)+offset,fold)
  wrist=wrist.lerp(Vector2(-19,-20)+offset,fold)
  tip=tip.lerp(Vector2(-22,-12)+offset,fold)
  var wing_color: Color=wing.darkened(.10) if far else wing
  var tangent: Vector2=(tip-wrist).normalized()
  if tangent.length_squared()<.5:tangent=Vector2.LEFT
  var normal: Vector2=Vector2(-tangent.y,tangent.x)
  # Rounded shoulder, elbow and three primary fingers; flexion on the upstroke.
  var membrane: PackedVector2Array=PackedVector2Array([root+Vector2(4,2),elbow-normal*6*size,wrist-normal*7*size,tip-normal*3*size,tip+normal*7*size,wrist+normal*12*size,elbow+normal*10*size,root+Vector2(4,7)])
  poly(Array(Geometry2D.convex_hull(membrane)),wing_color,true)
  for n: int in range(3):
   var f: float=float(n)
   var end: Vector2=tip+normal*(f*5.0-3.0)*size+Vector2(f*3,0)
   var base: Vector2=wrist+normal*(f*3.2-1.0)*size
   ellipse((base+end)*.5,Vector2(base.distance_to(end)*.55,3.3*size),wing_color,(end-base).angle(),true)
  curve(root,elbow,wrist,bright.darkened(.1 if far else 0.0),2.0)
  if id in ["tit","magpie","woodpecker"]:line([elbow+normal*2,wrist+normal*3],breast,2.2)

 func face_patch() -> void:
  var old: Transform2D=group
  group=Transform2D(face_angle,Vector2(9,-36)+face_shift)
  var face_color: Color=breast
  if id=="robin":face_color=Color("e7a06c")
  if id in ["magpie","swallow"]:face_color=cap
  if id=="kingfisher":face_color=back
  ellipse(Vector2.ZERO,Vector2(15,14),face_color)
  if id=="sparrow":
   # A bowl haircut makes the little blank face recognizably sparrow-like.
   poly([Vector2(-13,-5),Vector2(-12,-11),Vector2(-5,-16),Vector2(5,-15),Vector2(12,-10),Vector2(13,-6),Vector2(4,-8),Vector2(-2,-7)],cap)
   ellipse(Vector2(-10,6),Vector2(2.3,2.0),shade)
  elif id=="tit":
   poly([Vector2(-14,-5),Vector2(-12,-12),Vector2(-4,-16),Vector2(7,-15),Vector2(14,-8),Vector2(13,-5),Vector2(4,-8),Vector2(-6,-7)],cap)
   ellipse(Vector2(2,12),Vector2(5,3),shade)
  elif id=="woodpecker":
   ellipse(Vector2(0,-12),Vector2(12,6),cap)
  elif id=="swallow":ellipse(Vector2(6,9),Vector2(8,5),Color("d1a183"))
  elif id=="kingfisher":
   ellipse(Vector2(-10,7),Vector2(4.0,5.0),Color("f6ead0"))
   curve(Vector2(-9,-10),Vector2(-2,-15),Vector2(4,-10),bright,2.0)
  elif id=="magpie":ellipse(Vector2(-8,7),Vector2(4,5),breast)
  var eye_color: Color=Color("edf0de") if id in ["magpie","swallow"] else ink
  var blink: float=fposmod(t+float(IDS.find(id))*.63,5.5)
  var sleepy: bool=pose=="sleep" or blink>5.30
  for n: int in range(2):
   var eye: Vector2=Vector2(-4+n*12,-1+float(n))
   if id=="white_eye":ellipse(eye,Vector2(4.2,4.5),Color("fff8df"))
   if sleepy:line([eye+Vector2(-2,0),eye+Vector2(2,0)],eye_color,1.7)
   else:
    ellipse(eye,Vector2(2.1,2.6) if n==0 else Vector2(1.9,2.4),eye_color)
    if id in ["magpie","swallow"]:ellipse(eye+Vector2(.3,.3),Vector2(1.0,1.4),ink)
  var mouth: Vector2=Vector2(3,6)
  var beak_color: Color=Color("d5a263") if id not in ["woodpecker","kingfisher","magpie"] else beak
  var length: float=12.0 if id=="kingfisher" else (8.0 if id=="woodpecker" else 5.0)
  poly([mouth+Vector2(-3,-1),mouth+Vector2(length,1),mouth+Vector2(-1,4)],beak_color,true)
  if pose=="sing" and sin(t*8.0)>.25:
   ellipse(mouth+Vector2(1,4),Vector2(2.0,2.8),shade)
   line([mouth+Vector2(-2,5),mouth+Vector2(4,5)],beak_color,1.8)
  # The unibrow is a tiny, occasional confused expression, never a permanent scowl.
  if fposmod(t+float(id.length()),7.2)>5.8:line([Vector2(-7,-6),Vector2(-2,-7)],shade,1.0)
  group=old

 func owl() -> void:
  if flying:flight_wing(true)
  tail()
  feet()
  ellipse(Vector2(0,-29+bob),Vector2(28,28),back,0,true)
  ellipse(Vector2(2,-21+bob),Vector2(20,20),breast)
  if flying and landing<.94:flight_wing(false)
  else:
   for side: float in [-1.0,1.0]:
    ellipse(Vector2(side*23,-23+bob),Vector2(7,16),wing,side*-.16,true)
    line([Vector2(side*24,-23+bob),Vector2(side*24,-13+bob)],bright,1.5)
  var old: Transform2D=group
  group=Transform2D(face_angle,Vector2(0,-38)+face_shift)
  # Bread-loaf face, two pale cheeks and comically far-apart dot eyes.
  ellipse(Vector2(-10,0),Vector2(14,15),breast)
  ellipse(Vector2(10,0),Vector2(14,15),breast)
  for side: float in [-1.0,1.0]:
   poly([Vector2(side*15,-12),Vector2(side*22,-23),Vector2(side*25,-12)],back,true)
   var eye: Vector2=Vector2(side*10,-1)
   if fposmod(t+1.0,6.0)>5.8:line([eye+Vector2(-3,0),eye+Vector2(3,0)],ink,1.8)
   else:ellipse(eye,Vector2(2.5,3),ink)
   curve(Vector2(side*17,-8),Vector2(side*11,-10),Vector2(side*6,-8),shade,1.6)
  poly([Vector2(-3,5),Vector2(4,5),Vector2(1,11)],beak,true)
  group=old
  for x: float in [-9.0,0.0,9.0]:curve(Vector2(x-2,-13+bob),Vector2(x,-10+bob),Vector2(x+2,-13+bob),bright.darkened(.2),1)

 func woodpecker() -> void:
  # Feet grip the bark at the origin; the body is a squat upright bean beside it.
  var peck: float=pow(maxf(0.0,sin(t*9.0)),4.0) if pose=="peck" else 0.0
  ellipse(Vector2(-17,-18),Vector2(18,24),back,-.12,true)
  ellipse(Vector2(-9,-15),Vector2(11,20),breast,-.12)
  ellipse(Vector2(-26,-18),Vector2(8,16),wing,.12,true)
  for y: float in [-27.0,-18.0,-9.0]:line([Vector2(-29,y),Vector2(-23,y+1)],breast,2)
  poly([Vector2(-24,0),Vector2(-30,15),Vector2(-17,8),Vector2(-14,0)],wing,true)
  for y: float in [-5.0,4.0]:
   line([Vector2(-9,y-3),Vector2(-3,y),Vector2(1,y-1)],shade,1.5)
   line([Vector2(-3,y),Vector2(0,y+3)],shade,1.2)
  var old: Transform2D=group
  group=Transform2D(face_angle+peck*.24,Vector2(-8+peck*4,-40+peck*3))
  ellipse(Vector2.ZERO,Vector2(17,15),breast,0,true)
  poly([Vector2(-14,-7),Vector2(-11,-17),Vector2(-5,-21),Vector2(-1,-16),Vector2(7,-15),Vector2(14,-7)],cap,true)
  var blink: bool=fposmod(t+.7,5.1)>4.9
  for x: float in [-3.0,8.0]:
   if blink:line([Vector2(x-2,0),Vector2(x+2,0)],ink,1.5)
   else:ellipse(Vector2(x,0),Vector2(2.1,2.4),ink)
  poly([Vector2(7,6),Vector2(21,6),Vector2(8,10)],beak,true)
  group=old

 func egret() -> void:
  var tucked: float=1.0-landing if flying else 0.0
  if flying:flight_wing(true)
  var leg: Color=Color("77866b")
  for n: int in range(2):
   var x: float=-6+float(n)*10
   if flying and reach<.6:
    line([Vector2(x,-33),Vector2(-24-float(n)*4,-21),Vector2(-45-float(n)*4,-19)],leg,1.8)
   else:
    line([Vector2(x,-31),Vector2(x+float(n)*2,-15),Vector2(x,0),Vector2(x+7,1)],leg,1.8)
  ellipse(Vector2(-3,-40),Vector2(22,16),back,.10,true)
  ellipse(Vector2(3,-36),Vector2(16,12),breast)
  poly([Vector2(-19,-42),Vector2(-32,-36),Vector2(-20,-32)],wing,true)
  if flying and landing<.94:flight_wing(false)
  else:ellipse(Vector2(-10,-42),Vector2(13,10),wing,.15,true)
  var neck_y: float=-83+tucked*31+sin(t*.8)*1.2*activity
  var head_x: float=12+sin(t*.6)*1.0*activity
  # A very long sock neck and small vacant face are this bird's whole joke.
  curve(Vector2(11,-39),Vector2(8,-60+tucked*13),Vector2(head_x,neck_y+9),shade,10)
  curve(Vector2(11,-39),Vector2(8,-60+tucked*13),Vector2(head_x,neck_y+9),back,7.4)
  var old: Transform2D=group
  group=Transform2D(face_angle*.8,Vector2(head_x,neck_y))
  ellipse(Vector2.ZERO,Vector2(14,12),back,0,true)
  ellipse(Vector2(-3,-5),Vector2(7,3),bright)
  curve(Vector2(-6,-11),Vector2(-8,-18),Vector2(-3,-16),wing,1.5)
  var blink: bool=fposmod(t+2.4,5.4)>5.2
  for x: float in [-4.0,6.0]:
   if blink:line([Vector2(x-1,0),Vector2(x+2,0)],ink,1.5)
   else:ellipse(Vector2(x,0),Vector2(1.8,2.2),ink)
  poly([Vector2(6,5),Vector2(28,7),Vector2(6,10)],beak,true)
  group=old
