extends SceneTree
const World=preload("res://scripts/window_scene.gd")
const Habitat=preload("res://scripts/habitat_paths.gd")
const Motion=preload("res://scripts/visitor_motion.gd")
var checks: int=0
var failures: int=0
func _initialize() -> void:
 run.call_deferred()
func check(ok: bool, label: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error("BIRD_PERCH_SPACING_FAIL "+label)
func on_branch(image: Image, point: Vector2) -> bool:
 for offset: int in range(-1,4):
  var px: Vector2i=Vector2i((point+Vector2(0,offset))*Vector2(image.get_size())/Vector2(1440,810))
  var c: Color=image.get_pixelv(px)
  if c.a>0.8 and c.r>c.g*1.10 and c.r>c.b*1.25:return true
 return false
func run() -> void:
 var world=World.new()
 root.add_child(world)
 world.set_process(false)
 world.actors.clear()
 var tree: Image=(load("res://assets/art/layers_v1/tree.png") as Texture2D).get_image()
 # An unoccupied single-species preview retains its intended art contact.
 for id: String in Motion.EXPANSION_BIRDS:
  world.actors.clear()
  world.trigger(id,false)
  check((world.actors[0].anchor as Vector2)==Habitat.anchor(id),id+" keeps preferred perch when free")
 # Incoming birds reserve real contacts before any of them has landed.
 world.actors.clear()
 var contacts: Dictionary={}
 for id: String in ["sparrow","tit","clockwork_bird","alien_bird","twin_bird","galaxy_bird"]:
  world.trigger(id,false)
  var actor: Dictionary=world.get_actor_lifecycle_snapshot(id)
  var contact: Vector2=actor.anchor
  check(on_branch(tree,contact),id+" assigned contact sits on actual tree paint")
  if id in Motion.EXPANSION_BIRDS:
   var nearest: float=INF
   for old_point: Vector2 in contacts.values():nearest=minf(nearest,old_point.distance_to(contact))
   var best_available: float=0.0
   # A crowded sixth bird still selects the greatest available clearance;
   # the compact drawn tree cannot always provide six 60px gaps.
   var reserved: Array[Vector2]=[]
   for old_point: Vector2 in contacts.values():reserved.append(old_point)
   for source_id: String in ["squirrel","robin","owl","sparrow","kingfisher","white_eye","tit","magpie"]:
    best_available=maxf(best_available,world._branch_clearance(Habitat.anchor(source_id),reserved))
   for candidate: Vector2 in Habitat.SHELTER.values():best_available=maxf(best_available,world._branch_clearance(candidate,reserved))
   check(nearest>=60.0 or nearest>=best_available-0.01,id+" selects free contact or greatest remaining gap")
   check(nearest>25.0,id+" never stacks directly on another bird")
  contacts[id]=contact
 for id: String in contacts:
  world.seek_actor_phase(id,"idle",0.02)
  var actor: Dictionary=world.get_actor_lifecycle_snapshot(id)
  check((actor.anchor as Vector2)==contacts[id] and (actor.position as Vector2).distance_to(contacts[id])<0.01,id+" keeps reserved feet contact after landing")
 # Special habitats are unchanged even with occupied branches.
 for id: String in ["inverted_bird","shadow_bird","cloud_bird","pigeon","dough_bird","invisible_bird"]:
  world.actors.clear()
  world.trigger("sparrow",false)
  world.trigger("tit",false)
  world.trigger(id,false)
  check((world.get_actor_lifecycle_snapshot(id).anchor as Vector2)==Habitat.anchor(id),id+" preserves special habitat")
 world.free()
 print("BIRD_PERCH_SPACING_TEST checks=%d failures=%d" % [checks,failures])
 quit(1 if failures else 0)
