extends SceneTree
## Native scene regression: --headless --path game --script res://tests/scene_test.gd -- --capture
## --capture keeps normal demo save paths out of test runs.

const VISITORS: Array[String] = ["squirrel", "woodpecker", "owl", "luna_moth", "jewel_beetle", "fireflies", "kingfisher", "swallow", "magpie", "white_eye", "egret", "hedgehog", "cat", "bat", "dragonfly", "ladybug", "stag_beetle"]
const FANTASIES: Array[String] = ["aurora", "star_whale", "time_ripple", "tree_spirit", "lanterns", "ghost_train", "moon_gate", "signal_echo", "aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const ATMOSPHERES: Array[String] = ["aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const MODES: Dictionary = {"squirrel": 0, "woodpecker": 0, "owl": 2, "luna_moth": 2, "jewel_beetle": 1, "fireflies": 2, "aurora": 2, "star_whale": 2, "time_ripple": 3, "tree_spirit": 2, "kingfisher":0,"swallow":0,"magpie":0,"white_eye":7,"egret":5,"hedgehog":3,"cat":3,"bat":2,"dragonfly":0,"ladybug":0,"stag_beetle":2,"lanterns":2,"ghost_train":5,"moon_gate":2,"signal_echo":2,"aurora_crown":2,"ember_clouds":3,"meteor_shower":2,"deep_one":2,"sunken_city":5,"sky_jellyfish":2,"twin_moons":2,"floating_isles":0,"bioluminescent_tide":2,"constellation_stag":2}
var failures: int = 0
var checks: int = 0
var recorded: Array[String] = []
var selected: Array[String] = []

# A paint callback spy verifies that asset registration replaces subjects,
# rather than merely covering the same shapes with an additional image layer.
class AtmosphereDrawingProbe extends "res://scripts/window_scene.gd":
    var subject_draws: int = 0
    var detail_ids: Array[String] = []
    var weather_draws: int = 0
    var boat_draws: int = 0
    var beacon_draws: int = 0

    func _draw_valley_mist() -> void: weather_draws += 1
    func _draw_water() -> void: weather_draws += 1
    func _draw_distant_town() -> void: weather_draws += 1
    func _draw_stars() -> void: weather_draws += 1
    func _draw_airborne_details() -> void: weather_draws += 1
    func _draw_window_life() -> void: weather_draws += 1
    func _draw_rain() -> void: weather_draws += 1
    func _draw_snow() -> void: weather_draws += 1
    func _draw_boat() -> void: boat_draws += 1
    func _draw_signal_towers() -> void: beacon_draws += 1
    func _draw_attraction() -> void: pass

    func _draw_deep_one(_t: float, _alpha: float) -> void:
        subject_draws += 1

    func _draw_floating_isles(_t: float, _alpha: float) -> void:
        subject_draws += 1

    func _draw_painted_details(id: String, _t: float, _alpha: float) -> void:
        detail_ids.append(id)

func _initialize() -> void:
    _run.call_deferred()

func check(condition: bool, label: String) -> void:
    checks += 1
    if condition:
        print("PASS ", label)
    else:
        failures += 1
        push_error(label)

func _run() -> void:
    var scene: Node2D = load("res://scripts/window_scene.gd").new()
    root.add_child(scene)
    scene.set_process(false)
    scene.encounter.connect(func(id: String, _note: String): recorded.append(id))
    scene.bird_selected.connect(func(id: String): selected.append(id))
    # Deliberately offset and scale the native drawing node. Mouse coordinates
    # must travel through the real viewport rather than call a hit-test helper.
    scene.position = Vector2(83, 47)
    scene.scale = Vector2(0.7, 0.7)
    for id in VISITORS + FANTASIES:
        scene.actors.clear()
        scene.spectacles.clear()
        scene.set_weather(int(MODES[id]))
        var before: int = recorded.size()
        scene.trigger(id)
        scene._process(3.5)
        check(scene.get_active_event_ids().has(id), id + " has a visible actor/event at preview time")
        check(recorded.size() == before + 1 and recorded.back() == id, id + " records exactly once")
        await process_frame
        if id in VISITORS:
            selected.clear()
            var click: InputEventMouseButton = InputEventMouseButton.new()
            click.button_index = MOUSE_BUTTON_LEFT
            click.pressed = true
            click.position = scene.get_global_transform_with_canvas() * scene.get_actor_position(id)
            root.push_input(click, true)
            await process_frame
            check(selected.has(id), id + " opens through transformed viewport click")
        before = recorded.size()
        scene.trigger(id, false)
        scene._process(0.5)
        check(recorded.size() == before, id + " replay does not record")
        check(scene.get_active_event_ids().has(id), id + " replay creates a visual")
        scene.set_quiet(true)
        before = recorded.size()
        scene.trigger(id)
        scene._process(2.5)
        check(recorded.size() == before + 1, id + " quiet mode still records")
        check(scene.activity_blend < 0.48, id + " quiet mode reduces animation intensity")
        if id=="deep_one":check(not scene.is_event_visible(id), "large deep-water silhouette is hidden during quiet focus")
        scene.set_quiet(false)
    # Rare moments last long enough to inspect instead of disappearing on click.
    for id in FANTASIES:
        scene.spectacles.clear()
        scene.trigger(id, false)
        var duration: float=scene.get_event_duration(id)
        scene._process(duration-4.0)
        check(scene.get_active_event_ids().has(id), id + " remains present until its fade-out")
        check(scene.is_event_visible(id), id + " still has visible content near the end")
        scene._process(5.0)
        check(not scene.get_active_event_ids().has(id), id + " expires cleanly")
    scene.actors.clear()
    scene.spectacles.clear()
    for index in range(150):
        scene.trigger(VISITORS[index % VISITORS.size()], false)
        scene.trigger(FANTASIES[index % FANTASIES.size()], false)
    check(scene.actors.size() <= 6 and scene.spectacles.size() <= 2, "repeated demos have bounded visual density")
    check(scene.get_active_event_ids().count("squirrel") <= 1, "same visitor never piles up")
    # Existing bird and weather behavior remains compatible with the demo.
    scene.actors.clear()
    scene.set_weather(1)
    scene.trigger("sparrow", false)
    scene._process(8.0)
    check(not bool(scene.actors[0]["fly"]), "rain birds remain sheltered")
    check(scene.weather_weights[1] > 0.99, "weather transition completes")
    scene.trigger("butterfly", false)
    check(not scene.get_active_event_ids().has("butterfly"), "no butterfly visual in rain")
    scene.set_weather(0)
    scene.actors.clear()
    scene.trigger("sparrow", false)
    scene._process(13.5)
    check(bool(scene.actors[0]["fly"]) and scene.actors[0].get("support")=="air", "sunny sparrow makes a deliberate feeder flight after perching")
    scene._process(60.0)
    check(scene.actors.is_empty() and scene.spectacles.is_empty(), "all temporary visuals eventually expire")
    for mode in range(8):
        scene.set_weather(mode)
        scene._process(6.0)
        check(scene.weather_weights[mode] > 0.99, "weather %d has complete effect transition" % mode)
        check(not scene.get_weather_behavior().is_empty(), "weather %d has visitor behavior" % mode)
        await process_frame
    scene.set_weather(6)
    scene.actors.clear()
    scene.trigger("sparrow",false)
    scene._process(8.0)
    check(not bool(scene.actors[0]["fly"]), "storm birds shelter rather than cross the feeder")
    var minimums: Array[float] = [1.0,1.0]
    var maximums: Array[float] = [0.0,0.0]
    var beacons_present: bool = true
    for sample in range(48):
        scene._process(0.35)
        var levels: Array[float] = scene.get_beacon_levels()
        beacons_present = beacons_present and levels.size()==2
        for index in range(2):
            minimums[index]=minf(minimums[index],levels[index])
            maximums[index]=maxf(maximums[index],levels[index])
    check(beacons_present, "two distant beacons remain present through their full cycles")
    for index in range(2):
        check(maximums[index]-minimums[index]>0.6, "beacon %d actually blinks over time" % index)
    scene.set_quiet(true)
    var quiet_max: float=0.0
    for sample in range(32):
        scene._process(0.4)
        for level in scene.get_beacon_levels():quiet_max=maxf(quiet_max,level)
    check(quiet_max<0.6, "quiet mode softens tower lamps without stopping them")
    for item in ["seeds","fruit","flowers","lantern"]:
        scene.set_attraction(item)
        check(scene.attraction==item, "placed item "+item+" is visible in world state")
        await process_frame
    for id in ATMOSPHERES:
        check(scene.get_event_duration(id)>=55.0, id+" allows about a minute of painted observation")
    scene.set_attraction("invalid")
    check(scene.attraction=="seeds", "unknown decoration safely falls back")
    check(await _check_painted_atmospheres(scene) == true, "painted atmosphere regression completes without script errors")
    print("SCENE_TEST checks=", checks, " failures=", failures)
    quit(1 if failures else 0)

func _check_painted_atmospheres(scene: Node2D) -> bool:
    scene.set_quiet(false)
    scene.spectacles.clear()
    check(scene.get_atmosphere_state().is_empty(), "empty world has no painted atmosphere")
    scene.trigger("ghost_train", false)
    check(scene.get_atmosphere_state().is_empty(), "older encounters do not replace the painted scene")
    var registration: Array[String] = ["deep_one", "deep_one", "invalid", "sparrow"]
    scene.set_painted_atmospheres(registration)
    check(scene.painted_atmosphere_ids == ["deep_one"], "only unique supported painting IDs are registered")
    scene.set_painted_atmospheres(ATMOSPHERES)
    var before: int = recorded.size()
    for id in ATMOSPHERES:
        scene.clear_atmosphere_events()
        scene.trigger(id, false)
        scene._process(9.0)
        var state: Dictionary = scene.get_atmosphere_state()
        check(str(state.get("id", "")) == id and is_equal_approx(float(state.get("age", -1)), 9.0), id + " exposes the actual playback age")
        check(is_equal_approx(float(state.get("duration", 0)), 60.0) and not bool(state.get("quiet", true)), id + " exposes a full-minute normal scene")
        await process_frame
        scene.set_quiet(true)
        state = scene.get_atmosphere_state()
        check(state.is_empty() if id == "deep_one" else bool(state.get("quiet", false)), id + " applies its quiet atmosphere policy")
        scene.set_quiet(false)
        scene.trigger(id, false)
        check(is_zero_approx(float(scene.get_atmosphere_state().get("age", -1))), id + " replay restarts the full painting")
        scene._process(61.0)
        check(scene.get_atmosphere_state().is_empty(), id + " relinquishes the scene when playback ends")
    check(recorded.size() == before, "painting playback and expiry never create collection records")

    scene.trigger("ember_clouds", false)
    scene._process(2.0)
    scene.trigger("twin_moons", false)
    scene._process(1.0)
    var newest: Dictionary = scene.get_atmosphere_state()
    check(newest.get("id") == "twin_moons" and is_equal_approx(float(newest.get("age", 0)), 1.0), "the latest encounter owns the atmosphere independently of older age")
    check(not scene.is_event_visible("ember_clouds"), "an older painted event cannot draw over the newer scene")
    newest["age"] = 999.0
    newest["id"] = "deep_one"
    check(scene.get_atmosphere_state().get("id") == "twin_moons" and float(scene.get_atmosphere_state()["age"]) < 2.0, "atmosphere snapshots cannot mutate active encounters")
    scene.trigger("deep_one", false)
    scene.set_quiet(true)
    check(scene.get_atmosphere_state().is_empty(), "quiet deep water does not reveal an older painted encounter")
    scene.set_quiet(false)
    check(scene.get_atmosphere_state().get("id") == "deep_one", "leaving quiet mode restores the current deep-water encounter")

    scene.spectacles.clear()
    scene.actors.clear()
    scene.trigger("cat", false)
    scene.trigger("lanterns", false)
    scene.trigger("aurora_crown", false)
    scene.clear_atmosphere_events()
    check(scene.get_atmosphere_state().is_empty() and scene.get_active_event_ids().has("cat") and scene.get_active_event_ids().has("lanterns"), "manual weather reset keeps visitors and ordinary encounters")
    check(recorded.size() == before, "manual weather reset never changes collection records")
    scene.set_weather(0)
    scene._process(8.0)
    var original: Color = scene._ambient_color(Color(0.8, 0.7, 0.6, 0.5))
    scene.trigger("ember_clouds", false)
    scene._process(8.0)
    var painted: Color = scene._ambient_color(Color(0.8, 0.7, 0.6, 0.5))
    check(painted.b < original.b - 0.02 and is_equal_approx(painted.a, original.a), "painted warmth reaches visitors without changing their transparency")
    scene.clear_atmosphere_events()
    scene._process(0.1)
    var returning: Color = scene._ambient_color(Color(0.8, 0.7, 0.6, 0.5))
    check(returning.b > painted.b and returning.b < original.b, "visitor lighting returns gradually after leaving an encounter")
    scene._process(8.0)
    check(scene._ambient_color(Color(0.8, 0.7, 0.6, 0.5)).is_equal_approx(original), "visitor lighting fully recovers after an encounter")

    var probe: AtmosphereDrawingProbe = AtmosphereDrawingProbe.new()
    for id in ["deep_one", "floating_isles"]:
        probe.trigger(id, false)
        probe._process(9.0)
        probe._draw_fantasy(probe.spectacles.back())
    check(probe.subject_draws == 2, "missing paintings retain the playable native fallback")
    probe.set_painted_atmospheres(ATMOSPHERES)
    for id in ATMOSPHERES:
        probe.trigger(id, false)
        probe._process(9.0)
        probe._draw_fantasy(probe.spectacles.back())
    check(probe.detail_ids.is_empty() and probe.subject_draws == 2, "all ten registered layered events replace both native subjects and old accents")
    probe.trigger("deep_one", false)
    probe.set_quiet(true)
    probe._draw_fantasy(probe.spectacles.back())
    check(probe.detail_ids.is_empty() and probe.subject_draws == 2, "quiet deep water emits neither subject nor accent drawing")
    probe.set_quiet(false)
    probe.trigger("twin_moons", false)
    probe._draw_fantasy(probe.spectacles.front())
    check(probe.detail_ids.is_empty(), "superseded events cannot leak their old accents into independent layers")
    probe.actors.clear()
    probe.spectacles.clear()
    probe._draw()
    check(probe.weather_draws == 8 and probe.beacon_draws == 1, "standalone world retains its native weather fallback")
    probe.set_layered_weather_enabled(true)
    probe._draw()
    check(probe.weather_draws == 8 and probe.boat_draws == 1 and probe.beacon_draws == 2, "layered scenery suppresses duplicate weather while keeping the boat and beacons")
    probe.set_weather(6)
    probe.trigger("sparrow", false)
    probe._process(8.0)
    check(probe.weather_weights[6] > 0.99 and not bool(probe.actors[0]["fly"]), "layer ownership does not change animal weather behavior")
    probe.actors.clear()
    probe.set_layered_weather_enabled(false)
    probe._draw()
    check(probe.weather_draws == 16, "disabling layered scenery restores the standalone weather fallback")
    probe.free()
    return true
