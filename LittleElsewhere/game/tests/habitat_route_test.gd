extends SceneTree
const Motion=preload("res://scripts/visitor_motion.gd")
const Habitat=preload("res://scripts/habitat_paths.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:
 run.call_deferred()
func check(ok: bool, message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error("HABITAT_FAIL "+message)
func run() -> void:
 var image: Image=(load("res://assets/art/layers_v1/tree.png") as Texture2D).get_image()
 for id: String in ["squirrel","jewel_beetle","stag_beetle"]:
  var path: PackedVector2Array=Habitat.crawl_path(id)
  var on_bark: int=0
  var exposed_samples: int=0
  for frame: int in range(241):
   var sample: Dictionary=Habitat.sample_path(path,float(frame)/240.0)
   var point: Vector2=sample.position
   # Travel behind pots and flowers is covered by the rendered occlusion test.
   if point.y>588.0:continue
   exposed_samples+=1
   var px: Vector2i=Vector2i(point*Vector2(image.get_size())/Vector2(1440,810))
   var color: Color=image.get_pixel(px.x,px.y)
   if color.a>0.8 and color.r>color.g*1.10 and color.r>color.b*1.25:on_bark+=1
  check(exposed_samples>100,id+" has enough exposed contact samples: "+str(exposed_samples))
  check(float(on_bark)/maxf(1.0,float(exposed_samples))>=0.95,id+" contacts actual opaque brown bark along visible route: "+str(on_bark)+"/"+str(exposed_samples))
  check(Habitat.is_hidden(id,path[0]),id+" emerges from existing occluding foliage")
  check((Habitat.sample_path(path,1.0).position as Vector2).distance_to(Habitat.anchor(id))<0.01,id+" ends on traced anchor")
 for id: String in Motion.IDS:
  var actor: Dictionary=Motion.spawn(id,Habitat.anchor(id),0)
  var previous: Vector2=actor.pos
  var phases: Array[String]=[]
  var continuous: bool=true
  var finite: bool=true
  var opaque: bool=true
  for frame: int in range(int(actor.duration*60)+2):
   if Motion.advance(actor,1.0/60.0,0,1.0):break
   if not phases.has(str(actor.phase)):phases.append(str(actor.phase))
   finite=finite and (actor.pos as Vector2).is_finite()
   continuous=continuous and previous.distance_to(actor.pos)<16.0
   previous=actor.pos
   opaque=opaque and is_equal_approx(float(actor.alpha),1.0)
  check(phases==["entry","idle","exit"],id+" complete phase order")
  check(finite and continuous,id+" continuous support/flight path")
  check(opaque,id+" physical occlusion rather than fading")
  check(Habitat.is_hidden(id,actor.pos) if id in Motion.CRAWLERS else not Rect2(-80,-110,1600,980).has_point(actor.pos),id+" exits to hidden habitat or beyond view")
 var bird: Dictionary=Motion.spawn("sparrow",Habitat.anchor("sparrow"),0)
 var modes: Array[String]=[]
 while float(bird.age)<float(bird.entry_duration):
  Motion.advance(bird,1.0/60.0,0,1.0)
  if not modes.has(str(bird.flight_mode)):modes.append(str(bird.flight_mode))
 check("flap" in modes and "brake" in modes and "land" in modes,"bird has real flight, braking and landing substates")
 check((bird.pos as Vector2).distance_to(Habitat.anchor("sparrow"))<0.1,"bird feet land on branch surface")
 var squirrel: Dictionary=Motion.spawn("squirrel",Habitat.anchor("squirrel"),0)
 Motion.advance(squirrel,3.0,0,1.0)
 var previous: Vector2=squirrel.pos
 Motion.request_departure(squirrel)
 Motion.advance(squirrel,1.0/60.0,0,1.0)
 check((squirrel.pos as Vector2).distance_to(previous)<1.0,"interrupted climb reverses from actual paw contact")
 check(str(squirrel.support)=="bark" and not bool(squirrel.fly),"squirrel stays attached to bark while leaving")
 var landed: Dictionary=Motion.spawn("squirrel",Habitat.anchor("squirrel"),0)
 Motion.advance(landed,10.0,0,1.0)
 landed.relocate_from=landed.pos
 landed.relocate_at=landed.age
 Motion.advance(landed,0.1,6,1.0)
 check(not bool(landed.fly) and str(landed.support)=="branch","storm never turns perched squirrel into a flying creature")
 var quiet: Dictionary=Motion.spawn("sparrow",Habitat.anchor("sparrow"),0)
 Motion.advance(quiet,5.0,0,0.45)
 check(float(quiet.motion_age)<4.0 and str(quiet.phase)=="idle","quiet gestures preserve lifecycle and stable landing")
 print("HABITAT_ROUTE_TEST checks=%d failures=%d" % [checks,failures])
 quit(1 if failures else 0)
