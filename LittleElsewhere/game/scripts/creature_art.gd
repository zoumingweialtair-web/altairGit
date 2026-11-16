extends RefCounted
## Detailed, resolution-independent wildlife ink. Coordinates use one world pixel;
## the contact origin stays fixed while individual limbs, wings and fur move.
const IDS: Array[String] = ["squirrel","hedgehog","cat","bat","butterfly","luna_moth","jewel_beetle","fireflies","dragonfly","ladybug","stag_beetle"]

static func bounds(id: String, _flying: bool=false) -> Rect2:
 match id:
  "squirrel":return Rect2(-86,-96,133,103)
  "cat":return Rect2(-79,-75,137,81)
  "hedgehog":return Rect2(-45,-45,91,49)
  "bat":return Rect2(-75,-55,150,114)
  "luna_moth":return Rect2(-40,-40,80,96)
  "butterfly":return Rect2(-31,-28,62,58)
  "dragonfly":return Rect2(-42,-30,84,63)
  "fireflies":return Rect2(-47,-35,94,73)
  _:return Rect2(-25,-37,50,66)

static func bounds_for_actor(actor: Dictionary) -> Rect2:
 var id: String=str(actor.get("id",""))
 if id=="squirrel" and str(actor.get("pose",""))=="climb":
  var pull: float=clampf(float(actor.get("perch_blend",0)),0.0,1.0)
  var rect: Rect2=Rect2(-94,-40,128,157)
  rect=Rect2(rect.position.lerp(bounds(id).position,pull),rect.size.lerp(bounds(id).size,pull))
  var angle: float=lerp_angle(float(actor.get("route_angle",-PI/2))+PI/2,0,pull)
  return Transform2D(angle,Vector2.ZERO)*rect
 if id in ["jewel_beetle","ladybug","stag_beetle"]:
  return Transform2D(_beetle_rotation(actor),Vector2.ZERO)*bounds(id)
 return bounds(id,bool(actor.get("fly",false)))

static func _beetle_rotation(actor: Dictionary) -> float:
 var angle: float=float(actor.get("route_angle",-PI/2.0))+PI/2.0
 # A brief planted turn connects the upward crawl to the descending route.
 if str(actor.get("phase",""))=="exit":
  angle-=PI*(1.0-smoothstep(0.0,0.12,float(actor.get("phase_progress",1.0))))
 return angle

static func draw_creature(c: Node2D,a: Dictionary,context: Dictionary={}) -> void:
 var id: String=str(a.get("id","squirrel"))
 var ctx: Dictionary=context.duplicate()
 ctx["alpha"]=float(context.get("alpha",a.get("alpha",1.0)))
 var t: float=float(a.get("motion_age",0.0))
 var pos: Vector2=a.get("pos",Vector2.ZERO)
 var face: float=float(a.get("facing",1.0))
 var climbing: bool=id=="squirrel" and str(a.get("pose",""))=="climb"
 var rotation: float=float(a.get("body_tilt",0.0)) if bool(a.get("fly",false)) else 0.0
 if climbing:
  rotation=lerp_angle(float(a.get("route_angle",-PI/2.0))+PI/2.0,0.0,float(a.get("perch_blend",0.0)))
  face=float(a.get("support_side",1.0))
 elif id in ["jewel_beetle","ladybug","stag_beetle"]:
  rotation=_beetle_rotation(a)
  face=1.0
 c.draw_set_transform(pos,rotation,Vector2(face,1.0))
 match id:
  "squirrel":_squirrel(c,a,t,ctx,climbing)
  "cat":_cat(c,a,t,ctx)
  "hedgehog":_hedgehog(c,a,t,ctx)
  "bat":_bat(c,a,t,ctx)
  "butterfly","luna_moth":_lepidoptera(c,id,a,t,ctx)
  "dragonfly":_dragonfly(c,a,t,ctx)
  "fireflies":_fireflies(c,t,ctx)
  "jewel_beetle","ladybug","stag_beetle":_beetle(c,id,a,t,ctx)
 c.draw_set_transform(Vector2.ZERO)

static func _c(hex: String,ctx: Dictionary) -> Color:
 var value: Color=Color(hex)
 var lighting: Color=ctx.get("light",Color.WHITE)
 value*=lighting
 var tint: Color=ctx.get("tint",Color.WHITE)
 var strength: float=float(ctx.get("tint_strength",0.0))
 value=value.lerp(value*tint,clampf(strength,0.0,1.0))
 value.a*=float(ctx.get("alpha",1.0))
 return value

static func _ellipse(c: Node2D,center: Vector2,radius: Vector2,color: Color,edge: Color=Color.TRANSPARENT) -> void:
 var points: PackedVector2Array=[]
 for i: int in range(40):
  var angle: float=float(i)/40.0*TAU
  points.append((center+Vector2(cos(angle)*radius.x,sin(angle)*radius.y)).round())
 c.draw_colored_polygon(points,color)
 if edge.a>0.0:
  points.append(points[0])
  c.draw_polyline(points,edge,1.0,false)

static func _poly(c: Node2D,points: Array,color: Color,edge: Color=Color.TRANSPARENT) -> void:
 var shape: PackedVector2Array=[]
 for point: Vector2 in points:shape.append(point.round())
 if shape.size()==3 and absf((shape[1]-shape[0]).cross(shape[2]-shape[0]))<0.25:return
 c.draw_colored_polygon(shape,color)
 if edge.a>0.0:
  shape.append(shape[0])
  c.draw_polyline(shape,edge,1.0,false)

static func _line(c: Node2D,points: Array,color: Color,width: float=1.0) -> void:
 var shape: PackedVector2Array=[]
 for point: Vector2 in points:shape.append(point.round())
 c.draw_polyline(shape,color,width,false)

static func _curve(c: Node2D,start: Vector2,p1: Vector2,p2: Vector2,end: Vector2,color: Color,width: float=1.0) -> void:
 var points: PackedVector2Array=[]
 for i: int in range(21):points.append(start.bezier_interpolate(p1,p2,end,float(i)/20.0).round())
 c.draw_polyline(points,color,width,false)

static func _eye(c: Node2D,pos: Vector2,t: float,ctx: Dictionary,radius: float=2.6) -> void:
 var ink: Color=_c("263632",ctx)
 if fmod(t,6.3)>6.1:
  c.draw_line(pos-Vector2(radius,0),pos+Vector2(radius,0),ink,1.2,false)
 else:
  _ellipse(c,pos,Vector2(radius,radius*1.2),ink)
  c.draw_rect(Rect2(pos-Vector2(0.7,1.5),Vector2(1.3,1.3)),_c("fff6db",ctx))

static func _fur(c: Node2D,center: Vector2,rx: float,ry: float,color: Color,seed: int=0,count: int=26) -> void:
 for i: int in range(count):
  var angle: float=float(i)*2.39996+float(seed)
  var spread: float=sqrt(float(i+1)/float(count+1))
  var p: Vector2=center+Vector2(cos(angle)*rx,sin(angle)*ry)*spread
  c.draw_line(p.round(),(p+Vector2(-2.2+sin(angle)*1.4,2.2+cos(angle)*0.6)).round(),color,1.0,false)

static func _paw(c: Node2D,pos: Vector2,size: float,fur: Color,ink: Color) -> void:
 _ellipse(c,pos,Vector2(size,size*0.42),fur,ink)
 for i: int in range(3):
  var x: float=pos.x+float(i-1)*size*0.4
  c.draw_line(Vector2(x,pos.y),Vector2(x+1,pos.y+size*0.37),ink,1.0,false)

static func _squirrel_tail(c: Node2D,root: Vector2,t: float,ctx: Dictionary,climb_blend: float=0.0) -> void:
 var dark: Color=_c("735038",ctx)
 var base: Color=_c("aa7348",ctx)
 var gold: Color=_c("ce955d",ctx)
 var light: Color=_c("e2b57a",ctx)
 var bend: float=sin(t*1.15)*2.8
 var direction: float=lerpf(-1.0,1.0,climb_blend)
 var tip: Vector2=root+Vector2(-37+bend,66*direction)
 var centers: Array[Vector2]=[]
 var widths: Array[float]=[]
 for i: int in range(28):
  var f: float=float(i)/27.0
  centers.append(root.bezier_interpolate(root+Vector2(-35,-6*direction),root+Vector2(-60,40*direction),tip,f))
  widths.append(4.0+sin(f*PI)*16.0+sin(f*PI*0.5)*4.0)
 var left: Array=[]
 var right: Array=[]
 for i: int in range(centers.size()):
  var tangent: Vector2=centers[mini(i+1,27)]-centers[maxi(i-1,0)]
  var normal: Vector2=Vector2(-tangent.y,tangent.x).normalized()
  left.append(centers[i]+normal*widths[i])
  right.push_front(centers[i]-normal*widths[i])
 for i: int in range(27):
  var r0: Vector2=right[27-i]
  var r1: Vector2=right[26-i]
  _poly(c,[left[i],left[i+1],r0],base)
  _poly(c,[left[i+1],r1,r0],base)
 _line(c,left,dark)
 _line(c,right,dark)
 # Warmer center and narrow light-catching edge follow the actual tail curl.
 for i: int in range(4,26):
  _ellipse(c,centers[i]+Vector2(-4,0),Vector2(widths[i]*0.72,widths[i]*0.60),gold)
 _ellipse(c,tip,Vector2(7,7),base)
 for i: int in range(48):
  var f: float=0.08+float(i)/53.0
  var idx: int=clampi(int(f*27),1,26)
  var tangent: Vector2=(centers[idx+1]-centers[idx-1]).normalized()
  var normal: Vector2=Vector2(-tangent.y,tangent.x)
  var lateral: float=sin(float(i)*2.399)*widths[idx]*0.8
  var p: Vector2=centers[idx]+normal*lateral
  _line(c,[p-tangent*2,p+tangent*(3.0+float(i%3))],light if i%3==0 else (dark if i%5==0 else gold),1)
 for i: int in range(4,25,2):
  var tangent: Vector2=(centers[i+1]-centers[i-1]).normalized()
  var normal: Vector2=Vector2(-tangent.y,tangent.x)
  for side: float in [-1.0,1.0]:
   var p: Vector2=centers[i]+normal*widths[i]*side
   c.draw_line(p-tangent,p+normal*side*2.3+tangent*1.3,gold,1,false)

static func _squirrel(c: Node2D,a: Dictionary,t: float,ctx: Dictionary,climb: bool) -> void:
 var ink: Color=_c("5e4939",ctx)
 var shadow: Color=_c("8b5d3e",ctx)
 var fur: Color=_c("bb8552",ctx)
 var light: Color=_c("dfa86b",ctx)
 var cream: Color=_c("ecd2a0",ctx)
 var skin: Color=_c("cf9974",ctx)
 if climb:
  var pull: float=clampf(float(a.get("perch_blend",0.0)),0.0,1.0)
  if pull>=0.999:
   _squirrel(c,a,t,ctx,false)
   return
  _squirrel_tail(c,Vector2(-19,31).lerp(Vector2(-12,-7),pull),t,ctx,1.0-pull)
  # The torso and both pairs of paws pull over the bough while contact stays fixed.
  var gait: float=sin(float(a.get("gait_phase",t*7.0/TAU))*TAU)*(1.0-pull)
  var hip: Vector2=Vector2(-19,21).lerp(Vector2(-7,-8),pull)
  var hind: Vector2=Vector2(0,31+gait*3).lerp(Vector2(-10,-2),pull)
  _line(c,[hip,Vector2(-7,32).lerp(Vector2(-9,-5),pull),hind],shadow,7)
  _paw(c,hind,4,fur,ink)
  var far_hand: Vector2=Vector2(0,-4-gait*3).lerp(Vector2(26,-23),pull)
  _line(c,[Vector2(-12,8).lerp(Vector2(7,-29),pull),Vector2(-5,-2).lerp(Vector2(19,-26),pull),far_hand],shadow,6)
  _paw(c,far_hand,3.7,light,ink)
  var torso: Vector2=Vector2(-19,17).lerp(Vector2(-5,-17),pull)
  _ellipse(c,torso,Vector2(lerpf(15,19,pull),lerpf(25,22,pull)),fur,ink)
  _ellipse(c,Vector2(-11,16).lerp(Vector2(6,-21),pull),Vector2(lerpf(7,10,pull),lerpf(20,17,pull)),cream)
  _fur(c,Vector2(-21,15).lerp(Vector2(-13,-20),pull),10,21,light,2,23)
  var near_hind: Vector2=Vector2(2,36-gait*3).lerp(Vector2(1,-1),pull)
  _line(c,[Vector2(-22,32).lerp(Vector2(-6,-9),pull),Vector2(-10,42).lerp(Vector2(-3,-5),pull),near_hind],ink,7)
  _line(c,[Vector2(-22,31).lerp(Vector2(-6,-10),pull),Vector2(-10,41).lerp(Vector2(-3,-6),pull),near_hind-Vector2(0,1)],fur,5)
  _paw(c,near_hind,lerpf(4.5,9.0,pull),light,ink)
  var hand: Vector2=Vector2(2,1+gait*3).lerp(Vector2(18,-24),pull)
  _line(c,[Vector2(-17,4).lerp(Vector2(6,-29),pull),Vector2(-9,9).lerp(Vector2(12,-24),pull),hand],ink,6)
  _line(c,[Vector2(-17,3).lerp(Vector2(6,-30),pull),Vector2(-9,8).lerp(Vector2(12,-25),pull),hand-Vector2(0,1)],light,4)
  _paw(c,hand,4,light,ink)
  _squirrel_head(c,Vector2(-15,-10).lerp(Vector2(10,-41),pull),t,ctx,-0.1)
  if pull>0.7:
   var nut: Color=_c("b88f57",ctx)
   nut.a*=inverse_lerp(0.7,1.0,pull)
   _ellipse(c,Vector2(21,-23),Vector2(6,7),nut)
 else:
  _squirrel_tail(c,Vector2(-12,-7),t,ctx)
  _ellipse(c,Vector2(-5,-17),Vector2(19,22),fur,ink)
  _ellipse(c,Vector2(-8,-24),Vector2(14,20),light)
  _ellipse(c,Vector2(6,-21),Vector2(10,17),cream)
  _fur(c,Vector2(-13,-20),11,17,shadow,3,24)
  _fur(c,Vector2(2,-30),9,12,_c("f1bd7b",ctx),1,18)
  _ellipse(c,Vector2(-7,-8),Vector2(12,9),shadow)
  _ellipse(c,Vector2(-5,-10),Vector2(11,8),fur)
  _paw(c,Vector2(1,-1),10,light,ink)
  _paw(c,Vector2(-10,-2),7,fur,ink)
  var nibble: float=sin(t*8.5)*0.6 if str(a.get("pose","")) in ["nibble","eat"] else 0.0
  var head_shift: Vector2=Vector2(sin(t*0.45)*0.8,nibble)
  _squirrel_head(c,Vector2(10,-41)+head_shift,t,ctx,0)
  # A held hazelnut has a lit shell and a rough cap, enclosed by two tiny hands.
  _ellipse(c,Vector2(21,-23+nibble),Vector2(6.5,7),_c("a47744",ctx),ink)
  _ellipse(c,Vector2(23,-25+nibble),Vector2(3.7,4.5),_c("d7ad6a",ctx))
  _line(c,[Vector2(16,-28+nibble),Vector2(21,-30+nibble),Vector2(26,-27+nibble)],_c("78613c",ctx),3)
  _line(c,[Vector2(6,-29),Vector2(12,-24),Vector2(18,-24+nibble)],ink,5)
  _line(c,[Vector2(6,-30),Vector2(12,-25),Vector2(18,-25+nibble)],light,3)
  _paw(c,Vector2(18,-24+nibble),3.2,skin,ink)
  _paw(c,Vector2(26,-23+nibble),2.8,light,ink)

static func _squirrel_head(c: Node2D,center: Vector2,t: float,ctx: Dictionary,_tilt: float) -> void:
 var ink: Color=_c("5e4939",ctx)
 var fur: Color=_c("c48c57",ctx)
 var light: Color=_c("e6b67c",ctx)
 _poly(c,[center+Vector2(-10,-7),center+Vector2(-8,-23),center+Vector2(-3,-19),center+Vector2(0,-9)],fur,ink)
 _poly(c,[center+Vector2(-7,-13),center+Vector2(-7,-20),center+Vector2(-4,-16)],_c("dfbb97",ctx))
 _line(c,[center+Vector2(-8,-22),center+Vector2(-10,-27)],ink)
 _line(c,[center+Vector2(-6,-22),center+Vector2(-5,-27)],fur)
 _ellipse(c,center,Vector2(13,12),fur,ink)
 _ellipse(c,center+Vector2(5,4),Vector2(12,7),light)
 _ellipse(c,center+Vector2(13,3),Vector2(7,4.5),_c("efcca0",ctx))
 _ellipse(c,center+Vector2(18,1),Vector2(2.5,2),ink)
 _eye(c,center+Vector2(6,-3),t,ctx,2.8)
 _line(c,[center+Vector2(15,6),center+Vector2(10,7),center+Vector2(8,5)],ink,1)
 for i: int in range(3):
  _line(c,[center+Vector2(11,4),center+Vector2(23,2+i*4)],_c("886b53",ctx),0.8)
 _fur(c,center+Vector2(-5,-2),6,8,light,8,14)

static func _cat(c: Node2D,a: Dictionary,t: float,ctx: Dictionary) -> void:
 var ink: Color=_c("5b5548",ctx)
 var shadow: Color=_c("9e8765",ctx)
 var fur: Color=_c("bea17a",ctx)
 var light: Color=_c("dfc69a",ctx)
 var cream: Color=_c("eee0bb",ctx)
 var travelling: bool=str(a.get("phase","idle"))!="idle" or str(a.get("pose","sit")) in ["walk","arrive","depart"]
 var rest: float=clampf(float(a.get("perch_blend",a.get("land_blend",0.0))),0.0,1.0) if travelling else 1.0
 var stride: float=float(a.get("gait_phase",t*6.5/TAU))*TAU
 var tail_root: Vector2=Vector2(-28,-23).lerp(Vector2(-11,-8),rest)
 var tail_tip: Vector2=Vector2(-61,-48+sin(t)*3).lerp(Vector2(-60,-5+sin(t*1.1)*2),rest)
 var tail_p1: Vector2=Vector2(-53,-23).lerp(Vector2(-46,-4),rest)
 var tail_p2: Vector2=Vector2(-58,-41+sin(t)*3).lerp(Vector2(-53,1),rest)
 _curve(c,tail_root,tail_p1,tail_p2,tail_tip,ink,lerpf(7,10,rest))
 _curve(c,tail_root,tail_p1,tail_p2,tail_tip,fur,lerpf(5,8,rest))
 _ellipse(c,tail_tip,Vector2(2.8,2.8),fur)
 for rear: bool in [true,false]:
  for x: float in [-20.0,20.0]:
   var phase: float=stride+(PI if x<0 else 0.0)+(PI if rear else 0.0)
   var lift: float=maxf(0.0,sin(phase))*4.0*(1.0-rest)
   var step: float=cos(phase)*7.0*(1.0-rest)
   var hip: Vector2=Vector2(x,-19).lerp(Vector2(-10,-13) if x<0 else Vector2(8,-27),rest)
   var knee: Vector2=Vector2(x-step*0.55,-10-lift*0.4).lerp(Vector2(-13,-6) if x<0 else Vector2(10,-10),rest)
   var toe: Vector2=Vector2(x+step,-2-lift).lerp(Vector2(-7,-2) if x<0 else Vector2(12,-2),rest)
   var coat: Color=shadow if rear else fur
   _line(c,[hip,knee,toe],ink,lerpf(6,8,rest))
   _line(c,[hip,knee,toe],coat,lerpf(4,6,rest))
   _paw(c,toe+Vector2(3,0),lerpf(4.2,7.0 if x>0 else 11.0,rest),cream if not rear and x>0 else coat,ink)
  if rear:
   _ellipse(c,Vector2(-2,-24).lerp(Vector2(0,-21),rest),Vector2(lerpf(31,21,rest),lerpf(15,26,rest)),fur,ink)
   _ellipse(c,Vector2(-3,-31).lerp(Vector2(-8,-30),rest),Vector2(lerpf(27,11,rest),lerpf(7,16,rest)),light)
   _ellipse(c,Vector2(-6,-17).lerp(Vector2(9,-24),rest),Vector2(lerpf(23,12,rest),lerpf(6,20,rest)),cream)
   _fur(c,Vector2(-7,-26).lerp(Vector2(-8,-29),rest),lerpf(23,12,rest),lerpf(9,20,rest),shadow,5,27)
 var groom: bool=rest>0.99 and str(a.get("pose",""))=="groom"
 if groom:
  _line(c,[Vector2(-1,-31),Vector2(10,-34),Vector2(18,-37)],fur,5)
  _paw(c,Vector2(18,-37),4,cream,ink)
 var head: Vector2=Vector2(29,-31+sin(stride*2)*0.5).lerp(Vector2(4,-48),rest)
 if groom:head+=Vector2(2,3)
 _cat_head(c,head,t,ctx)

static func _cat_head(c: Node2D,p: Vector2,t: float,ctx: Dictionary) -> void:
 var ink: Color=_c("5b5548",ctx)
 var fur: Color=_c("c0a17a",ctx)
 var light: Color=_c("e4cd9f",ctx)
 _poly(c,[p+Vector2(-12,-6),p+Vector2(-13,-22),p+Vector2(-2,-12),p+Vector2(8,-15),p+Vector2(17,-20),p+Vector2(17,-4)],fur,ink)
 _poly(c,[p+Vector2(-10,-9),p+Vector2(-11,-18),p+Vector2(-4,-12)],_c("c79584",ctx))
 _poly(c,[p+Vector2(10,-12),p+Vector2(15,-16),p+Vector2(14,-7)],_c("c79584",ctx))
 _ellipse(c,p,Vector2(16,13),fur,ink)
 _ellipse(c,p+Vector2(1,-3),Vector2(13,8),light)
 _ellipse(c,p+Vector2(9,5),Vector2(10,7),_c("eee0bb",ctx))
 _ellipse(c,p+Vector2(-2,6),Vector2(8,6),_c("e6d7b1",ctx))
 for x: float in [-4.0,9.0]:
  _ellipse(c,p+Vector2(x,-2),Vector2(3.2,3.8),_c("a1ac78",ctx),ink)
  if fmod(t,5.7)>5.5:c.draw_line(p+Vector2(x-3,-2),p+Vector2(x+3,-2),ink,2)
  else:
   c.draw_line(p+Vector2(x,-5),p+Vector2(x,1),ink,1.4)
   c.draw_rect(Rect2(p+Vector2(x-1,-4),Vector2(1.4,1.4)),_c("fff7dc",ctx))
 _poly(c,[p+Vector2(5,3),p+Vector2(9,3),p+Vector2(7,6)],_c("a67a70",ctx))
 _line(c,[p+Vector2(7,6),p+Vector2(7,9),p+Vector2(3,10)],ink)
 _line(c,[p+Vector2(7,9),p+Vector2(10,10)],ink)
 for side: float in [-1.0,1.0]:
  for i: int in range(3):
   _line(c,[p+Vector2(5+side*5,7),p+Vector2(6+side*22,3+i*4)],_c("837f6c",ctx))
 _line(c,[p+Vector2(-6,-12),p+Vector2(-3,-8),p+Vector2(-1,-13)],_c("93805f",ctx),2)
 _line(c,[p+Vector2(3,-13),p+Vector2(5,-8),p+Vector2(8,-13)],_c("93805f",ctx),2)

static func _hedgehog(c: Node2D,a: Dictionary,t: float,ctx: Dictionary) -> void:
 var ink: Color=_c("555448",ctx)
 var dark: Color=_c("756e57",ctx)
 var coat: Color=_c("9d9270",ctx)
 var light: Color=_c("d2c5a0",ctx)
 var moving: bool=str(a.get("phase","idle"))!="idle"
 for x: float in [-20.0,14.0]:
  var phase: float=(float(a.get("gait_phase",t*5.0/TAU))*TAU+(PI if x<0 else 0)) if moving else 0.0
  _line(c,[Vector2(x,-9),Vector2(x+sin(phase)*2,-3),Vector2(x+4,-1)],dark,4)
 _ellipse(c,Vector2(-7,-17),Vector2(29,19),coat,ink)
 _poly(c,[Vector2(-30,-7),Vector2(-29,-24),Vector2(-14,-34),Vector2(9,-29),Vector2(22,-11),Vector2(14,-5)],coat,ink)
 for i: int in range(93):
  var angle: float=float(i)*2.399
  var distance: float=sqrt(float(i+1)/94.0)
  var pos: Vector2=Vector2(-9,-19)+Vector2(cos(angle)*25,sin(angle)*15)*distance
  if pos.x>8.0 and pos.y>-15:continue
  var tip: Vector2=pos+Vector2(-3.5+cos(angle)*1.7,-5.5+sin(angle)*1.2)
  _line(c,[pos,tip],dark if i%3 else ink,1)
  _line(c,[pos+Vector2(-1,-1),tip+Vector2(1,0)],light,1)
 var sniff: float=sin(t*3.1)*(0.7 if not moving else 0.2)
 _poly(c,[Vector2(12,-22),Vector2(23,-20),Vector2(31,-14+sniff),Vector2(40,-11+sniff),Vector2(35,-6),Vector2(17,-6),Vector2(9,-12)],_c("c9b695",ctx),ink)
 _ellipse(c,Vector2(17,-21),Vector2(5,6),_c("b7a07e",ctx),ink)
 _ellipse(c,Vector2(18,-21),Vector2(2,3),_c("d8b5a2",ctx))
 _eye(c,Vector2(27,-15),t,ctx,2.1)
 _ellipse(c,Vector2(39,-11+sniff),Vector2(3,2.2),ink)
 _line(c,[Vector2(31,-7),Vector2(36,-7)],dark)

static func _bat(c: Node2D,a: Dictionary,t: float,ctx: Dictionary) -> void:
 var ink: Color=_c("494b58",ctx)
 var membrane: Color=_c("858092",ctx)
 var light: Color=_c("aea2b0",ctx)
 var wing: float=sin(t*13.2)
 var folding: float=(1.0-wing)*0.5
 var reach: float=58.0-folding*17.0
 var tip_y: float=-9.0-wing*31.0
 for side: float in [-1.0,1.0]:
  var shoulder: Vector2=Vector2(side*7,-9)
  var elbow: Vector2=Vector2(side*27,-18-wing*11)
  var tip: Vector2=Vector2(side*reach,tip_y)
  var finger1: Vector2=Vector2(side*(reach-11),tip_y+27)
  var finger2: Vector2=Vector2(side*28,25+wing*5)
  var root: Vector2=Vector2(side*6,13)
  _poly(c,[shoulder,elbow,tip],membrane,ink)
  _poly(c,[elbow,tip,finger1],membrane,ink)
  _poly(c,[elbow,finger1,finger2],membrane,ink)
  _poly(c,[elbow,finger2,root],membrane,ink)
  _poly(c,[elbow,root,shoulder],membrane,ink)
  _poly(c,[shoulder,elbow,tip,Vector2(side*39,tip_y+8)],light)
  for finger: Vector2 in [tip,finger1,finger2,root]:_line(c,[elbow,finger],ink,1)
  _line(c,[shoulder,elbow,tip],_c("c2b5ba",ctx),1)
 _ellipse(c,Vector2(0,4),Vector2(9,16),_c("746c72",ctx),ink)
 _ellipse(c,Vector2(1,5),Vector2(5,12),_c("a39692",ctx))
 _poly(c,[Vector2(-7,-10),Vector2(-9,-27),Vector2(-1,-19),Vector2(5,-21),Vector2(10,-27),Vector2(8,-7)],_c("8a7f85",ctx),ink)
 _ellipse(c,Vector2(0,-9),Vector2(10,9),_c("998b8b",ctx),ink)
 _ellipse(c,Vector2(0,-4),Vector2(6,4),_c("b9a6a0",ctx))
 for x: float in [-4.0,4.0]:_eye(c,Vector2(x,-10),t,ctx,1.7)
 _ellipse(c,Vector2(0,-5),Vector2(2,1.4),ink)
 _fur(c,Vector2(0,6),5,10,_c("c4b7a5",ctx),4,16)
 _line(c,[Vector2(-4,17),Vector2(-5,21),Vector2(-8,22)],ink)
 _line(c,[Vector2(4,17),Vector2(5,21),Vector2(8,22)],ink)


static func _wing_points(points: Array,side: float,spread: float,vertical: float=1.0) -> Array:
 var output: Array=[]
 for p: Vector2 in points:output.append(Vector2(p.x*side*spread,p.y*vertical))
 return output

static func _lepidoptera(c: Node2D,id: String,a: Dictionary,t: float,ctx: Dictionary) -> void:
 var luna: bool=id=="luna_moth"
 var ink: Color=_c("678274" if luna else "736f59",ctx)
 var edge: Color=_c("9c8580" if luna else "7a7d6a",ctx)
 var base: Color=_c("c6d8a6" if luna else "ece8ca",ctx)
 var light: Color=_c("e6e9ba" if luna else "fff8df",ctx)
 var shadow: Color=_c("a3bd8c" if luna else "d3d7b5",ctx)
 var stroke: float=sin(t*(8.5 if luna else 13.4))
 var spread: float=0.20+0.80*pow(absf(stroke),0.65)
 if str(a.get("pose","")) in ["rest","perch"]:spread=0.70+sin(t*1.4)*0.12
 var size_value: float=1.18 if luna else 0.94
 for side: float in [-1.0,1.0]:
  var fore: Array=[Vector2(2,-5),Vector2(6,-14),Vector2(21,-28),Vector2(28,-29),Vector2(31,-22),Vector2(28,-11),Vector2(23,-4),Vector2(11,2),Vector2(3,5)]
  var hind: Array=[Vector2(3,1),Vector2(12,-1),Vector2(23,4),Vector2(24,12),Vector2(20,19),Vector2(14,23),Vector2(8,20),Vector2(2,9)]
  if luna:
   fore=[Vector2(2,-6),Vector2(14,-21),Vector2(29,-30),Vector2(31,-23),Vector2(30,-14),Vector2(26,-7),Vector2(15,1),Vector2(3,7)]
   hind=[Vector2(2,3),Vector2(12,-1),Vector2(24,5),Vector2(26,12),Vector2(19,19),Vector2(15,23),Vector2(16,31),Vector2(21,40),Vector2(19,42),Vector2(12,35),Vector2(9,23),Vector2(3,15)]
  _poly(c,_wing_points(hind,side,spread*size_value,size_value),shadow,ink)
  _poly(c,_wing_points(fore,side,spread*size_value,size_value),base,edge)
  _poly(c,_wing_points([Vector2(4,-6),Vector2(15,-19),Vector2(26,-25),Vector2(25,-17),Vector2(16,-5)],side,spread*size_value,size_value),light)
  for tip: Vector2 in [Vector2(27,-25),Vector2(28,-16),Vector2(23,-6),Vector2(19,13),Vector2(12,19)]:
   var start: Vector2=Vector2(3,3 if tip.y>0 else -2)
   _line(c,_wing_points([start,start.lerp(tip,0.55)+Vector2(2,-1),tip],side,spread*size_value,size_value),shadow,1)
  if luna:
   for spot: Vector2 in [Vector2(17,-10),Vector2(15,10)]:
    var center: Vector2=Vector2(spot.x*side*spread*size_value,spot.y*size_value)
    _ellipse(c,center,Vector2(4.2*spread,4.2),_c("b7a879",ctx),ink)
    _ellipse(c,center,Vector2(2.6*spread,2.8),_c("e8e3b4",ctx))
    c.draw_line(center-Vector2(1.4*side*spread,1),center+Vector2(1.4*side*spread,2),_c("748778",ctx),1)
   _line(c,_wing_points([Vector2(5,-9),Vector2(15,-22),Vector2(28,-29)],side,spread*size_value,size_value),_c("a98a85",ctx),2)
  else:
   _poly(c,_wing_points([Vector2(20,-27),Vector2(28,-29),Vector2(31,-22),Vector2(28,-13),Vector2(25,-15),Vector2(27,-22)],side,spread*size_value,size_value),_c("777a63",ctx))
   _ellipse(c,Vector2(side*spread*18,-8),Vector2(2.4*spread,2.8),_c("929174",ctx))
   _ellipse(c,Vector2(side*spread*15,11),Vector2(1.8*spread,2.1),_c("c5b578",ctx))
 _ellipse(c,Vector2(0,7),Vector2(2.7,11),_c("b5ae81" if luna else "a6a171",ctx),ink)
 for y: int in range(2,16,3):c.draw_line(Vector2(-2,y),Vector2(2,y),shadow,1)
 _ellipse(c,Vector2(0,-5),Vector2(3.7,5.2),_c("d1cea4" if luna else "c9c6a1",ctx),ink)
 _ellipse(c,Vector2(0,-10),Vector2(3,3),_c("d6d4ad",ctx),ink)
 for side: float in [-1.0,1.0]:
  _eye(c,Vector2(side*2.5,-10),t,ctx,0.9)
  var tip: Vector2=Vector2(side*(8+sin(t*1.6)), -19)
  _curve(c,Vector2(side,-12),Vector2(side*3,-16),Vector2(side*6,-19),tip,ink,1)
  if luna:
   for i: int in range(4):
    var p: Vector2=Vector2(side*(3+i),-14-i)
    c.draw_line(p,p+Vector2(side*3,-1),shadow,1)
  else:_ellipse(c,tip,Vector2(1.2,1.8),ink)

static func _beetle(c: Node2D,id: String,a: Dictionary,t: float,ctx: Dictionary) -> void:
 var ink: Color=_c("354b45",ctx)
 var lady: bool=id=="ladybug"
 var stag: bool=id=="stag_beetle"
 var base: Color=_c("c57558" if lady else ("8e8059" if stag else "398976"),ctx)
 var light: Color=_c("edaa73" if lady else ("c1af7b" if stag else "87c7a1"),ctx)
 var shadow: Color=_c("9d5947" if lady else ("685e46" if stag else "28685e"),ctx)
 var width: float=10.0 if lady else 9.0
 var length: float=11.0 if lady else 15.0
 var moving: bool=str(a.get("pose","")) in ["climb","crawl","walk"]
 var speed: float=7.0 if moving else 1.4
 # Tripod gait: alternating legs reach forward, remain planted, then recover.
 for side: float in [-1.0,1.0]:
  for i: int in range(3):
   var y: float=-6.0+i*7.0
   var phase: float=float(a.get("gait_phase",t*speed/TAU))*TAU+i*PI+(PI if side<0 else 0)
   var lift: float=sin(phase)*2.4
   var root: Vector2=Vector2(side*7,y)
   var knee: Vector2=Vector2(side*(14+absf(lift)),y-2+lift)
   var toe: Vector2=Vector2(side*(18+absf(lift)*0.3),y+3+lift)
   _line(c,[root,knee,toe],ink,1.6)
   _line(c,[knee+Vector2(side,0),toe],_c("8b9c7b",ctx),1)
   _line(c,[toe,toe+Vector2(side*2,-2)],ink)
 _ellipse(c,Vector2(0,2),Vector2(width+1,length+1),shadow,ink)
 _ellipse(c,Vector2(-2,0),Vector2(width-1,length),base)
 _ellipse(c,Vector2(-4,-3),Vector2(width*0.42,length*0.73),light)
 _ellipse(c,Vector2(-4,-7),Vector2(2,3),_c("f1d1a1" if lady else ("d4c797" if stag else "c1dfb6"),ctx))
 c.draw_line(Vector2(0,-11),Vector2(0,length+1),ink,1.0)
 c.draw_line(Vector2(1,-9),Vector2(1,length-2),light,1)
 if lady:
  for spot: Vector2 in [Vector2(-5,-5),Vector2(5,-5),Vector2(-6,3),Vector2(6,3),Vector2(-3,9),Vector2(3,9)]:
   _ellipse(c,spot,Vector2(2,2.6),_c("3e4d42",ctx))
 else:
  for side: float in [-1.0,1.0]:
   for x: float in [3.0,5.5,7.0]:
    _curve(c,Vector2(side*x,-8),Vector2(side*(x+1),-1),Vector2(side*x,8),Vector2(side*(x-1),12),shadow,1)
 _ellipse(c,Vector2(0,-11),Vector2(7.5,5.0),_c("344c43" if lady else ("756b4e" if stag else "467e6b"),ctx),ink)
 if lady:
  for side: float in [-1.0,1.0]:_ellipse(c,Vector2(side*4.5,-12),Vector2(2,2),_c("e7dfbd",ctx))
 else:_ellipse(c,Vector2(-2,-13),Vector2(4,2),light)
 _ellipse(c,Vector2(0,-17),Vector2(5,4.5),_c("535d45" if stag else "365c4d",ctx),ink)
 for side: float in [-1.0,1.0]:
  _eye(c,Vector2(side*4,-18),t,ctx,1.1)
  var wave: float=sin(t*2.2)*1.5
  _line(c,[Vector2(side*3,-19),Vector2(side*7,-23-wave),Vector2(side*10,-22-wave)],ink)
  if stag:
   _poly(c,[Vector2(side*2,-19),Vector2(side*7,-24),Vector2(side*8,-31),Vector2(side*5,-35),Vector2(side*5,-28),Vector2(side*2,-25)],base,ink)
   _line(c,[Vector2(side*6,-28),Vector2(side*2,-30)],light,1)

static func _dragonfly(c: Node2D,_a: Dictionary,t: float,ctx: Dictionary) -> void:
 var ink: Color=_c("42676a",ctx)
 var jade: Color=_c("74a99f",ctx)
 var pale: Color=_c("c6dcd1",ctx)
 var stroke: float=sin(t*34.0)
 var spread: float=0.63+0.37*absf(stroke)
 for side: float in [-1.0,1.0]:
  for pair: int in range(2):
   var y: float=-7.0+pair*8.0
   var tip: Vector2=Vector2(side*36*spread,y-13.0+pair*22+stroke*2)
   var points: Array=[Vector2(side*2,y),Vector2(side*12,y-6),tip,tip+Vector2(-side*3,5),Vector2(side*13,y+5),Vector2(side*3,y+3)]
   var membrane: Color=pale
   membrane.a*=0.60
   _poly(c,points,membrane,_c("8caea6",ctx))
   _line(c,[Vector2(side*3,y),tip],_c("86ada7",ctx),1)
   _line(c,[Vector2(side*5,y+2),tip+Vector2(-side*5,3)],_c("b2cdc4",ctx),1)
   for i: int in range(3):
    var f: float=0.30+i*0.18
    var p: Vector2=Vector2(side*3,y).lerp(tip,f)
    c.draw_line(p,p+Vector2(side*2,3),_c("94b7ad",ctx),1)
 _ellipse(c,Vector2(0,1),Vector2(3.2,6),jade,ink)
 for i: int in range(8):
  var y: float=7+i*3.0
  _ellipse(c,Vector2(sin(t*1.1+i*0.2)*0.5,y),Vector2(2.5-i*0.18,2.2),jade if i%2 else _c("4f8c91",ctx),ink)
  c.draw_line(Vector2(-1,y-1),Vector2(1,y-1),pale,1)
 for side: float in [-1.0,1.0]:
  _line(c,[Vector2(side*2,-3),Vector2(side*7,1),Vector2(side*5,5)],ink)
  _ellipse(c,Vector2(side*3.5,-10),Vector2(4,4.6),_c("79aaa2",ctx),ink)
  _ellipse(c,Vector2(side*4,-11),Vector2(2,2.4),_c("b9d0b6",ctx))
  c.draw_rect(Rect2(Vector2(side*4,-13),Vector2(1,1)),_c("e1e9ca",ctx))
 _ellipse(c,Vector2(0,-7),Vector2(2.5,3),_c("578d83",ctx))

static func _fireflies(c: Node2D,t: float,ctx: Dictionary) -> void:
 var ink: Color=_c("425a47",ctx)
 for i: int in range(6):
  var phase: float=float(i)*2.399
  var pos: Vector2=Vector2(cos(phase)*float(15+i*5),sin(phase)*float(10+i*3))
  pos+=Vector2(sin(t*0.6+phase)*4,cos(t*0.5+phase)*3)
  var glow: float=0.15+pow((sin(t*1.4+phase)+1)*0.5,2.0)*0.85
  var glow_color: Color=Color(0.76,0.87,0.44,glow*0.10*float(ctx.get("alpha",1.0)))
  _ellipse(c,pos+Vector2(0,4),Vector2(8,8),glow_color)
  _ellipse(c,pos+Vector2(0,4),Vector2(5,5),Color(0.82,0.93,0.55,glow*0.18*float(ctx.get("alpha",1.0))))
  var wing: float=3.0+absf(sin(t*22+phase))*4
  _poly(c,[pos+Vector2(-1,-2),pos+Vector2(-wing,-5),pos+Vector2(-wing-1,0),pos+Vector2(-1,3)],_c("bbc9a0",ctx),_c("94ad81",ctx))
  _poly(c,[pos+Vector2(1,-2),pos+Vector2(wing,-5),pos+Vector2(wing+1,0),pos+Vector2(1,3)],_c("bbc9a0",ctx),_c("94ad81",ctx))
  _ellipse(c,pos+Vector2(0,2),Vector2(2.2,5),_c("748259",ctx),ink)
  _ellipse(c,pos+Vector2(0,5),Vector2(2.0,2.4),_c("e5e6a1",ctx).lerp(Color(0.95,1,0.62,float(ctx.get("alpha",1.0))),glow))
  c.draw_line(pos+Vector2(-2,2),pos+Vector2(2,2),ink,1)
  _ellipse(c,pos+Vector2(0,-3),Vector2(2.5,2.5),_c("b69b66",ctx),ink)
  for side: float in [-1.0,1.0]:
   _line(c,[pos+Vector2(side,-4),pos+Vector2(side*3,-7)],ink)
   for y: float in [-1.0,1.0,3.0]:_line(c,[pos+Vector2(side,y),pos+Vector2(side*4,y+2)],ink)
