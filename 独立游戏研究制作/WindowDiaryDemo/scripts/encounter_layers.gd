extends Node2D
## Transparent, independently animated encounter subjects. WeatherStage owns
## the fixed terrain and supplies separate sky/water hosts for correct depth.
signal ready_ids_changed(ids: Array[String])

const IDS: Array[String] = ["aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const NODE_NAMES: Dictionary = {
    "aurora_crown":"AuroraCrown", "ember_clouds":"EmberClouds", "meteor_shower":"MeteorShower",
    "deep_one":"DeepOne", "sunken_city":"SunkenCity", "sky_jellyfish":"SkyJellyfish",
    "twin_moons":"TwinMoons", "floating_isles":"FloatingIsles", "bioluminescent_tide":"BioluminescentTide", "constellation_stag":"ConstellationStag"
}
const REQUIRED_ART: Dictionary = {
    "ember_clouds":"cloud", "deep_one":"deep_one", "sunken_city":"sunken_city",
    "sky_jellyfish":"jellyfish", "twin_moons":"moon", "floating_isles":"island", "constellation_stag":"stag"
}
const ART_DIR: String = "res://assets/art/layers_v1/"
const DEFORM: Shader = preload("res://shaders/encounter_deform.gdshader")
const LIGHT: Shader = preload("res://shaders/encounter_light.gdshader")

var _sky_root: Node2D
var _water_root: Node2D
var _nodes: Dictionary = {}
var _textures: Dictionary = {}
var _ready_ids: Array[String] = []
var _layers: Array[Dictionary] = []
var _requested_id: String = ""
var _last_id: String = ""
var _quiet: bool = false
var _clock: float = 0.0
var _scan_age: float = 0.0
var _meteor_count: int = 0
var _meteor_wait: float = 0.25
var _meteors: Array[Node2D] = []

func _ready() -> void:
    _sky_root = get_node("SkyRoot")
    _water_root = get_node("WaterRoot")
    for id in IDS:
        var host: Node2D = _water_root if id in ["sunken_city", "bioluminescent_tide"] else _sky_root
        var event_node: Node2D = host.get_node(str(NODE_NAMES[id]))
        event_node.visible = false
        event_node.set_meta("event_id", id)
        _nodes[id] = event_node
    reload_assets()

func setup(sky_host: Node2D, water_host: Node2D) -> void:
    if is_instance_valid(_sky_root) and _sky_root.get_parent() != sky_host:
        _sky_root.reparent(sky_host, false)
    if is_instance_valid(_water_root) and _water_root.get_parent() != water_host:
        _water_root.reparent(water_host, false)

func _exit_tree() -> void:
    # After setup the drawing subtrees belong to the depth hosts, while this
    # controller still owns their lifecycle.
    for node in [_sky_root, _water_root]:
        if is_instance_valid(node) and node.get_parent() != self and not node.is_queued_for_deletion():
            node.queue_free()

func reload_assets() -> Array[String]:
    for art in REQUIRED_ART.values():
        var key: String = str(art)
        if _textures.has(key):continue
        var path: String = ART_DIR + key + ".png"
        var texture: Texture2D
        if ResourceLoader.exists(path):
            texture = load(path) as Texture2D
        elif FileAccess.file_exists(path):
            var source: Image = Image.load_from_file(path)
            if source != null and not source.is_empty():
                texture = ImageTexture.create_from_image(source)
        if texture != null:
            _textures[key] = texture
    var changed: bool = false
    for id in IDS:
        if _ready_ids.has(id):continue
        if REQUIRED_ART.has(id) and not _textures.has(str(REQUIRED_ART[id])):continue
        _build_event(id)
        _ready_ids.append(id)
        changed = true
    if changed:ready_ids_changed.emit(get_ready_ids())
    return get_ready_ids()

func get_ready_ids() -> Array[String]:
    return _ready_ids.duplicate()

func get_event_node(id: String) -> Node2D:
    return _nodes.get(id) as Node2D

func set_quiet(value: bool) -> void:
    _quiet = value
    if not value:return
    for index in range(_layers.size() - 1, -1, -1):
        if str(_layers[index]["id"]) == "deep_one":
            _layers.remove_at(index)
    if _nodes.has("deep_one"):_nodes["deep_one"].visible = false
    if _requested_id == "deep_one":_requested_id = ""

func set_atmosphere_state(state: Dictionary) -> void:
    var id: String = str(state.get("id", ""))
    if state.has("quiet"):set_quiet(bool(state["quiet"]))
    if id not in IDS or (_quiet and id == "deep_one"):id = ""
    if id != _requested_id:
        for layer in _layers:
            if str(layer["id"]) != id and not bool(layer["leaving"]):
                layer["leaving"] = true
                layer["exit_age"] = 0.0
                layer["exit_weight"] = float(layer["weight"])
        _requested_id = id
    if id.is_empty():return
    _last_id = id
    for layer in _layers:
        if str(layer["id"]) != id:continue
        layer["age"] = maxf(0.0, float(state.get("age", layer["age"])))
        layer["duration"] = maxf(7.0, float(state.get("duration", 60.0)))
        layer["leaving"] = false
        return
    # Rapid switches have a strict, bounded cost. Removed subjects stop drawing.
    while _layers.size() >= 3:
        var removed: Dictionary = _layers.pop_front()
        _nodes[str(removed["id"])].visible = false
    var age: float = maxf(0.0, float(state.get("age", 0.0)))
    _layers.append({"id":id, "age":age, "duration":maxf(7.0, float(state.get("duration", 60.0))),
        "motion_age":age, "weight":0.0, "leaving":false, "exit_age":0.0, "exit_weight":0.0})

func _process(delta: float) -> void:
    _clock += delta
    _scan_age += delta
    if _scan_age >= 3.0:
        _scan_age = 0.0
        if _ready_ids.size() < IDS.size():reload_assets()
    for id in _nodes:_nodes[id].visible = false
    for index in range(_layers.size() - 1, -1, -1):
        var layer: Dictionary = _layers[index]
        var id: String = str(layer["id"])
        layer["age"] = float(layer["age"]) + delta
        layer["motion_age"] = float(layer["motion_age"]) + delta * (0.42 if _quiet else 1.0)
        var age: float = float(layer["age"])
        var duration: float = float(layer["duration"])
        var weight: float = minf(smoothstep(0.0, 3.0, age), 1.0 - smoothstep(duration - 4.0, duration, age))
        if bool(layer["leaving"]):
            layer["exit_age"] = float(layer["exit_age"]) + delta
            weight = float(layer["exit_weight"]) * (1.0 - smoothstep(0.0, 4.0, float(layer["exit_age"])))
        if not _ready_ids.has(id) or (_quiet and id == "deep_one"):weight = 0.0
        layer["weight"] = weight
        var event_node: Node2D = _nodes[id]
        event_node.modulate.a = weight
        event_node.visible = weight > 0.001
        if event_node.visible:_animate_event(id, float(layer["motion_age"]), age)
        if age >= duration or (bool(layer["leaving"]) and float(layer["exit_age"]) >= 4.0):
            event_node.visible = false
            _layers.remove_at(index)
    _step_meteors(delta)
    if _layers.is_empty():_last_id = ""

func get_snapshot() -> Dictionary:
    var weights: Dictionary = {}
    var age: float = 0.0
    var duration: float = 60.0
    var opacity: float = 0.0
    for layer in _layers:
        var id: String = str(layer["id"])
        var weight: float = float(layer["weight"])
        if weight > 0.001:weights[id] = weight
        opacity += weight
        if id == _last_id:
            age = float(layer["age"])
            duration = float(layer["duration"])
    return {"id":_last_id, "requested_id":_requested_id, "age":age, "duration":duration,
        "quiet":_quiet, "weights":weights, "opacity":clampf(opacity, 0.0, 1.0),
        "ready_ids":get_ready_ids(), "layer_count":_layers.size(), "meteor_count":_meteors.size()}

func _sprite(host: Node2D, name_value: String, art: String, bounds: Rect2, kind: int = -1) -> Sprite2D:
    var node: Sprite2D = Sprite2D.new()
    node.name = name_value
    node.texture = _textures[art]
    node.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    var fit: float = minf(bounds.size.x / node.texture.get_width(), bounds.size.y / node.texture.get_height())
    node.scale = Vector2.ONE * fit
    node.position = bounds.get_center()
    node.set_meta("base_position", node.position)
    node.set_meta("base_scale", node.scale)
    node.set_meta("part_kind", art)
    if kind >= 0:
        var material_value: ShaderMaterial = ShaderMaterial.new()
        material_value.shader = DEFORM
        material_value.set_shader_parameter("subject_kind", kind)
        material_value.set_shader_parameter("seed", float(host.get_child_count()) * 1.7)
        node.material = material_value
    host.add_child(node)
    return node

func _light(host: Node2D, name_value: String, bounds: Rect2, kind: int, color: Color) -> ColorRect:
    var node: ColorRect = ColorRect.new()
    node.name = name_value
    node.position = bounds.position
    node.size = bounds.size
    node.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var material_value: ShaderMaterial = ShaderMaterial.new()
    material_value.shader = LIGHT
    material_value.set_shader_parameter("effect_kind", kind)
    material_value.set_shader_parameter("light_color", color)
    node.material = material_value
    node.set_meta("base_position", node.position)
    host.add_child(node)
    return node

func _build_event(id: String) -> void:
    var host: Node2D = _nodes[id]
    match id:
        "aurora_crown":
            _light(host, "FlowingCurtains", Rect2(360, 0, 980, 330), 0, Color("9bdec8"))
        "ember_clouds":
            for index in range(3):
                var cloud: Sprite2D = _sprite(host, "WarmCloud%d" % index, "cloud", Rect2(390 + index * 235, 30 + index % 2 * 78, 540, 165), 0)
                cloud.modulate = Color(1.0, 0.65 + index * 0.05, 0.50 + index * 0.07, 0.48)
        "deep_one":
            var giant: Sprite2D = _sprite(host, "RisingAncient", "deep_one", Rect2(470, 42, 760, 360), 1)
            giant.modulate = Color(0.64, 0.82, 0.78, 0.80)
        "sunken_city":
            _sprite(host, "RisingRuins", "sunken_city", Rect2(475, 425, 360, 166), 4)
            _light(host, "FoundationMist", Rect2(470, 524, 370, 70), 3, Color("aecac4"))
            _light(host, "FoundationRipples", Rect2(490, 552, 345, 42), 4, Color("accdc7"))
        "sky_jellyfish":
            var bounds: Array[Rect2] = [Rect2(580, 85, 150, 113), Rect2(830, 20, 210, 158), Rect2(1070, 145, 100, 75), Rect2(735, 155, 90, 68)]
            for index in range(bounds.size()):
                var jelly: Sprite2D = _sprite(host, "Jellyfish%d" % index, "jellyfish", bounds[index], 2)
                jelly.modulate = Color(0.81 + index * 0.04, 0.86, 1.0, 0.88)
        "twin_moons":
            _light(host, "NearMoonGlow", Rect2(733, 30, 230, 230), 2, Color("c4d9ed"))
            _light(host, "FarMoonGlow", Rect2(951, 82, 176, 176), 2, Color("e1d8eb"))
            _sprite(host, "NearMoon", "moon", Rect2(795, 92, 106, 106))
            var moon: Sprite2D = _sprite(host, "FarMoon", "moon", Rect2(1003, 134, 72, 72))
            moon.modulate = Color(0.83, 0.80, 0.95, 0.82)
        "floating_isles":
            var bounds: Array[Rect2] = [Rect2(615, 25, 280, 183), Rect2(944, 30, 190, 130), Rect2(1090, 135, 110, 80)]
            for index in range(bounds.size()):
                var island: Sprite2D = _sprite(host, "Island%d" % index, "island", bounds[index])
                island.modulate = Color(1.0 - index * 0.06, 1.0, 0.95, 1.0 - index * 0.08)
                var visible_size: Vector2 = island.texture.get_size() * island.scale
                var fall_pos: Vector2 = island.position - visible_size * 0.5 + visible_size * Vector2(0.35, 0.48)
                _light(host, "Waterfall%d" % index, Rect2(fall_pos, Vector2(12 - index * 2, 100 - index * 20)), 1, Color("c0e4dc"))
        "constellation_stag":
            var stag: Sprite2D = _sprite(host, "WalkingStag", "stag", Rect2(690, 25, 310, 215), 3)
            stag.modulate = Color(1.0, 0.93, 0.76, 0.93)
        # Meteors are actual short-lived nodes. Blue tide is intentionally an
        # empty named water event: WeatherStage animates its existing river UVs.
        "meteor_shower", "bioluminescent_tide":pass

func _animate_event(id: String, t: float, age: float) -> void:
    var host: Node2D = _nodes[id]
    var amount: float = 0.40 if _quiet else 1.0
    for index in range(host.get_child_count()):
        var child: CanvasItem = host.get_child(index) as CanvasItem
        if child == null:continue
        if child.material is ShaderMaterial:
            child.material.set_shader_parameter("motion_time", t)
            child.material.set_shader_parameter("motion_amount", amount)
        if not child.has_meta("base_position"):continue
        var base: Vector2 = child.get_meta("base_position")
        var phase: float = float(index) * 1.7
        match id:
            "ember_clouds":
                child.position = base + Vector2(sin(t * 0.055 + phase) * 65, sin(t * 0.12 + phase) * 7) * amount
                child.scale = (child.get_meta("base_scale") as Vector2) * Vector2(1.0 + sin(t * 0.13 + phase) * 0.025, 1.0 + sin(t * 0.2 + phase) * 0.07)
            "deep_one":
                child.position = base + Vector2(sin(t * 0.10) * 6 * amount, (1.0 - smoothstep(0.0, 13.0, age)) * 145 + sin(t * 0.16) * 3 * amount)
            "sunken_city":
                if child is Sprite2D:
                    child.position = base + Vector2(0, (1.0 - smoothstep(0.0, 12.0, age)) * 100 + sin(t * 0.16) * 1.2 * amount)
            "sky_jellyfish":
                child.position = base + Vector2(sin(t * 0.12 + phase) * 30, sin(t * 0.24 + phase) * 20) * amount
                child.scale = (child.get_meta("base_scale") as Vector2) * Vector2(1.0 + sin(t * 1.1 + phase) * 0.055 * amount, 1.0 - sin(t * 1.1 + phase) * 0.070 * amount)
            "twin_moons":
                child.position = base + Vector2(sin(t * 0.045) * 5, (1.0 - smoothstep(0.0, 12.0, age)) * 25 + sin(t * 0.09) * 3) * amount
            "floating_isles":
                # Each fall shares its island's slow drift.
                phase = float(index / 2) * 1.7
                child.position = base + Vector2(sin(t * 0.11 + phase) * 18, sin(t * 0.20 + phase) * 10) * amount
            "constellation_stag":
                child.position = base + Vector2(sin(t * 0.045) * 52, sin(t * 1.1) * 2) * amount
                child.modulate.a = 0.87 + sin(t * 0.72) * 0.06 * amount

func _step_meteors(delta: float) -> void:
    var host: Node2D = _nodes.get("meteor_shower") as Node2D
    if host == null:return
    for index in range(_meteors.size() - 1, -1, -1):
        var meteor: Node2D = _meteors[index]
        var age: float = float(meteor.get_meta("age")) + delta
        var lifetime: float = float(meteor.get_meta("lifetime"))
        meteor.set_meta("age", age)
        meteor.position += (meteor.get_meta("velocity") as Vector2) * delta * (0.55 if _quiet else 1.0)
        meteor.modulate.a = sin(clampf(age / lifetime, 0, 1) * PI) * (0.50 if _quiet else 0.9)
        if age >= lifetime or not host.visible:
            meteor.queue_free()
            _meteors.remove_at(index)
    if not host.visible:
        _meteor_wait = 0.25
        return
    _meteor_wait -= delta
    if _meteor_wait > 0.0:return
    _meteor_wait = 4.8 if _quiet else 0.72
    if _meteors.size() >= 8:return
    var meteor: Node2D = Node2D.new()
    meteor.name = "Meteor%d" % _meteor_count
    meteor.position = Vector2(460 + fmod(_meteor_count * 173.0, 680.0), 24 + fmod(_meteor_count * 47.0, 116.0))
    meteor.set_meta("age", 0.0)
    meteor.set_meta("lifetime", 2.2)
    meteor.set_meta("velocity", Vector2(185 + _meteor_count % 3 * 27, 103 + _meteor_count % 2 * 16))
    meteor.set_meta("part_kind", "meteor")
    var trail: Line2D = Line2D.new()
    trail.name = "MovingTrail"
    trail.points = PackedVector2Array([Vector2(-58, -31), Vector2.ZERO])
    trail.width = 2.4
    var colors: Gradient = Gradient.new()
    colors.set_color(0, Color(0.66, 0.79, 0.96, 0.0))
    colors.set_color(1, Color(0.92, 0.95, 1.0, 0.95))
    trail.gradient = colors
    var width_curve: Curve = Curve.new()
    width_curve.add_point(Vector2(0, 0.04))
    width_curve.add_point(Vector2(1, 1))
    trail.width_curve = width_curve
    meteor.add_child(trail)
    var head: Polygon2D = Polygon2D.new()
    head.name = "BrightHead"
    head.polygon = PackedVector2Array([Vector2(0, -2), Vector2(3, 0), Vector2(0, 2), Vector2(-2, 0)])
    head.color = Color("f4f2df")
    meteor.add_child(head)
    host.add_child(meteor)
    _meteors.append(meteor)
    _meteor_count += 1
