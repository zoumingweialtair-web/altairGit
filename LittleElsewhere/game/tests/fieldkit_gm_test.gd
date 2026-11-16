extends SceneTree
## Isolated regression: --headless --path game --script res://tests/fieldkit_gm_test.gd -- --capture --test-mode
const Commands = preload("res://scripts/gm_commands.gd")
const World = preload("res://scripts/window_scene.gd")
var failures: int = 0
var checks: int = 0
func check(value: bool, note: String) -> void:
 checks += 1
 if not value:
  failures += 1
  push_error("FIELDKIT_GM " + note)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):
  push_error("Use --capture to protect the normal save.")
  quit(1)
  return
 var state: Node = root.get_node("DiaryState")
 state.set_process(false)
 state.collection.clear()
 state.records.clear()
 var scene: Node = Node.new()
 var fixture: GDScript = GDScript.new()
 fixture.source_code = "extends Node\nvar weather_mode: int = 0\nfunc _change_weather(value: int, _record: bool = false) -> void:\n weather_mode = value\n $World.set_weather(value)\n"
 check(fixture.reload() == OK, "world fixture compiles")
 scene.set_script(fixture)
 var world: Node = World.new()
 world.name = "World"
 scene.add_child(world)
 root.add_child(scene)
 world.set_process(false)
 var commands: RefCounted = Commands.new()
 for id: String in world.get_creature_ids():
  world.actors.clear()
  for phase: String in ["entry", "idle", "exit"]:
   var result: Dictionary = commands.execute("motion " + id + " " + phase + " 0.5", scene)
   check(bool(result.get("ok", false)), id + " " + phase + " accepted")
   check(str(world.get_actor_lifecycle_snapshot(id).get("phase", "")) == phase, id + " exact phase sampled")
  commands.execute("motion " + id + " idle 0.5", scene)
  var before: Vector2 = world.get_actor_position(id)
  check(bool(commands.execute("depart " + id, scene).get("ok", false)), id + " departs")
  check(world.get_actor_lifecycle_snapshot(id).get("phase", "") == "exit", id + " departure sets exit")
  check(world.get_actor_position(id).distance_to(before) < 0.01, id + " departure is continuous")
 check(state.get_count() == 0 and state.records.is_empty(), "every motion and departure grants no discovery")
 for invalid: String in ["motion sparrow flight", "motion absent idle", "motion aurora idle", "motion sparrow idle -1", "motion sparrow idle 1.1", "motion sparrow idle nope", "motion sparrow idle 0.5 extra", "depart absent", "depart aurora", "food", "food level -1", "food level 101", "food level nan", "food stock millet 1000", "food stock millet -1", "food stock unknown 2", "food stock millet 2.5", "food status extra"]:
  check(not bool(commands.execute(invalid, scene).get("ok", false)), "reject " + invalid)
 check(commands.complete("motion squir").has("motion squirrel idle 0.5"), "motion autocomplete")
 check(commands.complete("food stock m").has("food stock millet 36"), "food autocomplete")
 var normal_path: String = "user://window_diary_demo_save.json"
 var normal_hash: String = FileAccess.get_sha256(normal_path) if FileAccess.file_exists(normal_path) else ""
 var test_path: String = "user://fieldkit_gm_%d_%d.json" % [OS.get_process_id(), Time.get_ticks_usec()]
 state.storage_path_override = test_path
 check(bool(commands.execute("food stock millet 123", scene).get("ok", false)), "stock writes isolated save")
 check(bool(commands.execute("food level 25.5", scene).get("ok", false)), "level accepts finite percentage")
 check(bool(commands.execute("food status", scene).get("ok", false)), "food status readable")
 var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(test_path))
 check(int(saved.get("seed_stocks", {}).get("millet", 0)) == 123 and is_equal_approx(float(saved.get("food_percent", 0)), 25.5), "stock and food percentage persist")
 check((FileAccess.get_sha256(normal_path) if FileAccess.file_exists(normal_path) else "") == normal_hash, "normal save unchanged")
 state.storage_path_override = ""
 for suffix: String in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(test_path + suffix):
   DirAccess.remove_absolute(test_path + suffix)
 scene.queue_free()
 await process_frame
 print("FIELDKIT_GM_TEST checks=%d failures=%d" % [checks, failures])
 quit(failures)
