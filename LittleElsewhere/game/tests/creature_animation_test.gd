extends SceneTree
const World = preload("res://scripts/window_scene.gd")
var checks: int = 0
var failures: int = 0
var recordings: int = 0

func _initialize() -> void:
    run.call_deferred()

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func run() -> void:
    var world = World.new()
    root.add_child(world)
    world.set_process(false)
    world.encounter.connect(func(_id: String, _note: String): recordings += 1)
    check(world.get_creature_ids().size() == 21, "exactly 21 creatures are exposed")
    var scenery: Rect2 = Rect2(0, 0, 1440, 810)
    for id in world.get_creature_ids():
        world.actors.clear()
        world.spectacles.clear()
        world.set_quiet(false)
        world.set_weather(0)
        world.activity_blend = 1.0
        var before: int = recordings
        world.trigger(id)
        var state: Dictionary = world.get_actor_lifecycle_snapshot(id)
        check(str(state.get("phase", "")) == "entry", id + " starts with an entry")
        check(not scenery.intersects(world._actor_hit_rect(world.actors[0])), id + " begins off the scenery")
        var previous: Vector2 = state["position"]
        var phases: Array[String] = []
        var visible: bool = false
        var continuous: bool = true
        var finite: bool = true
        var opaque: bool = true
        var progress_ok: bool = true
        var last_rect: Rect2
        var duration: float = float(state["duration"])
        for frame in range(int(ceil(duration * 60.0)) + 2):
            world._process(1.0 / 60.0)
            state = world.get_actor_lifecycle_snapshot(id)
            if state.is_empty(): break
            var point: Vector2 = state["position"]
            finite = finite and point.is_finite()
            continuous = continuous and previous.distance_to(point) < 15.0
            previous = point
            var phase: String = str(state["phase"])
            if not phases.has(phase): phases.append(phase)
            var p: float = float(state["phase_progress"])
            progress_ok = progress_ok and p >= 0.0 and p <= 1.0
            opaque = opaque and is_equal_approx(float(state["alpha"]), 1.0)
            last_rect = world._actor_hit_rect(world.actors[0])
            if phase == "idle": visible = visible or scenery.intersects(last_rect)
        check(phases == ["entry", "idle", "exit"], id + " runs entry then idle then exit")
        check(finite and continuous, id + " has finite continuous motion without teleports")
        check(progress_ok, id + " reports bounded phase progress")
        check(visible, id + " is present in the scenery during idle")
        check(opaque, id + " does not fade in place to hide missing movement")
        check(not scenery.intersects(last_rect), id + " is outside scenery before removal")
        check(world.actors.is_empty(), id + " completes its lifecycle")
        check(recordings == before + 1, id + " records once across all phases")
        # Deterministic phase preview is useful for every species and does not record.
        world.trigger(id, false)
        for phase in ["entry", "idle", "exit"]:
            check(world.seek_actor_phase(id, phase, 0.5), id + " can seek " + phase)
            state = world.get_actor_lifecycle_snapshot(id)
            check(state.get("phase") == phase and absf(float(state["phase_progress"]) - 0.5) < 0.001, id + " seek uses phase-local progress")
        check(recordings == before + 1, id + " preview stays unrecorded")
        # Quiet affects gesture pacing, never lifespan or the ability to leave.
        world.actors.clear()
        world.set_quiet(true)
        world.activity_blend = 0.45
        world.trigger(id, false)
        world._process(10.0)
        state = world.get_actor_lifecycle_snapshot(id)
        check(float(state["motion_age"]) < float(state["age"]) * 0.75, id + " quiet reduces gesture pace")
        world._process(duration)
        check(world.actors.is_empty(), id + " quiet completes departure")
        print("PASS creature lifecycle: ", id)
    world.set_quiet(false)
    world.set_weather(0)
    world.trigger("butterfly", false)
    world.seek_actor_phase("butterfly", "idle", 0.25)
    var old_position: Vector2 = world.get_actor_position("butterfly")
    world.set_weather(6)
    world._process(1.0 / 60.0)
    var butterfly: Dictionary = world.get_actor_lifecycle_snapshot("butterfly")
    check(butterfly.get("phase") == "exit", "weather sends butterfly into a proper departure")
    check((butterfly["position"] as Vector2).distance_to(old_position) < 1.0, "weather departure starts at butterfly current position")
    check(float(butterfly["alpha"]) == 1.0, "weather never abruptly fades butterfly away")
    world._process(5.0)
    check(world.actors.is_empty(), "weather departure finishes")
    world.set_weather(0)
    world.trigger("sparrow", false)
    world.seek_actor_phase("sparrow", "idle", 0.25)
    old_position = world.get_actor_position("sparrow")
    world.set_weather(6)
    world._process(1.0 / 60.0)
    check(world.get_actor_position("sparrow").distance_to(old_position) < 2.0, "changing weather midflight is continuous")
    world._process(3.0)
    check(not bool(world.get_actor_lifecycle_snapshot("sparrow")["flying"]), "bird reaches shelter after weather changes")
    world.actors.clear()
    for id in ["sparrow", "tit", "robin", "cat", "hedgehog", "owl"]: world.trigger(id, false)
    var retained: Array[String] = []
    for actor in world.actors: retained.append(str(actor["id"]))
    world.trigger("squirrel", false)
    check(world.actors.size() == 6, "full scene has six visitors")
    for id in retained: check(not world.get_actor_lifecycle_snapshot(id).is_empty(), "capacity never hard-removes " + id)
    check(world.get_actor_lifecycle_snapshot("sparrow").get("phase") == "exit", "capacity asks old visitor to leave")
    world._process(4.1)
    check(not world.get_actor_lifecycle_snapshot("squirrel").is_empty(), "queued species enters when departure completes")
    old_position = world.get_actor_position("squirrel")
    world.trigger("squirrel", false)
    check(world.get_actor_position("squirrel") == old_position, "retrigger never teleports an existing visitor")
    world.free()
    print("CREATURE_ANIMATION_TEST checks=%d failures=%d" % [checks, failures])
    quit(1 if failures else 0)
