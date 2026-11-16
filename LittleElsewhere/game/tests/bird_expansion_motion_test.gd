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
  push_error("BIRD_EXPANSION_MOTION_FAIL "+message)
func brown(image: Image, world: Vector2) -> bool:
 var px: Vector2i=Vector2i(world*Vector2(image.get_size())/Vector2(1440,810))
 var c: Color=image.get_pixel(px.x,px.y)
 return c.a>0.8 and c.r>c.g*1.10 and c.r>c.b*1.25
func run() -> void:
 check(Motion.IDS.size()==37 and Motion.BIRDS.size()==26,"37 creatures including 26 birds")
 check(Motion.EXPANSION_BIRDS.size()==16,"16 added species have complete motion definitions")
 var tree: Image=(load("res://assets/art/layers_v1/tree.png") as Texture2D).get_image()
 for id: String in Motion.EXPANSION_BIRDS:
  var anchor: Vector2=Habitat.anchor(id)
  if Habitat.support(id)=="branch":
   var contact: bool=false
   for offset: int in range(-1,4):contact=contact or brown(tree,anchor+Vector2(0,offset))
   check(contact,id+" feet touch actual branch paint")
  if id=="inverted_bird":
   check(brown(tree,anchor-Vector2(0,1)) and not brown(tree,anchor+Vector2(0,5)),"hanging feet lie at lower edge of painted branch")
  var actor: Dictionary=Motion.spawn(id,anchor,0)
  var prev: Vector2=actor.pos
  var prev_invert: float=float(actor.get("invert_blend",0.0))
  var phases: Array[String]=[]
  var saw_food: bool=false
  var saw_personality: bool=false
  var continuous: bool=true
  var constraints: bool=true
  var stable_contact: bool=true
  for frame: int in range(int(actor.duration*60)+1):
   Motion.advance(actor,1.0/60.0,0,1.0)
   var point: Vector2=actor.pos
   var inverted: float=actor.get("invert_blend",0.0)
   if not phases.has(str(actor.phase)):phases.append(str(actor.phase))
   continuous=continuous and point.is_finite() and point.distance_to(prev)<16.0 and absf(inverted-prev_invert)<0.06
   saw_food=saw_food or float(actor.feed_blend)>0.1
   saw_personality=saw_personality or str(actor.special_action) not in ["observe","feed"]
   constraints=constraints and float(actor.alpha)==1.0 and inverted>=0.0 and inverted<=1.0
   if id=="shadow_bird":constraints=constraints and anchor==Vector2(1040,755) and not bool(actor.fly) and is_equal_approx(point.y,anchor.y) and str(actor.support)=="sill"
   if id=="inverted_bird" and inverted>0.01:
    stable_contact=stable_contact and point.distance_to(anchor)<0.01 and str(actor.support)=="branch_underside" and not bool(actor.fly)
   if str(actor.phase)=="idle" and id not in ["cloud_bird","crow","clockwork_bird","twin_bird"]:
    stable_contact=stable_contact and point.distance_to(anchor)<0.01
   prev=point
   prev_invert=inverted
  check(phases==["entry","idle","exit"],id+" reaches all lifecycle phases")
  check(saw_food,id+" has observable feeding gesture")
  check(saw_personality or id in ["shadow_bird","inverted_bird"],id+" has its own personality gesture")
  check(continuous and constraints,id+" is continuous, opaque and obeys locomotion constraints")
  check(stable_contact,id+" remains physically attached while resting or rotating")
  check(not Rect2(-80,-110,1600,980).has_point(actor.pos),id+" leaves beyond viewport")
  for stop_at: float in [0.5,Motion.entry_duration(id)*0.75,Motion.entry_duration(id)*0.90,Motion.entry_duration(id)+1.0,Motion.entry_duration(id)+12.0]:
   var interrupted: Dictionary=Motion.spawn(id,anchor,0)
   Motion.advance(interrupted,stop_at,0,1.0)
   var before: Vector2=interrupted.pos
   var before_invert: float=interrupted.get("invert_blend",0.0)
   Motion.request_departure(interrupted)
   Motion.sample(interrupted,0,1.0)
   var departure_ok: bool=before.distance_to(interrupted.pos)<0.01 and absf(before_invert-float(interrupted.get("invert_blend",0.0)))<0.001
   var previous: Vector2=interrupted.pos
   for frame: int in range(int(interrupted.exit_duration*60)+1):
    Motion.advance(interrupted,1.0/60.0,0,1.0)
    departure_ok=departure_ok and previous.distance_to(interrupted.pos)<16.0
    if id=="shadow_bird":departure_ok=departure_ok and not bool(interrupted.fly) and is_equal_approx((interrupted.pos as Vector2).y,anchor.y)
    previous=interrupted.pos
   check(departure_ok,id+" interrupted departure starts at actual pose/contact: "+str(stop_at))
 print("BIRD_EXPANSION_MOTION_TEST checks=%d failures=%d" % [checks,failures])
 quit(1 if failures else 0)
