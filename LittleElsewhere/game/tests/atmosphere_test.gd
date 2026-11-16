extends SceneTree
## --headless --path <project> --script res://tests/atmosphere_test.gd -- --capture
## Exercises real independent layers and motion; the normal save is read-only.
const IDS: Array[String] = ["aurora_crown","ember_clouds","meteor_shower","deep_one","sunken_city","sky_jellyfish","twin_moons","floating_isles","bioluminescent_tide","constellation_stag"]
const LAYERS: Array[String] = ["Sky","Stars","FarClouds","EventSky","Mountains","FarMist","Water","EventWater","TownShore","Tree","NearRainSnow","Foreground"]
const ART_IDS: Array[String] = ["mountains","town_shore","tree","foreground","water","cloud","deep_one","sunken_city","jellyfish","moon","island","stag"]
const TRANSPARENT_IDS: Array[String] = ["mountains","town_shore","tree","foreground","cloud","deep_one","sunken_city","jellyfish","moon","island","stag"]
const TEXTURED_EVENTS: Array[String] = ["deep_one","sunken_city","sky_jellyfish","twin_moons","floating_isles","constellation_stag"]
const VIEW_RECT: Rect2 = Rect2(0,0,1440,810)
const NORMAL_SAVE: String = "user://window_diary_demo_save.json"
var checks: int = 0
var failures: int = 0
var normal_existed: bool = false
var normal_bytes: PackedByteArray = PackedByteArray()

func _initialize() -> void:
    _run.call_deferred()

func check(ok: bool, label: String) -> void:
    checks += 1
    if ok: print("PASS ",label)
    else:
        failures += 1
        push_error("ATMOSPHERE_TEST "+label)

func _has_cutout(image: Image) -> bool:
    if image == null or image.is_empty(): return false
    if image.is_compressed(): image.decompress()
    var lowest: float = 1.0
    var highest: float = 0.0
    for y in range(45):
        for x in range(45):
            var pixel: Color = image.get_pixel(int(x*(image.get_width()-1)/44.0),int(y*(image.get_height()-1)/44.0))
            lowest = minf(lowest,pixel.a)
            highest = maxf(highest,pixel.a)
    return lowest < 0.05 and highest > 0.1

func _check_assets() -> bool:
    var complete: bool = true
    var hashes: Dictionary = {}
    for id: String in ART_IDS:
        var path: String = "res://assets/art/layers_v1/"+id+".png"
        var image: Image = Image.new()
        var readable: bool = FileAccess.file_exists(path) and image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))==OK and not image.is_empty()
        check(readable,id+" is an available independent layer asset")
        if not readable:
            complete = false
            continue
        hashes[FileAccess.get_sha256(path)] = true
        if id in TRANSPARENT_IDS:
            var cutout: bool = _has_cutout(image)
            check(cutout,id+" contains both transparent space and visible painted content")
            complete = complete and cutout
    check(hashes.size()==ART_IDS.size(),"independent layer files are distinct assets")
    var no_legacy: bool = true
    for path: String in ["res://main.tscn","res://scenes/weather_stage.tscn","res://scripts/weather_stage.gd","res://scripts/weather_layers.gd","res://scripts/encounter_layers.gd"]:
        if not FileAccess.file_exists(path):
            no_legacy = false
            continue
        for line: String in FileAccess.get_file_as_string(path).split("\n"):
            if line.strip_edges().begins_with("#"): continue
            for legacy: String in ["res://assets/art/v3/","res://assets/art/v4/","res://assets/art/encounters_v1/","res://assets/art/window_background.png","res://assets/art/weather_"]:
                if line.contains(legacy): no_legacy = false
    check(no_legacy,"runtime scenes and layer scripts do not reference old flattened backgrounds")
    return complete and no_legacy

func _advance(app: Control, seconds: float) -> void:
    var remaining: float = seconds
    while remaining>0.0001:
        var step: float = minf(0.25,remaining)
        app.scene_view._process(step)
        app._process(step)
        app.backdrop._process(step)
        remaining -= step

func _shader_time(item: CanvasItem, parameter: String) -> Variant:
    var material: ShaderMaterial = item.material as ShaderMaterial
    if material == null or material.shader == null: return null
    for uniform: Dictionary in material.shader.get_shader_uniform_list():
        if str(uniform.get("name",""))==parameter:
            return material.get_shader_parameter(parameter)
    return null

func _motion_values(node: Node, values: Dictionary = {}) -> Dictionary:
    var key: String = str(node.get_path())
    if node is Node2D:
        values[key+":transform"] = (node as Node2D).transform
    if node is CanvasItem:
        for parameter: String in ["motion_time","clock"]:
            var value: Variant = _shader_time(node as CanvasItem,parameter)
            if value != null: values[key+":"+parameter] = value
    for child: Node in node.get_children():
        _motion_values(child,values)
    return values

func _collect_sprites(node: Node, output: Array[Sprite2D]) -> void:
    if node is Sprite2D: output.append(node as Sprite2D)
    for child: Node in node.get_children(): _collect_sprites(child,output)

func _covers_view(sprite: Sprite2D) -> bool:
    var rect: Rect2 = sprite.get_rect()
    var matrix: Transform2D = sprite.get_global_transform()
    return (matrix*rect.position).distance_to(VIEW_RECT.position)<0.1 and (matrix*rect.end).distance_to(VIEW_RECT.end)<0.1

func _finish() -> void:
    var untouched: bool = FileAccess.file_exists(NORMAL_SAVE)==normal_existed
    if normal_existed: untouched = untouched and FileAccess.get_file_as_bytes(NORMAL_SAVE)==normal_bytes
    check(untouched,"layer integration tests leave the normal save byte identical")
    print("ATMOSPHERE_TEST checks=",checks," failures=",failures)
    quit(1 if failures else 0)

func _run() -> void:
    normal_existed = FileAccess.file_exists(NORMAL_SAVE)
    if normal_existed: normal_bytes = FileAccess.get_file_as_bytes(NORMAL_SAVE)
    if not OS.get_cmdline_user_args().has("--capture"):
        check(false,"run layer integration tests with --capture")
        _finish()
        return
    if not _check_assets():
        _finish()
        return
    # Deferred compilation allows main.gd to resolve the DiaryState autoload.
    var harness: GDScript = GDScript.new()
    harness.source_code = "extends \"res://scripts/main.gd\"\nfunc _capture() -> void:\n    pass\nfunc _run_ui_smoke() -> void:\n    pass\n"
    if harness.reload()!=OK:
        check(false,"main scene harness compiles after autoload initialization")
        _finish()
        return
    var app: Control = load("res://main.tscn").instantiate()
    app.set_script(harness)
    root.add_child(app)
    app.set_process(false)
    app.scene_view.set_process(false)
    app.backdrop.set_process(false)
    var state: Node = root.get_node("DiaryState")
    state.set_process(false)
    await process_frame
    var stage: Node2D = app.backdrop
    var named_layers: bool = true
    var last_index: int = -1
    for layer: String in LAYERS:
        var node: Node = stage.get_node_or_null(layer)
        if not is_instance_valid(node) or node.get_index()<=last_index: named_layers = false
        if is_instance_valid(node): last_index = node.get_index()
    check(named_layers,"the actual scene contains twelve separately ordered scenery and effect layers")
    check(stage.get_node_or_null("AtmospherePainting")==null,"the old full canvas panorama sprite is absent")
    check(app.scene_view.layered_weather_enabled,"main world delegates weather drawing to the independent layers")
    var ready: Array[String] = stage.get_painted_atmosphere_ids()
    var all_ready: bool = true
    for id: String in IDS:
        if not ready.has(id): all_ready = false
    check(all_ready,"all ten events are available through the independent layer controller")
    if not named_layers or not all_ready:
        app.queue_free()
        _finish()
        return
    var foreground: Sprite2D = stage.get_node("Foreground") as Sprite2D
    var foreground_transform: Transform2D = foreground.transform
    var foreground_rect: Rect2 = foreground.get_rect()
    for layer: String in ["Mountains","TownShore","Tree","Foreground"]:
        var sprite: Sprite2D = stage.get_node(layer) as Sprite2D
        check(sprite != null and sprite.texture != null and _has_cutout(sprite.texture.get_image()),layer+" is a real transparent sprite rather than a flattened backdrop")
        check(sprite != null and _covers_view(sprite),layer+" uses its actual source dimensions to align with the viewing canvas")
    var clouds: Node = stage.get_node("FarClouds")
    var particles: Node = stage.get_node("NearRainSnow")
    var water: CanvasItem = stage.get_node("Water")
    var mist: CanvasItem = stage.get_node("FarMist")
    var tree: CanvasItem = stage.get_node("Tree")
    check(water is ColorRect and (water as ColorRect).size.is_equal_approx(VIEW_RECT.size),"water is an independent surface covering the viewing canvas")
    var layers_before: Dictionary = stage.get_layer_snapshot()
    var cloud_before: Array = clouds.get_cloud_positions().duplicate()
    var water_before: Variant = _shader_time(water,"clock")
    var mist_before: Variant = _shader_time(mist,"clock")
    var tree_before: Variant = _shader_time(tree,"clock")
    _advance(app,1.0)
    check(clouds.get_cloud_positions()!=cloud_before,"cloud positions actually move over time")
    check(water_before != null and _shader_time(water,"clock") != water_before,"water shader receives changing simulation time")
    check(mist_before != null and _shader_time(mist,"clock") != mist_before,"independent mist shader receives changing simulation time")
    check(tree_before != null and _shader_time(tree,"clock") != tree_before,"tree shader receives changing leaf motion time")
    for mode: int in range(8):
        app._change_weather(mode)
        _advance(app,3.0)
        var weights: Array = stage.get_weights()
        check(weights.size()==8 and float(weights[mode])>0.98,"weather %d converges across the independent layers" % mode)
    for mode: int in [1,4,6]:
        app._change_weather(mode)
        _advance(app,3.0)
        var positions: Array = particles.get_particle_positions().duplicate()
        _advance(app,0.75)
        check(not positions.is_empty() and particles.get_particle_positions()!=positions,"weather %d has moving rain or snow particles" % mode)
    check(stage.get_layer_snapshot().get("sky_top") != layers_before.get("sky_top"),"weather changes the actual sky palette")
    var controller: Node = stage.get_encounter_layers()
    for id: String in IDS:
        var before: int = int(state.collection.get(id,{}).get("count",0))
        app._demo_trigger(id)
        _advance(app,4.0)
        await process_frame
        var snapshot: Dictionary = stage.get_atmosphere_snapshot()
        var subject: Node2D = controller.get_event_node(id)
        check(str(snapshot.get("id",""))==id and float(snapshot.get("opacity",0.0))>0.9 and is_instance_valid(subject) and subject.is_visible_in_tree(),id+" has its own visible event node")
        check(int(state.collection.get(id,{}).get("count",0))==before+1,id+" is recorded exactly once")
        if id=="bioluminescent_tide":
            var tide: Variant = _shader_time(water,"blue_tide")
            check(tide != null and float(tide)>0.9,"blue tide activates its actual water shader effect")
        if not is_instance_valid(subject): continue
        # Blue tide is an animated mode of the independent water surface.
        var motion_node: Node = water if id=="bioluminescent_tide" else subject
        var motion_before: Dictionary = _motion_values(motion_node,{})
        var sprites: Array[Sprite2D] = []
        _collect_sprites(subject,sprites)
        var textures_present: bool = true
        var transparent_subject: bool = false
        for sprite: Sprite2D in sprites:
            if sprite.texture==null: textures_present = false
            elif _has_cutout(sprite.texture.get_image()): transparent_subject = true
        if id in TEXTURED_EVENTS:
            textures_present = textures_present and not sprites.is_empty() and transparent_subject
        check(textures_present,id+" uses loaded independent sprite parts when present")
        _advance(app,2.0)
        check(_motion_values(motion_node,{})!=motion_before,id+" changes a real transform or shader UV time after its entrance")
        check(foreground.transform.is_equal_approx(foreground_transform) and foreground.get_rect().is_equal_approx(foreground_rect),id+" leaves the foreground geometry fixed")
        check(is_equal_approx(float(app.scene_view.get_atmosphere_state().get("duration",0.0)),60.0),id+" retains the sixty second observation")
        _advance(app,52.0)
        snapshot = stage.get_atmosphere_snapshot()
        check(float(snapshot.get("opacity",0.0))>0.0 and float(snapshot.get("opacity",0.0))<1.0,id+" fades its independent layers near the end")
        _advance(app,7.0)
        snapshot = stage.get_atmosphere_snapshot()
        check(app.scene_view.get_atmosphere_state().is_empty() and float(snapshot.get("opacity",0.0))<0.01,id+" removes its event layers after playback")
        if id=="bioluminescent_tide":
            check(float(_shader_time(water,"blue_tide"))<0.01,"blue tide releases the water shader when the event ends")
        before = int(state.collection[id]["count"])
        app._replay(id)
        _advance(app,4.0)
        check(stage.get_active_atmosphere_id()==id and int(state.collection[id]["count"])==before,id+" replay animates without another observation")
        app._change_weather(0)
        _advance(app,5.0)
    var bounded: bool = true
    for id: String in ["aurora_crown","twin_moons","meteor_shower","sunken_city","sky_jellyfish","constellation_stag"]:
        app._demo_trigger(id)
        _advance(app,0.8)
        if int(stage.get_atmosphere_snapshot().get("layer_count",0))>3: bounded = false
    _advance(app,4.0)
    check(bounded and stage.get_active_atmosphere_id()=="constellation_stag","rapid event switches remain bounded and settle on the latest subject")
    app._change_weather(5)
    _advance(app,5.0)
    check(app.scene_view.get_atmosphere_state().is_empty() and stage.get_active_atmosphere_id().is_empty(),"changing weather retires event layers without reviving older subjects")
    var quiet_before: int = int(state.collection.get("deep_one",{}).get("count",0))
    app._start_focus()
    app._demo_trigger("aurora_crown")
    _advance(app,4.0)
    check(stage.get_active_atmosphere_id()=="aurora_crown","gentle independent event layers remain available in quiet focus")
    app.scene_view.trigger("deep_one")
    _advance(app,5.0)
    check(int(state.collection["deep_one"]["count"])==quiet_before+1 and app.scene_view.get_atmosphere_state().is_empty() and float(stage.get_atmosphere_snapshot().get("opacity",0.0))<0.01,"quiet deep-water encounter records without showing the creature")
    check(not app.toast_panel.visible,"quiet discovery does not interrupt with a popup")
    app._end_focus()
    app.scene_view.clear_atmosphere_events()
    app._replay("deep_one")
    _advance(app,4.0)
    check(stage.get_active_atmosphere_id()=="deep_one" and int(state.collection["deep_one"]["count"])==quiet_before+1,"the quietly collected creature can animate later without another count")
    check(foreground.transform.is_equal_approx(foreground_transform),"foreground placement survives weather event and quiet-mode changes")
    app.queue_free()
    await process_frame
    _finish()
