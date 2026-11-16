@tool
extends Node2D
## Actual scene layers: geometry never changes when the weather or an encounter changes.
signal painted_atmospheres_changed(ids: Array[String])
const TRANSITION_SECONDS: float=2.0
const PAINTING_SIZE: Vector2i=Vector2i(1440,810)
const LAYER_NAMES: Array[String]=["Sky","Stars","FarClouds","EventSky","Mountains","FarMist","Water","EventWater","TownShore","Tree","NearRainSnow","Foreground"]
const ATMOSPHERE_IDS: Array[String]=["aurora_crown","ember_clouds","meteor_shower","deep_one","sunken_city","sky_jellyfish","twin_moons","floating_isles","bioluminescent_tide","constellation_stag"]
const TERRAIN_ASSETS: Dictionary={"Mountains":"mountains","TownShore":"town_shore","Tree":"tree","Foreground":"foreground"}
const WEATHER_ENV: Array[Dictionary]=[
 {"sky_top":Color("94c2d8"),"sky_bottom":Color("d5e0d4"),"water":Color("68a8b4"),"tint":Color("fff6e6"),"cloud_color":Color("eeeada"),"glow_color":Color("f1dda8"),"mist":0.04,"rain":0.0,"snow":0.0,"snow_cover":0.0,"stars":0.0,"moon":0.0,"sun":0.8,"sun_low":0.0,"cloud":0.76,"wind":0.3,"glow":0.12,"reflection":0.26,"lightning":0.0},
 {"sky_top":Color("758e9e"),"sky_bottom":Color("a7b7bc"),"water":Color("6b909c"),"tint":Color("9cabb2"),"cloud_color":Color("a9bbc1"),"glow_color":Color("c2d1cf"),"mist":0.32,"rain":0.62,"snow":0.0,"snow_cover":0.0,"stars":0.0,"moon":0.0,"sun":0.0,"sun_low":0.0,"cloud":0.86,"wind":0.7,"glow":0.03,"reflection":0.12,"lightning":0.0},
 {"sky_top":Color("192c48"),"sky_bottom":Color("435a70"),"water":Color("385671"),"tint":Color("6d8099"),"cloud_color":Color("657d96"),"glow_color":Color("a1b9bb"),"mist":0.10,"rain":0.0,"snow":0.0,"snow_cover":0.0,"stars":0.94,"moon":0.88,"sun":0.0,"sun_low":0.0,"cloud":0.35,"wind":0.2,"glow":0.04,"reflection":0.52,"lightning":0.0},
 {"sky_top":Color("b591a1"),"sky_bottom":Color("e4bea1"),"water":Color("a28495"),"tint":Color("dab9ae"),"cloud_color":Color("e8c9b4"),"glow_color":Color("f1c996"),"mist":0.10,"rain":0.0,"snow":0.0,"snow_cover":0.0,"stars":0.04,"moon":0.0,"sun":0.65,"sun_low":0.8,"cloud":0.55,"wind":0.24,"glow":0.45,"reflection":0.6,"lightning":0.0},
 {"sky_top":Color("b9cbd5"),"sky_bottom":Color("e4e7df"),"water":Color("9bbac7"),"tint":Color("cfdbdf"),"cloud_color":Color("e2e6df"),"glow_color":Color("e6eadc"),"mist":0.23,"rain":0.0,"snow":1.0,"snow_cover":1.0,"stars":0.0,"moon":0.0,"sun":0.0,"sun_low":0.0,"cloud":0.65,"wind":0.42,"glow":0.05,"reflection":0.16,"lightning":0.0},
 {"sky_top":Color("b4c8c2"),"sky_bottom":Color("d3ded4"),"water":Color("a4bfb8"),"tint":Color("b8cbc4"),"cloud_color":Color("c7d5cc"),"glow_color":Color("e0e3cd"),"mist":0.78,"rain":0.0,"snow":0.0,"snow_cover":0.0,"stars":0.0,"moon":0.0,"sun":0.0,"sun_low":0.0,"cloud":0.25,"wind":0.12,"glow":0.09,"reflection":0.12,"lightning":0.0},
 {"sky_top":Color("344c62"),"sky_bottom":Color("718593"),"water":Color("46677e"),"tint":Color("81949f"),"cloud_color":Color("788c9e"),"glow_color":Color("b9c4c7"),"mist":0.35,"rain":1.0,"snow":0.0,"snow_cover":0.0,"stars":0.0,"moon":0.0,"sun":0.0,"sun_low":0.0,"cloud":0.95,"wind":1.5,"glow":0.02,"reflection":0.14,"lightning":1.0},
 {"sky_top":Color("97a9c0"),"sky_bottom":Color("e9d4b4"),"water":Color("a1b8b7"),"tint":Color("e1d8c3"),"cloud_color":Color("e3ddcd"),"glow_color":Color("f3dcac"),"mist":0.34,"rain":0.0,"snow":0.0,"snow_cover":0.0,"stars":0.16,"moon":0.08,"sun":0.5,"sun_low":1.0,"cloud":0.46,"wind":0.17,"glow":0.37,"reflection":0.53,"lightning":0.0}
]
const ATMOSPHERE_ENV: Dictionary={
 "aurora_crown":{"sky_top":Color("18243e"),"sky_bottom":Color("52777e"),"water":Color("376d78"),"tint":Color("8398ad"),"cloud_color":Color("7b969f"),"glow_color":Color("a7cbb2"),"stars":1.0,"moon":0.0,"sun":0.0,"cloud":0.2,"mist":0.16,"glow":0.25,"reflection":0.7},
 "ember_clouds":{"sky_top":Color("946878"),"sky_bottom":Color("e7a685"),"water":Color("b58a79"),"tint":Color("e1ad96"),"cloud_color":Color("e9b695"),"glow_color":Color("f4cb91"),"stars":0.08,"moon":0.0,"sun":0.0,"cloud":0.36,"mist":0.13,"glow":0.6,"reflection":0.86},
 "meteor_shower":{"sky_top":Color("10213c"),"sky_bottom":Color("3a536d"),"water":Color("304e6a"),"tint":Color("687d98"),"cloud_color":Color("637c94"),"glow_color":Color("b5c9cd"),"stars":1.0,"moon":0.0,"sun":0.0,"cloud":0.10,"mist":0.06,"glow":0.06,"reflection":0.45},
 "deep_one":{"sky_top":Color("183b3d"),"sky_bottom":Color("547976"),"water":Color("295657"),"tint":Color("678d80"),"cloud_color":Color("7f9b8c"),"glow_color":Color("a7baa1"),"stars":0.15,"moon":0.0,"sun":0.0,"cloud":0.48,"mist":0.43,"glow":0.13,"reflection":0.23},
 "sunken_city":{"sky_top":Color("7e9b98"),"sky_bottom":Color("bfd1bc"),"water":Color("709d96"),"tint":Color("a5beb0"),"cloud_color":Color("c1d0bc"),"glow_color":Color("dfdfb8"),"stars":0.08,"moon":0.0,"sun":0.0,"cloud":0.28,"mist":0.7,"glow":0.27,"reflection":0.56},
 "sky_jellyfish":{"sky_top":Color("292944"),"sky_bottom":Color("777d9a"),"water":Color("596b93"),"tint":Color("9297bc"),"cloud_color":Color("9d9cba"),"glow_color":Color("c5c0d7"),"stars":0.9,"moon":0.0,"sun":0.0,"cloud":0.16,"mist":0.24,"glow":0.24,"reflection":0.7},
 "twin_moons":{"sky_top":Color("1c304c"),"sky_bottom":Color("6d8ba0"),"water":Color("567d98"),"tint":Color("95abc1"),"cloud_color":Color("9aacbc"),"glow_color":Color("dde2cf"),"stars":0.75,"moon":0.0,"sun":0.0,"cloud":0.12,"mist":0.16,"glow":0.22,"reflection":0.84},
 "floating_isles":{"sky_top":Color("80b7b7"),"sky_bottom":Color("dce0b7"),"water":Color("83b6ad"),"tint":Color("c8d4ab"),"cloud_color":Color("e5e8cc"),"glow_color":Color("f2e3ad"),"stars":0.04,"moon":0.0,"sun":0.0,"cloud":0.48,"mist":0.18,"glow":0.37,"reflection":0.48},
 "bioluminescent_tide":{"sky_top":Color("142b45"),"sky_bottom":Color("3f717e"),"water":Color("265b72"),"tint":Color("6e9ca9"),"cloud_color":Color("7196a3"),"glow_color":Color("9ccfc6"),"stars":0.77,"moon":0.0,"sun":0.0,"cloud":0.18,"mist":0.14,"glow":0.15,"reflection":0.5},
 "constellation_stag":{"sky_top":Color("203c45"),"sky_bottom":Color("7b9c8c"),"water":Color("557f7d"),"tint":Color("9bb29a"),"cloud_color":Color("acbea4"),"glow_color":Color("e3dfb0"),"stars":0.94,"moon":0.0,"sun":0.0,"cloud":0.12,"mist":0.2,"glow":0.27,"reflection":0.67}
}
@export_range(0,7) var weather: int=0
var _weights: Array[float]=[1.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
var _weather_from: Array[float]=[]
var _weather_elapsed: float=TRANSITION_SECONDS
var _target_weather: int=0
var _clock: float=0.0
var _asset_clock: float=0.0
var _asset_mtimes: Dictionary={}
var _asset_ids: Array[String]=[]
var _encounters: Node
var _last_state: Dictionary={}
var _ready_ids: Array[String]=[]
var _environment: Dictionary={}
var _quiet: bool=false
var _manual_quiet: bool=false

func _ready() -> void:
    _refresh_assets()
    _install_encounters()
    set_weather(weather,true)
    _enable_world_layering.call_deferred()

func _enable_world_layering() -> void:
    if Engine.is_editor_hint():return
    var world: Node=get_parent().get_node_or_null("World") if get_parent()!=null else null
    if is_instance_valid(world) and world.has_method("set_layered_weather_enabled"):world.set_layered_weather_enabled(true)

func _install_encounters() -> void:
    if Engine.is_editor_hint():return
    if is_instance_valid(_encounters):return
    var path: String="res://scenes/encounter_layers.tscn"
    if not ResourceLoader.exists(path):return
    var scene: PackedScene=ResourceLoader.load(path) as PackedScene
    if scene==null:return
    _encounters=scene.instantiate()
    _encounters.name="EncounterLayers"
    add_child(_encounters)
    _encounters.setup($EventSky,$EventWater)
    _encounters.set_process(false)
    if _encounters.has_signal("ready_ids_changed"):_encounters.connect("ready_ids_changed",_on_event_assets_ready)
    _encounters.set_atmosphere_state(_last_state)
    _on_event_assets_ready(_encounters.get_ready_ids())

func _on_event_assets_ready(ids: Array[String]) -> void:
    if ids==_ready_ids:return
    _ready_ids=ids.duplicate()
    painted_atmospheres_changed.emit(_ready_ids)

func _load_texture(path: String) -> Texture2D:
    if ResourceLoader.exists(path) and (FileAccess.file_exists(path+".import") or not FileAccess.file_exists(path)):
        return ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_REPLACE) as Texture2D
    if FileAccess.file_exists(path):
        var bitmap: Image=Image.load_from_file(path)
        if bitmap!=null and not bitmap.is_empty():return ImageTexture.create_from_image(bitmap)
    elif ResourceLoader.exists(path):return ResourceLoader.load(path) as Texture2D
    return null

func _refresh_assets(force: bool=false) -> void:
    for node_name: String in TERRAIN_ASSETS:
        var id: String=str(TERRAIN_ASSETS[node_name])
        var path: String="res://assets/art/layers_v1/"+id+".png"
        var stamp: int=int(FileAccess.get_modified_time(path)) if FileAccess.file_exists(path) else 0
        if not force and _asset_mtimes.get(id,-1)==stamp:continue
        var texture: Texture2D=_load_texture(path)
        if texture==null:continue
        var sprite: Sprite2D=get_node(node_name) as Sprite2D
        sprite.texture=texture
        sprite.position=Vector2.ZERO
        sprite.scale=Vector2(1440.0/texture.get_width(),810.0/texture.get_height())
        sprite.set_meta("asset_path",path)
        _asset_mtimes[id]=stamp
        if id not in _asset_ids:_asset_ids.append(id)
    for id: String in ["cloud","water"]:
        var path: String="res://assets/art/layers_v1/"+id+".png"
        var stamp: int=int(FileAccess.get_modified_time(path)) if FileAccess.file_exists(path) else 0
        if not force and _asset_mtimes.get(id,-1)==stamp:continue
        var texture: Texture2D=_load_texture(path)
        if texture==null:continue
        if id=="cloud":$FarClouds.cloud_texture=texture
        else:
            $Water.material.set_shader_parameter("water_tile",texture)
            $Water.material.set_shader_parameter("tile_amount",1.0)
        _asset_mtimes[id]=stamp
        if id not in _asset_ids:_asset_ids.append(id)

func reload_atmosphere_art() -> Array[String]:
    _refresh_assets(true)
    _install_encounters()
    if is_instance_valid(_encounters):
        _encounters.reload_assets()
        _on_event_assets_ready(_encounters.get_ready_ids())
    return get_painted_atmosphere_ids()

func get_painted_atmosphere_ids() -> Array[String]:
    return _ready_ids.duplicate()

func get_encounter_layers() -> Node:
    return _encounters

func set_weather(mode: int,immediate: bool=false) -> void:
    weather=clampi(mode,0,7)
    _target_weather=weather
    _weather_from=_weights.duplicate()
    _weather_elapsed=TRANSITION_SECONDS if immediate else 0.0
    if immediate:
        for i in range(8):_weights[i]=1.0 if i==weather else 0.0
    if is_inside_tree():_apply_environment()

func get_weights() -> Array[float]:
    return _weights.duplicate()

func set_quiet(value: bool) -> void:
    _manual_quiet=value
    _sync_quiet()

func _sync_quiet() -> void:
    var world: Node=get_parent().get_node_or_null("World") if get_parent()!=null else null
    _quiet=_manual_quiet or bool(_last_state.get("quiet",false))
    if is_instance_valid(world) and not Engine.is_editor_hint():_quiet=_quiet or bool(world.get("quiet"))
    if is_instance_valid(_encounters) and _encounters.has_method("set_quiet"):_encounters.set_quiet(_quiet)

func set_atmosphere_state(state: Dictionary) -> void:
    _last_state=state.duplicate()
    _sync_quiet()
    if is_instance_valid(_encounters):_encounters.set_atmosphere_state(state)

func _process(delta: float) -> void:
    if not is_inside_tree():return
    if weather!=_target_weather:set_weather(weather,Engine.is_editor_hint())
    _sync_quiet()
    _clock+=delta*(0.55 if _quiet else 1.0)
    _asset_clock+=delta
    if _asset_clock>=2.5:
        _asset_clock=0.0
        _refresh_assets()
        _install_encounters()
        if is_instance_valid(_encounters):
            _encounters.reload_assets()
            _on_event_assets_ready(_encounters.get_ready_ids())
    if _weather_elapsed<TRANSITION_SECONDS:
        _weather_elapsed=minf(TRANSITION_SECONDS,_weather_elapsed+delta)
        var t: float=smoothstep(0.0,1.0,_weather_elapsed/TRANSITION_SECONDS)
        for i in range(8):_weights[i]=lerpf(_weather_from[i],1.0 if i==_target_weather else 0.0,t)
    if is_instance_valid(_encounters):_encounters._process(delta)
    _apply_environment()
    for name_text: String in ["Stars","FarClouds","NearRainSnow"]:
        get_node(name_text).advance(delta)

func _encounter_snapshot() -> Dictionary:
    return _encounters.get_snapshot() if is_instance_valid(_encounters) else {}

func _event_weights() -> Dictionary:
    return _encounter_snapshot().get("weights",{})

func _apply_environment() -> void:
    var env: Dictionary={}
    for key: String in WEATHER_ENV[0]:
        if WEATHER_ENV[0][key] is Color:
            var color: Color=Color(0,0,0,0)
            for i in range(8):color+=WEATHER_ENV[i][key]*_weights[i]
            env[key]=color
        else:
            var value: float=0.0
            for i in range(8):value+=float(WEATHER_ENV[i][key])*_weights[i]
            env[key]=value
    var event_weights: Dictionary=_event_weights()
    var total: float=0.0
    for weight: Variant in event_weights.values():total+=float(weight)
    var normalized: float=1.0/maxf(1.0,total)
    for key: String in env:
        var base: Variant=env[key]
        var blended: Variant=base*(1.0-minf(1.0,total))
        for id: String in event_weights:
            var target: Variant=ATMOSPHERE_ENV.get(id,{}).get(key,base)
            blended+=target*float(event_weights[id])*normalized
        env[key]=blended
    _environment=env
    var sky: ShaderMaterial=$Sky.material as ShaderMaterial
    for key: String in ["sky_top","sky_bottom","glow_color","glow"]:sky.set_shader_parameter(key,env[key])
    sky.set_shader_parameter("clock",_clock)
    var water: ShaderMaterial=$Water.material as ShaderMaterial
    water.set_shader_parameter("clock",_clock)
    water.set_shader_parameter("water_color",env.water)
    water.set_shader_parameter("reflection_color",env.glow_color)
    water.set_shader_parameter("reflection_strength",env.reflection)
    water.set_shader_parameter("rain_strength",env.rain)
    water.set_shader_parameter("wind_strength",env.wind)
    water.set_shader_parameter("blue_tide",float(event_weights.get("bioluminescent_tide",0.0))*normalized)
    water.set_shader_parameter("gold_tide",(float(event_weights.get("ember_clouds",0.0))*0.95+float(event_weights.get("floating_isles",0.0))*0.3)*normalized)
    var mist: ShaderMaterial=$FarMist.material as ShaderMaterial
    mist.set_shader_parameter("clock",_clock)
    mist.set_shader_parameter("density",env.mist)
    mist.set_shader_parameter("mist_color",env.sky_bottom)
    for node_name: String in TERRAIN_ASSETS:
        var mat: ShaderMaterial=get_node(node_name).material as ShaderMaterial
        var tint: Color=env.tint
        var wash: float=float(env.mist)*0.12
        if node_name=="Foreground":wash=float(env.mist)*0.035
        elif node_name=="Mountains":wash=float(env.mist)*0.24
        var sky_color: Color=env.sky_top
        var night_light: float=clampf((0.54-(sky_color.r*0.21+sky_color.g*0.72+sky_color.b*0.07))*2.3+_weights[3]*0.23,0.0,1.0)
        mat.set_shader_parameter("clock",_clock)
        mat.set_shader_parameter("light_tint",tint)
        mat.set_shader_parameter("wash_color",env.sky_bottom)
        mat.set_shader_parameter("wash_strength",wash)
        mat.set_shader_parameter("snow_cover",float(env.snow_cover))
        mat.set_shader_parameter("window_light",night_light)
        mat.set_shader_parameter("wind_strength",env.wind)
    for name_text: String in ["Stars","FarClouds","NearRainSnow"]:get_node(name_text).set_environment(env,_quiet)

func get_active_atmosphere_id() -> String:
    return str(_encounter_snapshot().get("id",""))

func get_atmosphere_snapshot() -> Dictionary:
    var data: Dictionary=_encounter_snapshot()
    var weights: Dictionary=data.get("weights",{})
    var total: float=0.0
    for weight: Variant in weights.values():total+=float(weight)
    return {"id":str(data.get("id","")),"requested_id":str(_last_state.get("id","")),"age":float(data.get("age",0.0)),"duration":float(data.get("duration",60.0)),"quiet":_quiet,"opacity":clampf(total,0.0,1.0),"layer_count":weights.size(),"layer_ids":weights.keys(),"weights":weights.values(),"event_weights":weights,"canvas_size":Vector2(PAINTING_SIZE),"ready_ids":get_painted_atmosphere_ids(),"layered":true,"layer_names":LAYER_NAMES.duplicate()}

func get_layer_snapshot() -> Dictionary:
    var foreground: Sprite2D=$Foreground as Sprite2D
    var rect: Rect2=foreground.get_global_transform()*foreground.get_rect()
    return {"layered":true,"time":_clock,"weather_weights":get_weights(),"layer_names":LAYER_NAMES.duplicate(),"sky_top":_environment.get("sky_top",Color.WHITE),"sky_bottom":_environment.get("sky_bottom",Color.WHITE),"water_color":_environment.get("water",Color.WHITE),"river_level":0.526,"tree_sway":2.4,"snow_cover":float(_environment.get("snow_cover",0.0)),"particles":$NearRainSnow.get_particle_positions(),"cloud_positions":$FarClouds.get_cloud_positions(),"mist_offsets":Vector2(_clock*0.07,-_clock*0.05),"asset_ids":_asset_ids.duplicate(),"foreground_rect":rect,"event_weights":_event_weights()}
