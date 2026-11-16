extends SceneTree
## Run with --test-mode --capture. This invokes real GM clearing, without a save.
const World: Script = preload("res://scripts/window_scene.gd")
const Commands: Script = preload("res://scripts/gm_commands.gd")
const NEW_BIRDS: Array[String] = ["pigeon", "crow", "cockatiel", "dough_bird", "dandelion_bird", "paper_bird", "cloud_bird", "yarn_bird", "clockwork_bird", "alien_bird", "twin_bird", "invisible_bird", "shadow_bird", "inverted_bird", "galaxy_bird", "crescent_bird"]
const BASE_BIRDS: Array[String] = ["sparrow", "tit", "robin", "woodpecker", "owl", "kingfisher"]
var checks: int = 0
var failures: int = 0
var recordings: Dictionary = {}

func _initialize() -> void:
 run.call_deferred()

func check(ok: bool, label: String) -> void:
 checks += 1
 if ok: print("PASS ", label)
 else:
  failures += 1
  push_error("VISITOR_QUEUE_TEST " + label)

func queued_ids(world: Node) -> Array[String]:
 var ids: Array[String] = []
 for actor: Dictionary in world.actors:
  for id: String in actor.get("replacement_queue", []): ids.append(id)
 return ids

func on_encounter(id: String, _note: String) -> void:
 recordings[id] = int(recordings.get(id, 0)) + 1

func fill_scene(world: Node) -> void:
 world.actors.clear()
 for id: String in BASE_BIRDS: world.trigger(id, false)

func burst(world: Node) -> void:
 for id: String in NEW_BIRDS: world.trigger(id)

func run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):
  push_error("Run with --test-mode --capture to isolate all state")
  quit(1)
  return
 var real_path: String = "user://window_diary_demo_save.json"
 var existed: bool = FileAccess.file_exists(real_path)
 var old_hash: String = FileAccess.get_sha256(real_path) if existed else ""
 var state: Node = root.get_node("DiaryState")
 state.set_process(false)
 var collection_before: Dictionary = state.collection.duplicate(true)
 var records_before: Array = state.records.duplicate(true)
 var host: Node = Node.new()
 root.add_child(host)
 var world: Node = World.new()
 world.name = "World"
 host.add_child(world)
 world.set_process(false)
 world.encounter.connect(on_encounter)
 world.set_weather(0)
 fill_scene(world)
 burst(world)
 var initial_pending: Array[String] = queued_ids(world)
 check(world.actors.size() == 6 and initial_pending.size() == 16, "six occupied slots retain all sixteen additional bird requests")
 var pending_once: bool = true
 for id: String in NEW_BIRDS:
  if initial_pending.count(id) != 1: pending_once = false
 check(pending_once, "every pending bird has exactly one queue entry, including both legendary birds")
 # GM/replay repetitions cannot add a second actor or pending entry.
 for id: String in NEW_BIRDS: world.trigger(id, false)
 for id: String in BASE_BIRDS: world.trigger(id, false)
 check(queued_ids(world).size() == 16 and world.actors.size() == 6, "retriggering queued or active species does not duplicate them")
 var seen: Dictionary = {}
 var bounded: bool = true
 var unique: bool = true
 for frame: int in range(600):
  var active: Array[String] = []
  for actor: Dictionary in world.actors:
   var id: String = str(actor.id)
   if active.has(id): unique = false
   active.append(id)
   if NEW_BIRDS.has(id): seen[id] = true
  var pending: Array[String] = queued_ids(world)
  var all_ids: Array[String] = active + pending
  for id: String in all_ids:
   if all_ids.count(id) != 1: unique = false
  if world.actors.size() > 6: bounded = false
  if world.actors.is_empty(): break
  world._process(0.25)
 check(seen.size() == 16, "all sixteen requested birds eventually become actors instead of being overwritten")
 check(bounded and unique, "active actors never exceed six and no ID is active or queued twice")
 check(world.actors.is_empty() and queued_ids(world).is_empty(), "a finite burst fully drains through departure animations")
 var recorded_once: bool = recordings.size() == 16
 for id: String in NEW_BIRDS:
  if int(recordings.get(id, 0)) != 1: recorded_once = false
 check(recorded_once, "queue admission and requeue never emit a second encounter for the same request")
 fill_scene(world)
 burst(world)
 world.trigger("aurora", false)
 check(queued_ids(world).size() == 16, "GM clear fixture contains a full pending queue")
 var before_clear: Dictionary = recordings.duplicate(true)
 var backend: RefCounted = Commands.new()
 var result: Dictionary = backend.execute("clear actors", host)
 check(bool(result.get("ok", false)) and world.actors.is_empty() and queued_ids(world).is_empty(), "real GM clear actors discards active actors and their entire queue")
 check(world.spectacles.size() == 1 and str(world.spectacles[0].id) == "aurora", "clearing creatures keeps the active atmosphere intact")
 for frame: int in range(480): world._process(0.25)
 check(world.actors.is_empty() and recordings == before_clear, "cleared birds never respawn later and no delayed encounter is emitted")
 world.trigger("galaxy_bird", false)
 check(world.actors.size() == 1 and str(world.actors[0].id) == "galaxy_bird", "a genuinely new visit works after GM clearing")
 check(state.collection == collection_before and state.records == records_before, "queue and replay tests do not change collection progress")
 check((FileAccess.file_exists(real_path) and FileAccess.get_sha256(real_path) == old_hash) if existed else not FileAccess.file_exists(real_path), "real player save remains unchanged")
 host.free()
 print("VISITOR_QUEUE_TEST checks=%d failures=%d" % [checks, failures])
 quit(1 if failures else 0)
