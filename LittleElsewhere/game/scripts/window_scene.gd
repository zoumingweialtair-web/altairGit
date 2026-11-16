extends Node2D

const VisitorMotion = preload("res://scripts/visitor_motion.gd")
var _drawing_actor: Dictionary = {}

signal encounter(id: String, note: String)
signal bird_selected(id: String)

var weather: int = 0
var quiet: bool = false
var layered_weather_enabled: bool = false
var clock_time: float = 0.0
# Weather weights still drive animal behavior and reflected light when Stage
# owns the separate scenery and weather layers.
var weather_weights: Array[float] = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
var attraction: String = "seeds"
const TOWER_BASES: Array[Vector2] = [Vector2(650,368), Vector2(1000,325)]
const TOWER_HEIGHTS: Array[float] = [40.0,24.0]
var activity_blend: float = 1.0
var sheltered_perches: Dictionary = {
    "sparrow": Vector2(211, 375),
    "tit": Vector2(278, 239),
    "robin": Vector2(379, 321)
}
var actors: Array[Dictionary] = []
var spectacles: Array[Dictionary] = []
# This compatibility registry hands the ten new effects to EncounterLayers.
# Registered events are never painted again here, including their old accents.
var painted_atmosphere_ids: Array[String] = []
var atmosphere_tint: Color = Color.WHITE
var atmosphere_tint_strength: float = 0.0
const ATMOSPHERE_EVENTS: Array[String] = ["aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const ATMOSPHERE_TINTS: Dictionary = {
    "aurora_crown": Color("a9d6cc"), "ember_clouds": Color("efb997"),
    "meteor_shower": Color("afbcd7"), "deep_one": Color("91b4b1"),
    "sunken_city": Color("a5c5c1"), "sky_jellyfish": Color("bfc4e2"),
    "twin_moons": Color("c7d7e5"), "floating_isles": Color("d6dfb5"),
    "bioluminescent_tide": Color("92d5d3"), "constellation_stag": Color("c1cfe5")
}
const TREE_VISITORS: Array[String] = ["squirrel", "woodpecker", "owl", "luna_moth", "jewel_beetle", "fireflies", "kingfisher", "swallow", "magpie", "white_eye", "egret", "hedgehog", "cat", "bat", "dragonfly", "ladybug", "stag_beetle"]
const FANTASY_EVENTS: Array[String] = ["aurora", "star_whale", "time_ripple", "tree_spirit", "lanterns", "ghost_train", "moon_gate", "signal_echo", "aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const VISITOR_ANCHORS: Dictionary = {
    "squirrel": Vector2(185, 462), "woodpecker": Vector2(207, 321),
    "owl": Vector2(191, 417), "luna_moth": Vector2(392, 248),
    "jewel_beetle": Vector2(180, 479), "fireflies": Vector2(445, 481),
    "kingfisher": Vector2(474, 306), "swallow": Vector2(710, 230),
    "magpie": Vector2(547, 115), "white_eye": Vector2(379, 321),
    "egret": Vector2(855, 494), "hedgehog": Vector2(289, 728),
    "cat": Vector2(1237, 757), "bat": Vector2(718, 259),
    "dragonfly": Vector2(810, 530), "ladybug": Vector2(248, 651), "stag_beetle": Vector2(226, 477)
}
const EVENT_DURATIONS: Dictionary = {"aurora": 22.0, "star_whale": 22.0, "time_ripple": 20.0, "tree_spirit": 20.0, "lanterns":24.0, "ghost_train":24.0, "moon_gate":22.0, "signal_echo":22.0, "aurora_crown":60.0, "ember_clouds":60.0, "meteor_shower":60.0, "deep_one":60.0, "sunken_city":60.0, "sky_jellyfish":60.0, "twin_moons":60.0, "floating_isles":60.0, "bioluminescent_tide":60.0, "constellation_stag":60.0}
var perches: Dictionary = {
    "sparrow": Vector2(458, 302),
    "tit": Vector2(550, 115),
    "robin": Vector2(379, 321)
}
const BIRD_PATTERN: Array[String] = [
    "...........OOOO....",
    "..........OHHHHO...",
    "..........OHHEHOO..",
    ".........OHHHHHOBB.",
    "....OOOOOHHHHOO....",
    "...OWWWWWWWCCCO....",
    "..OWWWWWWWCCCCCO...",
    ".OTWWWWWWWCCCCO....",
    "OTTWWWWWCCCCOO.....",
    "TTTOOOOOOOOO.......",
    "......L..L.........",
    ".....LL..LL........"
]

func _ready() -> void:
    trigger("sparrow", false)
    trigger("tit", false)
    set_process(true)

func set_weather(value: int) -> void:
    weather = clampi(value, 0, 7)
    queue_redraw()

func set_layered_weather_enabled(enabled: bool) -> void:
    layered_weather_enabled = enabled
    queue_redraw()

func set_painted_atmospheres(ids: Array[String]) -> void:
    painted_atmosphere_ids.clear()
    for id in ids:
        if id in ATMOSPHERE_EVENTS and not painted_atmosphere_ids.has(id):
            painted_atmosphere_ids.append(id)
    queue_redraw()

func get_atmosphere_state() -> Dictionary:
    # Trigger order takes priority, including replay. Quiet deep water is an
    # explicit empty scene, not permission to reveal an older atmosphere.
    for index in range(spectacles.size() - 1, -1, -1):
        var event: Dictionary = spectacles[index]
        var id: String = str(event["id"])
        if id not in ATMOSPHERE_EVENTS:
            continue
        if quiet and id == "deep_one":
            return {}
        return {"id": id, "age": float(event["age"]), "duration": get_event_duration(id), "quiet": quiet}
    return {}

func clear_atmosphere_events() -> void:
    for index in range(spectacles.size() - 1, -1, -1):
        if str(spectacles[index]["id"]) in ATMOSPHERE_EVENTS:
            spectacles.remove_at(index)
    queue_redraw()

func get_weather_behavior() -> String:
    return ["枝头张望与食盘往返", "叶下避雨与抖落水珠", "枝头安静休息", "夕光中的缓慢归巢", "蓬松羽毛与枝头避雪", "薄雾里的近枝停歇", "树荫下避风与听雨", "晨光中梳羽与河边觅食"][weather]

func set_quiet(value: bool) -> void:
    quiet = value
    if quiet:
        # Gentle new encounters remain visible; older flyby effects stay suppressed.
        for index in range(spectacles.size() - 1, -1, -1):
            if str(spectacles[index]["id"]) not in FANTASY_EVENTS:
                spectacles.remove_at(index)
    queue_redraw()

func trigger(id: String, record: bool = true) -> void:
    var notes: Dictionary = {
        "sparrow": "麻雀先在枝头张望，然后落到食盘边啄食。",
        "tit": "蓝山雀停在高枝上，轻轻梳理羽毛。",
        "robin": "知更鸟从树影中探出身子，陪你看了一会儿河流。",
        "butterfly": "一只白蝶绕着窗边的小花缓缓飞过。",
        "ufo": "一道安静的光掠过雪山，河面留下短暂倒影。",
        "meteor": "流星从远处天空划过，留下细细的光迹。",
        "supernova": "远处多了一颗微亮的星，像一封迟到的问候。",
        "squirrel": "松鼠沿树干攀上横枝，抱着一颗小果子，蓬松的尾巴慢慢摆动。",
        "woodpecker": "啄木鸟攀住树皮，停一会儿，再有节奏地轻啄树干。",
        "owl": "树洞里探出一只林鸮，眨了眨圆眼睛，安静地转头望向河流。",
        "luna_moth": "月蛾披着淡绿色的长尾翅，在树影与月光之间缓缓盘旋。",
        "jewel_beetle": "雨后的树皮上，一只宝石甲虫慢慢爬行，鞘翅映出一线青绿。",
        "fireflies": "几颗萤火在岸边轻轻呼吸，像散落在草丛中的小星星。",
        "aurora": "雪山上方舒展出青紫色的极光，天空像一封缓缓打开的信。",
        "star_whale": "一尾小小的星鲸游过远空，身后留下渐渐熄灭的星粒。",
        "time_ripple": "一圈温柔的涟漪在远山前展开，像时间在此停了一小会儿。",
        "tree_spirit": "枝叶之间亮起两点青绿，树灵探出头，又轻轻融回树影。",
        "kingfisher": "翠鸟掠过水面，又回到低枝，蓝色翅膀闪过一线光。",
        "swallow": "燕子的剪刀尾划过晴空，转身时像一枚飞快的逗号。",
        "magpie": "喜鹊在高枝上摆了摆长尾，侧过头打量窗台。",
        "white_eye": "绣眼鸟轻跳到枝头，眼边一圈白色，像戴着小眼镜。",
        "egret": "白鹭在浅水中缓缓迈步，细长的倒影被河水拉开。",
        "hedgehog": "刺猬从花盆边慢慢探出头，鼻尖轻嗅一片落叶。",
        "cat": "一只猫轻巧地坐到窗台，尾巴晃了晃，望向远处的城镇。",
        "bat": "一只小蝙蝠绕着暮色盘旋，翼尖无声地掠过窗外。",
        "dragonfly": "蜻蜓在水面上悬停，透明翅膀闪着细碎的光。",
        "ladybug": "瓢虫沿叶片边缘慢慢爬过，红色背上藏着小黑点。",
        "stag_beetle": "锹甲爬上树皮，停下来探了探触角，像守着一座小门。",
        "lanterns": "几盏河灯从对岸漂来，温暖的光在水面轻轻摇晃。",
        "ghost_train": "远岸的雾里，一列没有声音的光慢慢驶过，又融入城镇。",
        "moon_gate": "月光在天空中围成一道门，门内的星点像另一片夜空。",
        "signal_echo": "远处的信号塔依次亮起，像正在传递一封只有夜色读得懂的信。",
        "aurora_crown": "极光在雪山上方展开成冠冕，河水也接住了青色的光。",
        "ember_clouds": "绯红的晚霞从远山漫过来，像一封铺满天空的温暖长信。",
        "meteor_shower": "许多流星错落划过夜空，愿望不必急着说完。",
        "deep_one": "远水之下缓缓浮起古老的巨大剪影，许多触须听了一会儿潮声，又沉回深处。",
        "sunken_city": "雾中的河面浮出一座阶梯之城，塔影静静倒映在水里。",
        "sky_jellyfish": "几只由星光织成的水母游过天空，触须拖着缓慢的银色波纹。",
        "twin_moons": "第二轮淡淡的月亮升起来，与熟悉的月光隔着星空相望。",
        "floating_isles": "长着小树的岩岛慢慢离开山脊，碎光从它们的根部落下。",
        "bioluminescent_tide": "一层层青蓝色的潮光从对岸推来，把河流写成发光的信。",
        "constellation_stag": "山脊上的星点连成一头鹿，枝杈般的鹿角驮着几颗更亮的星。"
    }
    if not notes.has(id):
        return
    if id in ["sparrow", "tit", "robin"]:
        if weather == 1:
            notes[id] = "这位来客躲进树叶下，在枝头轻轻抖落水珠。"
        elif weather == 2:
            notes[id] = "这位熟悉的来客在夜色里安静地歇在枝头。"
        elif weather == 3:
            notes[id] = "夕光落在羽毛上，来客慢慢返回枝头。"
        elif weather == 4:
            notes[id] = "小鸟蓬起羽毛，在树枝上等雪慢慢落下。"
    if record:
        encounter.emit(id, str(notes[id]))
    if id in ["ufo", "meteor", "supernova"] or id in FANTASY_EVENTS:
        if quiet and id not in FANTASY_EVENTS:
            return
        for index in range(spectacles.size() - 1, -1, -1):
            if str(spectacles[index]["id"]) == id:
                spectacles.remove_at(index)
        # A small limit keeps repeated demo clicks from filling the entire sky.
        while spectacles.size() >= 2:
            spectacles.pop_front()
        spectacles.append({"id": id, "age": 0.0, "motion_age": 0.0})
        queue_redraw()
        return
    # Retriggering a present species never teleports it or interrupts its gesture.
    for actor in actors:
        if str(actor["id"]) == id:
            return
    if id == "butterfly" and weather in VisitorMotion.SHELTER_WEATHER:
        return
    if actors.size() >= 6:
        # Make room by letting a visitor leave. The queued arrival belongs to that
        # slot, so explicit GM clears also discard queued visitors safely.
        var slot: Dictionary = actors[0]
        for actor in actors:
            if not actor.has("replacement"):
                slot = actor
                break
        slot["replacement"] = id
        VisitorMotion.request_departure(slot)
        return
    _spawn_actor(id)
    queue_redraw()

func _spawn_actor(id: String) -> void:
    if id not in VisitorMotion.IDS: return
    for actor in actors:
        if str(actor["id"]) == id: return
    if id == "butterfly" and weather in VisitorMotion.SHELTER_WEATHER: return
    var perch: Vector2 = VISITOR_ANCHORS.get(id, perches.get(id, Vector2(230, 550)))
    if weather in VisitorMotion.SHELTER_WEATHER and sheltered_perches.has(id):
        perch = sheltered_perches[id]
    actors.append(VisitorMotion.spawn(id, perch, weather))

func get_creature_ids() -> Array[String]:
    return VisitorMotion.IDS.duplicate()

func get_creature_duration(id: String) -> float:
    return VisitorMotion.duration(id, weather) if id in VisitorMotion.IDS else 0.0

func get_actor_lifecycle_snapshot(id: String) -> Dictionary:
    for actor in actors:
        if str(actor["id"]) == id:
            return {"id":id, "phase":actor.get("phase", "entry"),
                "phase_progress":actor.get("phase_progress", 0.0), "duration":actor.get("duration", 0.0),
                "age":actor["age"], "position":actor["pos"], "pose":actor.get("pose", ""),
                "flying":actor["fly"], "alpha":actor["alpha"], "motion_age":actor["motion_age"],
                "entry_duration":actor["entry_duration"], "exit_duration":actor["exit_duration"]}
    return {}

func request_actor_departure(id: String) -> bool:
    for actor in actors:
        if str(actor["id"]) == id:
            VisitorMotion.request_departure(actor)
            return true
    return false

func seek_actor_phase(id: String, phase: String, progress: float = 0.0) -> bool:
    if phase not in ["entry", "idle", "exit"]: return false
    for actor in actors:
        if str(actor["id"]) != id: continue
        var p: float = clampf(progress, 0.0, 0.9999)
        var enter: float = float(actor["entry_duration"])
        var leave: float = float(actor["exit_duration"])
        var duration: float = get_creature_duration(id)
        actor["duration"] = duration
        actor.erase("forced_exit_age")
        actor.erase("exit_from")
        actor.erase("relocate_from")
        actor.erase("replacement")
        actor["age"] = enter * p if phase == "entry" else (enter + (duration - enter - leave) * p if phase == "idle" else duration - leave + leave * p)
        actor["motion_age"] = float(actor["age"]) * (0.35 + 0.65 * activity_blend)
        VisitorMotion.sample(actor, weather, activity_blend)
        queue_redraw()
        return true
    return false

func _process(delta: float) -> void:
    clock_time += delta
    var blend: float = 1.0 - exp(-delta * 1.8)
    for index in range(8):
        var target: float = 1.0 if index == weather else 0.0
        weather_weights[index] = lerpf(weather_weights[index], target, blend)
    activity_blend = lerpf(activity_blend, 0.45 if quiet else 1.0, blend)
    var arrivals: Array[String] = []
    for i in range(actors.size() - 1, -1, -1):
        var actor: Dictionary = actors[i]
        var id: String = str(actor["id"])
        if int(actor.get("weather", weather)) != weather and str(actor.get("phase", "")) == "idle":
            actor["weather"] = weather
            actor["relocate_from"] = actor["pos"]
            actor["relocate_at"] = actor["age"]
            if perches.has(id):
                actor["anchor"] = sheltered_perches[id] if weather in VisitorMotion.SHELTER_WEATHER else perches[id]
        if VisitorMotion.advance(actor, delta, weather, activity_blend):
            if actor.has("replacement"): arrivals.append(str(actor["replacement"]))
            actors.remove_at(i)
    for id in arrivals:
        _spawn_actor(id)
    for i in range(spectacles.size() - 1, -1, -1):
        spectacles[i]["age"] = float(spectacles[i]["age"]) + delta
        spectacles[i]["motion_age"] = float(spectacles[i].get("motion_age", 0.0)) + delta * (0.45 + activity_blend * 0.55)
        var event_id: String = str(spectacles[i]["id"])
        var duration: float = get_event_duration(event_id)
        if float(spectacles[i]["age"]) > duration:
            spectacles.remove_at(i)
    _update_atmosphere_tint(delta)
    queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    if quiet:
        return
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        var click: Vector2 = (make_input_local(event) as InputEventMouseButton).position
        for actor in actors:
            if _actor_hit_rect(actor).has_point(click):
                bird_selected.emit(str(actor["id"]))
                get_viewport().set_input_as_handled()
                return
        for spectacle in spectacles:
            if _fantasy_hit_rect(spectacle).has_point(click):
                bird_selected.emit(str(spectacle["id"]))
                get_viewport().set_input_as_handled()
                return

func _draw() -> void:
    if not layered_weather_enabled:
        _draw_valley_mist()
        _draw_water()
        _draw_distant_town()
        _draw_stars()
        _draw_airborne_details()
        _draw_window_life()
    else:
        # The boat remains a separate moving visitor to the water. Surface
        # movement, reflections, clouds, leaves and precipitation belong to Stage.
        _draw_boat()
    _draw_signal_towers()
    _draw_attraction()
    for actor in actors:
        _drawing_actor = actor
        if str(actor["id"]) in TREE_VISITORS:
            _draw_tree_visitor(actor)
        elif str(actor["id"]) == "butterfly":
            _draw_butterfly(actor)
        else:
            _draw_bird(actor)
    _drawing_actor = {}
    for spectacle in spectacles:
        if str(spectacle["id"]) in FANTASY_EVENTS:
            _draw_fantasy(spectacle)
        else:
            _draw_spectacle(spectacle)
    if not layered_weather_enabled:
        _draw_rain()
        _draw_snow()

func _draw_bird(actor: Dictionary) -> void:
    var id: String = str(actor["id"])
    var age: float = float(actor.get("motion_age", actor["age"]))
    var alpha: float = float(actor["alpha"])
    var body: Color = Color("bda78a")
    var wing: Color = Color("806d55")
    var head: Color = Color("a99474")
    if id == "tit":
        body = Color("e5c866")
        wing = Color("65858c")
        head = Color("e9e1c7")
    elif id == "robin":
        body = Color("d59a69")
        wing = Color("88765c")
        head = Color("c98755")
    var palette: Dictionary = {
        "O": Color("34464a"), "H": head, "E": Color("17262e"),
        "B": Color("b4a069"), "W": wing, "C": body,
        "T": wing.darkened(0.1), "L": Color("495048")
    }
    var pos: Vector2 = actor["pos"]
    var flying: bool = bool(actor["fly"])
    var resting: float = weather_weights[2] + weather_weights[4] * 0.5
    var bob: float = sin(age * 2.2) * lerpf(0.85, 0.18, resting) * activity_blend
    var scale_pixel: float = 2.65
    var puff: float = 1.0 + weather_weights[4] * 0.11
    var facing: float = float(actor["facing"])
    draw_set_transform((pos + Vector2(0, bob)).round(), float(actor.get("body_tilt", 0.0)) * facing, Vector2(scale_pixel * facing * puff, scale_pixel))
    for y in range(BIRD_PATTERN.size()):
        var row: String = BIRD_PATTERN[y]
        for x in range(row.length()):
            var key: String = row.substr(x, 1)
            if key == ".":
                continue
            var color: Color = _ambient_color(palette[key])
            # A sleeping eye is a short dark stroke rather than a blinking flash.
            if key == "E" and (weather_weights[2] > 0.65 or fmod(age + float(id.length()), 5.3) < 0.18):
                color = _ambient_color(head.darkened(0.35))
            color.a = alpha
            var peek: float = 1.0 if not flying and y < 5 and sin(age * 0.72) > 0.86 else 0.0
            var part: Vector2 = Vector2.ZERO
            var pose: String = str(actor.get("pose", "perch"))
            if y < 5 and not flying:
                if pose == "peck": part = Vector2(1, maxf(0.0, sin(age * 8.0)) * 2.5)
                elif pose == "preen": part = Vector2(-2, 1)
                elif pose == "sing" and key == "B": part.y = 1.0 if int(age * 4) % 2 == 0 else 0.0
            if key == "T": part.y = roundf(sin(age * 1.6) * activity_blend)
            if key == "L" and flying: part.y -= 2.0 * (1.0 - float(actor.get("land_blend", 0.0)))
            if key == "C" and pose == "sing": part.x += roundf(sin(age * 4.0) * 0.6)
            draw_rect(Rect2(Vector2(x - 9 + peek, y - 12) + part, Vector2.ONE), color)
    if flying or (not quiet and weather in [0, 3] and fmod(age, 13.0) > 12.35):
        var flap: bool = int(age * 9.0) % 2 == 0
        var fold: float = float(actor.get("land_blend",0.0)) if str(actor.get("phase","idle")) != "idle" else 0.0
        var wc: Color = _ambient_color(wing.lightened(0.12))
        wc.a = alpha
        if flap:
            draw_rect(Rect2(-5, -16+fold*7, 5, 9-fold*4), wc)
            draw_rect(Rect2(-8+fold*3, -18+fold*10, 5, 5-fold*2), wc)
        else:
            draw_rect(Rect2(-5, -6-fold*3, 7-fold*2, 7-fold*4), wc)
    elif weather == 1 and sin(age * 1.1) > 0.91 and not quiet:
        # A brief small shake and a few droplets, without screen-wide effects.
        draw_rect(Rect2(-9, -13, 1, 2), Color(0.68, 0.81, 0.87, alpha * 0.6))
        draw_rect(Rect2(7, -15, 1, 2), Color(0.68, 0.81, 0.87, alpha * 0.5))
    elif weather in [0, 3] and age > 11.0 and sin(age * 3.5) > 0.8:
        var seed: Color = Color("e4c488")
        seed.a = alpha
        draw_rect(Rect2(9, -3, 1, 1), seed)
    draw_set_transform(Vector2.ZERO)

func _draw_butterfly(actor: Dictionary) -> void:
    var pos: Vector2 = actor["pos"]
    var age: float = float(actor.get("motion_age", actor["age"]))
    var width: float = 3.0 + absf(sin(age * 6.0)) * 6.0
    var c: Color = _ambient_color(Color(0.98, 0.93, 0.75, float(actor["alpha"])))
    draw_rect(Rect2(pos.x - width - 2, pos.y - 9, width, 10), c)
    draw_rect(Rect2(pos.x + 2, pos.y - 9, width, 10), c)
    draw_rect(Rect2(pos.x - width + 1, pos.y + 2, width - 2, 5), c.darkened(0.08))
    draw_rect(Rect2(pos.x + 2, pos.y + 2, width - 2, 5), c.darkened(0.08))
    draw_rect(Rect2(pos.x - 1, pos.y - 7, 3, 15), _visitor_ink("646453", float(actor["alpha"])))
    for side in [-1.0, 1.0]:
        draw_line(pos + Vector2(side, -7), pos + Vector2(side * (4 + sin(age * 2.3)), -12), _visitor_ink("646453", float(actor["alpha"])), 1.0)

func _update_atmosphere_tint(delta: float) -> void:
    var state: Dictionary = get_atmosphere_state()
    var target: Color = Color.WHITE
    var strength: float = 0.0
    if not state.is_empty() and str(state["id"]) in painted_atmosphere_ids:
        target = ATMOSPHERE_TINTS[str(state["id"])]
        strength = 0.40 * minf(smoothstep(0.0, 3.0, float(state["age"])),
            1.0 - smoothstep(float(state["duration"]) - 4.0, float(state["duration"]), float(state["age"])))
    var blend: float = 1.0 - exp(-delta * 2.0)
    atmosphere_tint = atmosphere_tint.lerp(target, blend)
    atmosphere_tint_strength = lerpf(atmosphere_tint_strength, strength, blend)

func _ambient_color(color: Color) -> Color:
    var tint: Color = Color.WHITE * weather_weights[0]
    tint += Color(0.63, 0.74, 0.81) * weather_weights[1]
    tint += Color(0.35, 0.46, 0.65) * weather_weights[2]
    tint += Color(1.0, 0.80, 0.65) * weather_weights[3]
    tint += Color(0.78, 0.85, 0.91) * weather_weights[4]
    tint += Color(0.80, 0.88, 0.87) * weather_weights[5]
    tint += Color(0.48, 0.61, 0.71) * weather_weights[6]
    tint += Color(1.0, 0.90, 0.76) * weather_weights[7]
    tint.a = 1.0
    # Preserve species markings while letting feathers and fur catch a small
    # amount of the layered scene's reflected light.
    tint = tint.lerp(tint * atmosphere_tint, atmosphere_tint_strength)
    return color * tint

func _draw_water() -> void:
    var glint: Color = Color("e6f2de").lerp(Color("e8bd81"), weather_weights[3])
    glint = glint.lerp(Color("a3c4df"), weather_weights[2])
    var calm: float = 1.0 - weather_weights[1] * 0.7 - weather_weights[4] * 0.4
    for i in range(20):
        var x: float = 340.0 + fmod(float(i * 53), 650.0)
        var y: float = 467.0 + fmod(float(i * 23), 128.0)
        if not _is_open_water(Vector2(x,y)):continue
        var alpha: float = (0.04 + (sin(clock_time * 0.5 + float(i)) + 1.0) * 0.06) * calm
        glint.a = alpha
        draw_rect(Rect2(x, y, 7 + i % 4 * 4, 2), glint)
    var rain: float = weather_weights[1] + weather_weights[6]
    if rain > 0.01:
        var ripple_count: int = 12 if quiet else 26
        for i in range(ripple_count):
            var phase: float = fmod(clock_time * 0.66 + float(i) * 0.313, 1.0)
            var center: Vector2 = Vector2(340.0 + fmod(float(i * 83), 650.0), 467.0 + fmod(float(i * 37), 128.0))
            if not _is_open_water(center):continue
            var rx: float = 3.0 + phase * 13.0
            var ry: float = 1.0 + phase * 3.0
            var c: Color = Color(0.66, 0.78, 0.84, rain * (1.0 - phase) * 0.25)
            draw_line(center + Vector2(-rx * 0.6, -ry), center + Vector2(rx * 0.6, -ry), c, 1.0)
            draw_line(center + Vector2(-rx, 0), center + Vector2(-rx * 0.7, -ry), c, 1.0)
            draw_line(center + Vector2(rx, 0), center + Vector2(rx * 0.7, -ry), c, 1.0)
            draw_line(center + Vector2(-rx * 0.6, ry), center + Vector2(rx * 0.6, ry), c, 1.0)
    _draw_boat()

func _draw_boat() -> void:
    var progress: float = fmod(clock_time / 105.0, 1.0)
    var boat_pos: Vector2 = Vector2(500, 568).lerp(Vector2(900, 540), progress)
    var boat_alpha: float = 1.0 - weather_weights[4] * 0.75
    var hull: Color = _ambient_color(Color("786e58"))
    hull.a = boat_alpha
    var cabin: Color = _ambient_color(Color("d7c9a7"))
    cabin.a = boat_alpha
    var roof: Color = _ambient_color(Color("e1d9c1"))
    roof.a = boat_alpha
    draw_rect(Rect2(boat_pos + Vector2(-19, 0), Vector2(40, 7)), hull)
    draw_rect(Rect2(boat_pos + Vector2(-14, 7), Vector2(30, 3)), hull)
    draw_rect(Rect2(boat_pos + Vector2(-12, -13), Vector2(25, 13)), cabin)
    draw_rect(Rect2(boat_pos + Vector2(-15, -16), Vector2(32, 4)), roof)
    var window_color: Color = _ambient_color(Color("6f9099")).lerp(Color("e2b977"), weather_weights[2] * 0.8)
    window_color.a = boat_alpha
    for x in [-8, 1, 9]:
        draw_rect(Rect2(boat_pos + Vector2(x, -10), Vector2(5, 8)), window_color)

func _draw_valley_mist() -> void:
    var mist: float = weather_weights[1] * 0.75 + weather_weights[4] * 0.45 + weather_weights[5] * 2.3 + weather_weights[6] * 1.2
    if mist < 0.01:
        return
    # Each translucent ribbon follows the distant valley only, never the sill.
    for band in range(3):
        var points: PackedVector2Array = PackedVector2Array()
        var y0: float = 303.0 + float(band) * 41.0
        for i in range(15):
            var x: float = 460.0 + float(i) * 48.0
            var y: float = y0 + sin(float(i) * 0.65 + clock_time * 0.035 + float(band)) * 6.0
            points.append(Vector2(x, y))
        for i in range(14, -1, -1):
            var x: float = 460.0 + float(i) * 48.0
            var y: float = y0 + 20.0 + sin(float(i) * 0.65 + clock_time * 0.035 + float(band)) * 6.0
            points.append(Vector2(x, y))
        draw_colored_polygon(points, Color(0.71, 0.81, 0.84, mist * 0.045))

func _draw_rain() -> void:
    var strength: float = weather_weights[1] + weather_weights[6]
    if strength < 0.01:
        return
    for layer in range(2):
        var count: int = (80 if layer == 0 else 55) if not quiet else (45 if layer == 0 else 22)
        var speed: float = (145.0 if layer == 0 else 265.0) * (0.65 + activity_blend * 0.35)
        for i in range(count):
            var x: float = 60.0 + fmod(float(i * 137 + layer * 53) + clock_time * (15.0 + layer * 10.0 + weather_weights[6] * 145.0), 1315.0)
            var y: float = 45.0 + fmod(float(i * 73 + layer * 127) + clock_time * speed, 650.0)
            var length: float = 6.0 if layer == 0 else 12.0
            var alpha: float = (0.14 if layer == 0 else 0.31) * strength
            var c: Color = Color(0.74, 0.84, 0.90, alpha)
            draw_line(Vector2(x, y).round(), Vector2(x - 2.0 - layer - weather_weights[6] * 15.0, y + length).round(), c, 1.0 if layer == 0 else 1.5)
    # Water gathers briefly on the outside rail, not across the interior desk.
    for i in range(10):
        var phase: float = fmod(clock_time * 0.8 + float(i) * 0.43, 1.0)
        var x: float = 400.0 + float(i) * 83.0
        if phase < 0.18:
            var c: Color = Color(0.80, 0.88, 0.92, strength * (1.0 - phase / 0.18) * 0.3)
            draw_rect(Rect2(x, 602.0 - phase * 11.0, 2, 3), c)

func _draw_snow() -> void:
    var strength: float = weather_weights[4]
    if strength < 0.01:
        return
    for layer in range(2):
        var count: int = (55 if layer == 0 else 42) if not quiet else (28 if layer == 0 else 22)
        var speed: float = (24.0 if layer == 0 else 43.0) * (0.7 + activity_blend * 0.3)
        for i in range(count):
            var x: float = 60.0 + fmod(float(i * 139 + layer * 67) + clock_time * 8.0 + sin(clock_time * 0.19 + i) * 19.0, 1310.0)
            var y: float = 32.0 + fmod(float(i * 89 + layer * 113) + clock_time * speed, 661.0)
            var side: float = 2.0 if layer == 0 else 3.0
            var c: Color = Color(0.93, 0.96, 0.98, strength * (0.38 if layer == 0 else 0.72))
            draw_rect(Rect2(Vector2(x, y).round(), Vector2(side, side)), c)
            if layer == 1 and i % 4 == 0:
                draw_rect(Rect2(Vector2(x - 1, y + 1).round(), Vector2(5, 1)), c)
                draw_rect(Rect2(Vector2(x + 1, y - 1).round(), Vector2(1, 5)), c)

func _draw_airborne_details() -> void:
    var daylight: float = weather_weights[0] * 0.65 + weather_weights[3] + weather_weights[7] * 0.85
    if daylight > 0.01:
        for i in range(6):
            var phase: float = fmod(clock_time * 0.022 + float(i) * 0.193, 1.0)
            var alpha: float = sin(phase * PI) * daylight * 0.55 * activity_blend
            var pos: Vector2 = Vector2(165.0 + phase * 430.0, 168.0 + phase * 420.0 + sin(phase * 9.0 + i) * 22.0)
            var c: Color = Color("c9ba76") if i % 2 == 0 else Color("82965e")
            c.a = alpha
            draw_rect(Rect2(pos.round(), Vector2(4, 2)), c)
            draw_rect(Rect2((pos + Vector2(1, -1)).round(), Vector2(2, 4)), c)
    var night: float = weather_weights[2]
    if night > 0.01:
        var count: int = 5 if quiet else 10
        for i in range(count):
            var pos: Vector2 = Vector2(175.0 + fmod(float(i * 83), 600.0), 480.0 + fmod(float(i * 37), 132.0))
            pos += Vector2(sin(clock_time * 0.18 + i) * 11.0, cos(clock_time * 0.15 + i) * 9.0)
            var phase: float = (sin(clock_time * 0.5 + float(i) * 1.7) + 1.0) * 0.5
            var alpha: float = night * phase * 0.42
            draw_rect(Rect2((pos - Vector2.ONE).round(), Vector2(4, 4)), Color(0.73, 0.77, 0.46, alpha * 0.12))
            draw_rect(Rect2(pos.round(), Vector2(2, 2)), Color(0.91, 0.88, 0.61, alpha))

func _draw_stars() -> void:
    var strength: float = weather_weights[2]
    if strength < 0.01:
        return
    for i in range(13):
        var x: float = 650.0 + fmod(float(i * 97), 500.0)
        var y: float = 47.0 + fmod(float(i * 43), 142.0)
        var alpha: float = (0.28 + sin(clock_time * 0.3 + float(i)) * 0.07) * strength
        draw_rect(Rect2(x, y, 2, 2), Color(0.95, 0.91, 0.75, alpha))

func _draw_spectacle(event: Dictionary) -> void:
    var id: String = str(event["id"])
    var age: float = float(event["age"])
    if id == "ufo":
        var progress: float = age / 12.0
        var pos: Vector2 = Vector2(640 + progress * 580.0, 139 + sin(progress * PI) * 21.0)
        var alpha: float = minf(1.0, minf(age, 12.0 - age))
        draw_rect(Rect2(pos + Vector2(-9, -8), Vector2(18, 7)), Color(0.6, 0.8, 0.78, alpha))
        draw_rect(Rect2(pos + Vector2(-18, -1), Vector2(36, 5)), Color(0.72, 0.78, 0.77, alpha))
        draw_rect(Rect2(pos + Vector2(-25, 4), Vector2(50, 5)), Color(0.38, 0.51, 0.58, alpha))
        draw_rect(Rect2(pos + Vector2(-14, 9), Vector2(28, 3)), Color(0.79, 0.83, 0.65, alpha))
        draw_rect(Rect2(750 + progress * 170, 528, 30, 2), Color(0.8, 0.92, 0.83, alpha * 0.5))
    elif id == "meteor":
        if age > 4.5:
            return
        var progress: float = age / 4.5
        var pos: Vector2 = Vector2(750, 80).lerp(Vector2(1160, 220), progress)
        var alpha: float = sin(progress * PI)
        for i in range(14):
            var c: Color = Color(1.0, 0.93, 0.68, alpha * (1.0 - float(i) / 14.0))
            draw_rect(Rect2(pos - Vector2(i * 5, i * 1.7), Vector2(4, 3)), c)
    elif id == "supernova":
        var alpha: float = sin(age / 18.0 * PI) * 0.8
        var pos: Vector2 = Vector2(930, 125)
        draw_rect(Rect2(pos - Vector2(2, 10), Vector2(4, 20)), Color(0.91, 0.94, 1.0, alpha * 0.7))
        draw_rect(Rect2(pos - Vector2(10, 2), Vector2(20, 4)), Color(0.91, 0.94, 1.0, alpha * 0.7))
        draw_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), Color(1.0, 0.98, 0.88, alpha))




# Read-only probes are also useful to accessibility and viewport click checks.
func get_active_event_ids() -> Array[String]:
    var ids: Array[String] = []
    for actor in actors:
        ids.append(str(actor["id"]))
    for event in spectacles:
        ids.append(str(event["id"]))
    return ids

func get_event_duration(id: String) -> float:
    if id in TREE_VISITORS:return 36.0
    if id in ["sparrow", "tit", "robin", "butterfly"]:return 40.0
    return float(EVENT_DURATIONS.get(id, 18.0 if id=="supernova" else 12.0))

func is_event_visible(id: String) -> bool:
    if quiet and id=="deep_one":return false
    if id in painted_atmosphere_ids and str(get_atmosphere_state().get("id", "")) != id:
        return false
    for spectacle in spectacles:
        if str(spectacle["id"])==id:
            return _event_envelope(float(spectacle["age"]),get_event_duration(id))>0.01
    return false

func get_actor_position(id: String) -> Vector2:
    for actor in actors:
        if str(actor["id"]) == id:
            return actor["pos"]
    return Vector2.INF

func _actor_hit_rect(actor: Dictionary) -> Rect2:
    var pos: Vector2 = actor["pos"]
    if bool(actor.get("fly",false)) and str(actor["id"]) in ["woodpecker","owl","egret"]:
        return Rect2(pos-Vector2(66,88),Vector2(132,118))
    match str(actor["id"]):
        "squirrel": return Rect2(pos - Vector2(50, 66), Vector2(94, 72))
        "woodpecker": return Rect2(pos - Vector2(31, 60), Vector2(56, 66))
        "owl": return Rect2(pos - Vector2(30, 64), Vector2(60, 68))
        "luna_moth": return Rect2(pos - Vector2(43, 35), Vector2(86, 75))
        "jewel_beetle": return Rect2(pos - Vector2(22, 36), Vector2(44, 46))
        "fireflies": return Rect2(pos - Vector2(67, 49), Vector2(134, 98))
        "cat": return Rect2(pos - Vector2(44, 76), Vector2(102, 83))
        "hedgehog": return Rect2(pos - Vector2(45, 40), Vector2(88, 46))
        "egret": return Rect2(pos - Vector2(25, 68), Vector2(62, 75))
        "swallow", "bat", "dragonfly": return Rect2(pos - Vector2(44, 31), Vector2(88, 62))
    return Rect2(pos - Vector2(31, 45), Vector2(68, 53))

func _fantasy_hit_rect(event: Dictionary) -> Rect2:
    var t: float = float(event.get("motion_age", event["age"]))
    match str(event["id"]):
        "aurora": return Rect2(650, 45, 460, 165)
        "star_whale": return Rect2(_whale_position(t) - Vector2(88, 42), Vector2(176, 84))
        "time_ripple": return Rect2(854, 211, 140, 140)
        "tree_spirit": return Rect2(309, 182, 65, 77)
        "lanterns": return Rect2(420, 475, 590, 100)
        "ghost_train": return Rect2(440, 421, 250, 38)
        "moon_gate": return Rect2(789, 81, 142, 158)
        "signal_echo": return Rect2(600, 260, 440, 150)
        "aurora_crown", "ember_clouds", "meteor_shower":return Rect2(570,60,560,230)
        "deep_one":return Rect2(510,475,310,120)
        "sunken_city":return Rect2(560,460,330,135)
        "sky_jellyfish":return Rect2(590,75,535,220)
        "twin_moons":return Rect2(650,70,140,135)
        "floating_isles":return Rect2(620,145,530,155)
        "bioluminescent_tide":return Rect2(350,470,670,120)
        "constellation_stag":return Rect2(650,190,330,150)
    return Rect2()

func _event_envelope(age: float, duration: float) -> float:
    return minf(smoothstep(0.0, 1.5, age), 1.0 - smoothstep(duration - 3.0, duration, age))

func _pixel_pattern(pattern: Array[String], palette: Dictionary, origin: Vector2, alpha: float, ambient: bool = true) -> void:
    for y in range(pattern.size()):
        for x in range(pattern[y].length()):
            var key: String = pattern[y].substr(x, 1)
            if not palette.has(key):
                continue
            var color: Color = palette[key]
            if ambient:
                color = color.lerp(_ambient_color(color), 0.7)
            color.a *= alpha
            draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), color)

func _visitor_ink(hex_color: String, alpha: float, ambient: bool = true) -> Color:
    var color: Color = Color(hex_color)
    if ambient:
        color = color.lerp(_ambient_color(color), 0.7)
    color.a = alpha
    return color

func _draw_tree_visitor(actor: Dictionary) -> void:
    var id: String = str(actor["id"])
    var pos: Vector2 = actor["pos"]
    var t: float = float(actor["motion_age"])
    var alpha: float = float(actor["alpha"])
    if bool(actor.get("fly", false)) and id in ["woodpecker", "owl", "egret"]:
        var landing: float = float(actor.get("land_blend", 0.0))
        var flight_actor: Dictionary = actor.duplicate()
        flight_actor["alpha"] = alpha * (1.0 - landing)
        _draw_large_bird_flight(flight_actor)
        if landing <= 0.001: return
        alpha *= landing
    match id:
        "squirrel": _draw_squirrel(pos, t, alpha, str(actor.get("pose", "climb")))
        "woodpecker": _draw_woodpecker(pos, t, alpha)
        "owl": _draw_owl(pos, t, alpha)
        "luna_moth": _draw_luna_moth(pos, t, alpha)
        "jewel_beetle": _draw_jewel_beetle(pos, t, alpha)
        "fireflies": _draw_firefly_group(pos, t, alpha)
        "kingfisher", "swallow", "magpie", "white_eye", "egret": _draw_new_bird(id, pos, t, alpha)
        "hedgehog": _draw_hedgehog(pos, t, alpha)
        "cat": _draw_cat(pos, t, alpha)
        "bat": _draw_bat(pos, t, alpha)
        "dragonfly", "ladybug", "stag_beetle": _draw_new_insect(id, pos, t, alpha)

func _draw_squirrel(pos: Vector2, t: float, alpha: float, pose: String) -> void:
    var palette: Dictionary = {"O": Color("354640"), "F": Color("ae784b"), "H": Color("e1aa69"), "C": Color("efd5a2"), "E": Color("1c333c")}
    var tail: Array[String] = [
        "....OOOOO...", "..OOCCCCHO..", ".OCCHHHHHHO.", "OCHFFFFHHHO.",
        "OHFFFFFHHHO.", "OHFFFFHHHHO.", "OHFFFHHHHO..", "OHFFHHHHO...",
        "OHFFHHHO....", "OHFFHHHO....", ".OHFFHHO....", ".OHFFFHO....",
        "..OHFFHO....", "...OFFFO....", "....OOO....."
    ]
    var body: Array[String] = [
        "........OO.....", ".......OFFO....", "......OHFFO....", "......OHHHHOO..",
        ".....OHHHEHFFO.", ".....OHHHHHHFO.", ".....OHHHHHOO..", "....OFFHCOO....",
        "...OFFFHHCO....", "..OFFFFHCCCO...", "..OFFFHHCCCO...", "..OFFHHHCCCO...",
        "..OFFHHHCCO....", "...OFFHHCO.....", "...OFFHFO......", "..OFFFFFOOO....",
        "..OOOOOOOOO...."
    ]
    var bob: float = sin(t * (2.3 if pose == "nibble" else 4.2)) * 0.65 * activity_blend
    draw_set_transform((pos + Vector2(0, bob)).round(), 0.0, Vector2(2.3 * float(_drawing_actor.get("facing",1.0)), 2.3))
    var tail_sway: float = roundf(sin(t * 1.8) * 1.3 * activity_blend)
    # Tail root joins the rump; the curled upper section moves independently.
    for width in [6.0,4.0]:
        var tail_color: Color = _visitor_ink("354640" if width > 5.0 else "ae784b",alpha)
        draw_line(Vector2(-15,-15+tail_sway),Vector2(-12,-7),tail_color,width)
        draw_line(Vector2(-12,-7),Vector2(-4,-5),tail_color,width)
    _pixel_pattern(tail, palette, Vector2(-20, -29 + tail_sway), alpha)
    _pixel_pattern(body, palette, Vector2(-8, -17), alpha)
    if fmod(t, 5.2) < 0.18: draw_rect(Rect2(2,-13,2,1),_visitor_ink("ae784b",alpha))
    draw_rect(Rect2(0,-17-roundf(maxf(0.0,sin(t*0.8))),2,2),_visitor_ink("ae784b",alpha))
    if pose == "nibble":
        var nibble: float = 1.0 if fmod(t, 2.7) < 0.5 else 0.0
        draw_rect(Rect2(5, -10 + nibble, 5, 5), _visitor_ink("b98c4f", alpha))
        draw_rect(Rect2(4, -11 + nibble, 7, 2), _visitor_ink("6c553b", alpha))
        draw_rect(Rect2(5, -8 + nibble, 2, 2), _visitor_ink("e1bc86", alpha))
    else:
        var step: float = sin(t * 5.0) * 1.0
        draw_rect(Rect2(-9, -10 + roundf(step), 5, 2), _visitor_ink("c68c5a", alpha))
        draw_rect(Rect2(-8, -3 - roundf(step), 5, 2), _visitor_ink("c68c5a", alpha))
    draw_set_transform(Vector2.ZERO)

func _draw_woodpecker(pos: Vector2, t: float, alpha: float) -> void:
    var pattern: Array[String] = [
        "......RRRR.....", ".....ORRRRO....", "....OHHHHHHO...", "...OHHHEHHHHO..",
        "BBBBBHHHHHHHO..", "...OHHHHHOOO...", "....OHHOOO.....", "....OHHCOOO....",
        "....OHCCOWWO...", "....OHCCOWWO...", "....OHCCOWHO...", "....OHCCOWWO...",
        "....OHCCOWHO...", "....OHCCOWWO...", "....OHCCOWHO...", "...LOHCCOOO....",
        "..LL.OHCOOO....", ".....ORROO.....", "....LORRO......", "...LL.OOO......",
        "......OOO......", "......OO......."
    ]
    var palette: Dictionary = {"O": Color("293b3b"), "H": Color("e2dfbf"), "C": Color("f0e2bd"), "W": Color("586166"), "R": Color("b75a4c"), "B": Color("5d6861"), "E": Color("192b31"), "L": Color("696552")}
    draw_set_transform(pos.round(), 0.0, Vector2(2.2, 2.2))
    var peck_phase: float = fmod(t, 4.4)
    var peck: float = maxf(0.0, sin(peck_phase * 10.0)) * 2.0 * activity_blend if peck_phase < 1.1 else 0.0
    # Head moves toward the bark while feet and tail remain braced.
    for y in range(pattern.size()):
        _pixel_pattern([pattern[y]], palette, Vector2(-7 - roundf(peck) if y < 7 else -7, y - 22), alpha)
    draw_set_transform(Vector2.ZERO)

func _draw_owl(pos: Vector2, t: float, alpha: float) -> void:
    var body: Array[String] = [
        ".....OOOOOOOO.....", "...OOFFFFFFFFOO...", "..OFFHHHHHHHHFFO..", ".OFFHHHHHHHHHHFFO.",
        ".OFHCCCCCCCCCCHFO.", "OFHCCCCCCCCCCCCHFO", "OFHCCCCCCCCCCCCHFO", "OFHCCCCCCCCCCCCHFO",
        ".OFHHCCCCCCCCHHFO.", ".OFFHHHHHHHHHFFFO.", "..OFFHHHHHHHFFFO..", "..OFFHCCCCCHFFFO..",
        "..OFFHCFCFCHFFFO..", "..OFFHCCCCCHFFFO..", "..OFFHCFCFCHFFFO..", "...OFFCCCCFFFO....",
        "....OFFCCFFFO.....", ".....OOOOOOO......", ".....LL..LL......."
    ]
    var palette: Dictionary = {"O": Color("47504a"), "F": Color("8b7d62"), "H": Color("b5a383"), "C": Color("d5c6a2"), "L": Color("8e8968")}
    draw_set_transform((pos + Vector2(0, sin(t * 1.4) * 0.3 * activity_blend)).round(), 0.0, Vector2(2.7, 2.7))
    _pixel_pattern(body, palette, Vector2(-9, -19), alpha)
    var gaze: float = roundf(sin(t * 0.36) * 1.2)
    var blink: bool = fmod(t, 5.7) < 0.23
    for x in [-4.0, 3.0]:
        draw_rect(Rect2(x + gaze - 2, -14, 5, 5), _visitor_ink("b8a773", alpha))
        if blink:
            draw_rect(Rect2(x + gaze - 1, -12, 3, 1), _visitor_ink("283c3e", alpha))
        else:
            draw_rect(Rect2(x + gaze - 1, -13, 3, 3), _visitor_ink("263c3f", alpha))
            draw_rect(Rect2(x + gaze - 1, -13, 1, 1), _visitor_ink("dfdab3", alpha))
    draw_rect(Rect2(gaze, -10, 2, 3), _visitor_ink("b89e62", alpha))
    draw_set_transform(Vector2.ZERO)

func _draw_luna_moth(pos: Vector2, t: float, alpha: float) -> void:
    var wing: Array[String] = [
        ".......OO....", ".....OOGGO...", "...OOGGLLO...", "..OGGLLLLO...",
        ".OGLLLLLLO...", "OGLLEELLO....", "OGLLCELLO....", "OGLLLLLO.....",
        ".OGLLLO......", "..OGLO.......", "..OGLLO......", "..OGLLO......",
        "...OGLO......", "...OGLO......", "....GLO......", "....GLO......",
        ".....GO......", ".....GO......", "......O......"
    ]
    var palette: Dictionary = {"O": Color("638c77"), "G": Color("9bbd8b"), "L": Color("c3d6a7"), "E": Color("b2a57c"), "C": Color("e1d7ad")}
    var spread: float = 0.62 + sin(t * (9.0 if str(_drawing_actor.get("phase","idle")) != "idle" else 5.0)) * 0.30 * activity_blend
    for side in [-1.0, 1.0]:
        draw_set_transform(pos.round(), 0.0, Vector2(2.5 * spread * side, 2.0))
        _pixel_pattern(wing, palette, Vector2(1, -10), alpha)
    draw_set_transform(pos.round(), 0.0, Vector2(2.0, 2.0))
    draw_rect(Rect2(-1, -7, 3, 13), _visitor_ink("c8c49b", alpha))
    draw_rect(Rect2(-1, -9, 3, 3), _visitor_ink("d5d5af", alpha))
    draw_line(Vector2(0, -8), Vector2(-4 - sin(t * 2.1), -12), _visitor_ink("a3b28b", alpha), 1.0)
    draw_line(Vector2(1, -8), Vector2(5 + sin(t * 2.1), -12), _visitor_ink("a3b28b", alpha), 1.0)
    draw_set_transform(Vector2.ZERO)

func _draw_jewel_beetle(pos: Vector2, t: float, alpha: float) -> void:
    var pattern: Array[String] = [
        "...OOOO...", "..OGGGGO..", "...OGGO...", "..OGGGGO..", ".OGHGGHGO.",
        "OGHHGGHHGO", "OGHHGGHHGO", "OGHGGGGHGO", "OGHGGGGHGO", "OGHGGGGHGO",
        ".OGGGGGGO.", "..OGGGGO..", "...OOOO..."
    ]
    var palette: Dictionary = {"O": Color("2d4d42"), "G": Color("458f78"), "H": Color("85b690")}
    draw_set_transform(pos.round(), 0.0, Vector2(2.35, 2.35))
    var leg: float = roundf(sin(t * 2.4))
    for y in [-9, -5, -2]:
        draw_line(Vector2(-4, y), Vector2(-7, y - 1 + leg), _visitor_ink("4b5d45", alpha), 1.0)
        draw_line(Vector2(4, y), Vector2(7, y + 1 - leg), _visitor_ink("4b5d45", alpha), 1.0)
    _pixel_pattern(pattern, palette, Vector2(-5, -13), alpha)
    draw_rect(Rect2(-0.5, -9, 1, 8), _visitor_ink("315f54", alpha))
    draw_line(Vector2(-2, -12), Vector2(-4 - sin(t * 1.7), -15), _visitor_ink("58794f", alpha), 1.0)
    draw_line(Vector2(2, -12), Vector2(4 + cos(t * 1.7), -15), _visitor_ink("58794f", alpha), 1.0)
    var glint: float = pow((sin(t * 0.75) + 1.0) * 0.5, 3.0) * 0.5
    draw_rect(Rect2(-3, -9, 1, 3), Color(0.67, 0.9, 0.69, alpha * glint))
    draw_set_transform(Vector2.ZERO)

func _draw_firefly_group(pos: Vector2, t: float, alpha: float) -> void:
    var count: int = 7 if quiet else 12
    for index in range(count):
        var phase: float = float(index) * 2.399
        var radius: float = 19.0 + float(index % 4) * 11.0
        var point: Vector2 = pos + Vector2(cos(phase + t * 0.035) * radius, sin(phase) * radius * 0.65)
        point += Vector2(sin(t * 0.4 + phase) * 5.0, cos(t * 0.31 + phase) * 6.0) * activity_blend
        var wing: float = 1.5 + absf(sin(t * 15.0 + phase)) * 2.0
        draw_line(point+Vector2(-wing,-1),point+Vector2(wing,-1),Color(0.65,0.76,0.60,alpha*0.35),1.0)
        draw_rect(Rect2(point+Vector2(0,-2),Vector2(1,3)),Color(0.36,0.49,0.37,alpha*0.7))
        var pulse: float = 0.2 + (sin(t * 0.9 + phase) + 1.0) * 0.32
        var glow: float = alpha * pulse * (0.68 if quiet else 1.0)
        draw_rect(Rect2((point - Vector2(2, 2)).round(), Vector2(7, 7)), Color(0.78, 0.82, 0.48, glow * 0.06))
        draw_rect(Rect2((point - Vector2.ONE).round(), Vector2(5, 5)), Color(0.87, 0.88, 0.53, glow * 0.1))
        draw_rect(Rect2(point.round(), Vector2(2, 2)), Color(0.95, 0.93, 0.63, glow))

func _whale_position(t: float) -> Vector2:
    return Vector2(735 + t * 16.0, 133.0 + sin(t * 0.22) * 12.0)

func _draw_fantasy(event: Dictionary) -> void:
    var id: String = str(event["id"])
    var age: float = float(event["age"])
    var t: float = float(event.get("motion_age", age))
    if quiet and id=="deep_one":return
    var alpha: float = _event_envelope(age, get_event_duration(id)) * (0.48 if quiet else 1.0)
    if id in painted_atmosphere_ids:
        # Independent event nodes now own both the subject and its motion.
        # Keeping the old full-scene accents would draw a second weather layer.
        return
    match id:
        "aurora": _draw_aurora(t, alpha)
        "star_whale": _draw_star_whale(t, alpha)
        "time_ripple": _draw_time_ripple(t, alpha)
        "tree_spirit": _draw_tree_spirit(t, alpha)
        "lanterns": _draw_lanterns(t, alpha)
        "ghost_train": _draw_ghost_train(t, alpha)
        "moon_gate": _draw_moon_gate(t, alpha)
        "signal_echo": _draw_signal_echo(t, alpha)
        "aurora_crown": _draw_aurora_crown(t,alpha)
        "ember_clouds": _draw_ember_clouds(t,alpha)
        "meteor_shower": _draw_meteor_shower(t,alpha)
        "deep_one": _draw_deep_one(t,alpha)
        "sunken_city": _draw_sunken_city(t,alpha)
        "sky_jellyfish": _draw_sky_jellyfish(t,alpha)
        "twin_moons": _draw_twin_moons(t,alpha)
        "floating_isles": _draw_floating_isles(t,alpha)
        "bioluminescent_tide": _draw_bioluminescent_tide(t,alpha)
        "constellation_stag": _draw_constellation_stag(t,alpha)

func _draw_painted_details(id: String, t: float, alpha: float) -> void:
    # Full-scene encounter art supplies all silhouettes, celestial bodies and
    # cloud forms. These deliberately small accents only give that art life.
    match id:
        "aurora_crown":
            _draw_painted_motes(t * 0.55, alpha * 0.42, Color("b9ded3"), 14, 76, 16)
            _water_glow(t * 0.6, alpha * 0.8, Color("94cfc2"), 13)
        "ember_clouds":
            _draw_painted_motes(t * 0.35, alpha * 0.3, Color("efcaa1"), 8, 190, -25)
            _water_glow(t * 0.7, alpha, Color("e6bf8c"), 19)
        "meteor_shower":
            for index in range(4):
                var phase: float = fmod(t + index * 5.6, 18.0)
                if phase > 1.9:
                    continue
                var progress: float = phase / 1.9
                var p: Vector2 = Vector2(600 + index * 129, 78 + index % 3 * 42) + Vector2(103, 54) * progress
                var light: float = sin(progress * PI) * alpha * 0.63
                for tail in range(8):
                    draw_rect(Rect2((p - Vector2(tail * 2.8, tail * 1.4)).round(), Vector2(2, 1)),
                        Color(0.86, 0.92, 0.97, light * (1.0 - tail / 8.0)))
        "deep_one":
            # Ripples may move, but the old procedural head and tentacles must
            # never compete with the painted creature.
            _draw_painted_water_ripples(t * 0.5, alpha * 0.19, Color("92b5b6"), 4)
        "sunken_city":
            for index in range(7):
                var p: Vector2 = Vector2(540 + index * 48 + sin(t * 0.08 + index) * 12,
                    532 + index % 3 * 17 + sin(t * 0.12 + index) * 3)
                if _is_open_water(p):
                    draw_rect(Rect2(p.round(), Vector2(22 + index % 3 * 11, 2)),
                        Color(0.72, 0.85, 0.83, alpha * (0.055 + sin(t * 0.2 + index) * 0.015)))
            _water_glow(t * 0.4, alpha * 0.55, Color("b3cfca"), 10)
        "sky_jellyfish":
            _draw_painted_motes(t * 0.6, alpha * 0.4, Color("dbd4f0"), 15, 110, -34)
        "twin_moons":
            _water_glow(t * 0.65, alpha, Color("d5e2eb"), 24)
            _draw_painted_motes(t * 0.2, alpha * 0.24, Color("dfe8ee"), 7, 75, 2)
        "floating_isles":
            _draw_painted_motes(t * 0.5, alpha * 0.38, Color("e2d6ab"), 17, 208, 65)
        "bioluminescent_tide":
            _draw_painted_water_ripples(t * 0.65, alpha * 0.32, Color("87dcd9"), 6)
            _water_glow(t, alpha, Color("83d4d6"), 11)
        "constellation_stag":
            _draw_painted_motes(t * 0.32, alpha * 0.46, Color("e0e6ef"), 14, 130, 3)
            _water_glow(t * 0.35, alpha * 0.45, Color("c8d6e5"), 10)

func _draw_painted_motes(t: float, alpha: float, color: Color, count: int, top: float, travel: float) -> void:
    for index in range(count):
        var phase: float = fmod(t * 0.05 + index * 0.173, 1.0)
        var p: Vector2 = Vector2(555 + fmod(index * 67.0, 610.0) + sin(t * 0.1 + index) * 8,
            top + fmod(index * 31.0, 103.0) + phase * travel)
        var c: Color = color
        c.a = alpha * sin(phase * PI) * (0.6 + sin(t * 0.6 + index) * 0.3)
        draw_rect(Rect2(p.round(), Vector2(2, 2)), c)

func _draw_painted_water_ripples(t: float, alpha: float, color: Color, count: int) -> void:
    for index in range(count):
        var phase: float = fmod(t * 0.065 + index * 0.19, 1.0)
        var center: Vector2 = Vector2(590 + index % 3 * 108, 523 + phase * 58)
        var c: Color = color
        c.a = alpha * sin(phase * PI)
        for segment in range(5):
            var p: Vector2 = center + Vector2((segment - 2) * 13, sin(segment * 0.7 + t * 0.2) * 2)
            if _is_open_water(p) and _is_open_water(p + Vector2(9, 0)):
                draw_rect(Rect2(p.round(), Vector2(9, 1)), c)

func _draw_aurora(t: float, alpha: float) -> void:
    # Narrow translucent curtains leave the mountains and clouds readable.
    for band in range(3):
        var points: PackedVector2Array = PackedVector2Array()
        for index in range(31):
            var x: float = 640.0 + float(index) * 17.0
            var y: float = 92.0 + float(band) * 24.0 + sin(float(index) * 0.17 + t * 0.12 + band) * 24.0
            points.append(Vector2(x, y).round())
        for index in range(30, -1, -1):
            var x: float = 640.0 + float(index) * 17.0
            var y: float = 112.0 + float(band) * 24.0 + sin(float(index) * 0.17 + t * 0.12 + band) * 24.0
            points.append(Vector2(x, y).round())
        var color: Color = Color("80c7ba") if band < 2 else Color("b3a2ca")
        color.a = alpha * (0.1 if band == 0 else 0.065)
        draw_colored_polygon(points, color)
        for index in range(28):
            var x: float = 656.0 + float(index) * 18.0
            var y: float = 97.0 + float(band) * 24.0 + sin(float(index) * 0.18 + t * 0.12 + band) * 24.0
            var height: float = 13.0 + sin(float(index) * 0.4 + t * 0.16) * 6.0
            draw_rect(Rect2(Vector2(x, y).round(), Vector2(2, height)), Color(color.r, color.g, color.b, alpha * 0.055))

func _draw_star_whale(t: float, alpha: float) -> void:
    var pos: Vector2 = _whale_position(t)
    var body: Array[String] = [
        "..........OOOOOOOOOOO..........", ".......OOOBBBBBBBBBBBOOO.......", ".....OOBBBBBBLLBBBBBBBBBOO.....",
        "....OBBBBBBLLLLLLBBBBBBBBBO....", "...OBBBBLLLLLLLLLLBBBBBBBBBO...", "..OBBBBLLLLLLLLLLLLBBBBBBBBBO..",
        ".OBBBBLLLLLLLLLLLLLLBBBBBBBBBO.", "OBBBBBLLLLLLLLLLLLLLLBBBBBEBBO.", "OBBBBBLLLLLLLLLLLLLLLLBBBBBBOO.",
        ".OBBBBBLLLLLLLLLLLLLLLLBBBBBO..", "..OBBBBBBLLLLLLLLLLLLLLBBBBO...", "...OOBBBBBBLLLLLLLLLLBBBBOO....",
        ".....OOOBBBBBBBBBBBBBOOO.......", "........OOOOOOOOOOOOO.........."
    ]
    var palette: Dictionary = {"O": Color("718da9"), "B": Color("97b0c9"), "L": Color("c5d1de"), "E": Color("394f6c")}
    draw_set_transform(pos.round(), 0.0, Vector2(3.0, 3.0))
    var tail_y: float = roundf(sin(t * 0.85) * 2.0 * activity_blend)
    var tail: PackedVector2Array = PackedVector2Array([Vector2(-13, -1), Vector2(-23, -7 + tail_y), Vector2(-20, -1 + tail_y), Vector2(-24, 6 + tail_y), Vector2(-13, 3)])
    draw_colored_polygon(tail, Color(0.54, 0.67, 0.78, alpha * 0.86))
    _pixel_pattern(body, palette, Vector2(-15, -7), alpha * 0.9, false)
    draw_colored_polygon(PackedVector2Array([Vector2(0, 3), Vector2(7, 10 + tail_y), Vector2(9, 5)]), Color(0.55, 0.68, 0.8, alpha * 0.82))
    draw_rect(Rect2(10, 2, 3, 1), Color(0.73, 0.79, 0.87, alpha))
    draw_set_transform(Vector2.ZERO)
    for index in range(12):
        var phase: float = fmod(t * 0.35 + float(index) * 0.193, 1.0)
        var particle: Vector2 = pos - Vector2(70.0 + phase * 110.0, -sin(float(index) * 2.1 + t * 0.17) * 17.0)
        var glow: float = alpha * (1.0 - phase) * 0.46
        draw_rect(Rect2(particle.round(), Vector2(2, 2)), Color(0.77, 0.86, 0.93, glow))
        if index % 4 == 0:
            draw_rect(Rect2((particle - Vector2(2, -1)).round(), Vector2(6, 1)), Color(0.77, 0.86, 0.93, glow * 0.6))

func _draw_time_ripple(t: float, alpha: float) -> void:
    var center: Vector2 = Vector2(924, 281)
    for ring in range(3):
        var phase: float = fmod(t * 0.115 + float(ring) / 3.0, 1.0)
        var radius: float = 17.0 + phase * 53.0
        var opacity: float = alpha * sin(phase * PI) * 0.48
        for segment in range(36):
            if segment % 9 == 0:
                continue
            var angle: float = float(segment) / 36.0 * TAU + t * 0.045
            var next_angle: float = (float(segment) + 0.68) / 36.0 * TAU + t * 0.045
            var a: Vector2 = center + Vector2(cos(angle), sin(angle) * 0.75) * radius
            var b: Vector2 = center + Vector2(cos(next_angle), sin(next_angle) * 0.75) * radius
            draw_line(a.round(), b.round(), Color(0.28, 0.38, 0.44, opacity * 0.35), 3.0)
            draw_line(a.round(), b.round(), Color(0.97, 0.88, 0.71, opacity), 1.7)
        var point: Vector2 = center + Vector2(cos(t * 0.2 + ring * 2.0), sin(t * 0.2 + ring * 2.0) * 0.75) * radius
        draw_rect(Rect2(point.round(), Vector2(3, 3)), Color(0.89, 0.79, 0.64, opacity * 1.3))

func _draw_tree_spirit(t: float, alpha: float) -> void:
    var pos: Vector2 = Vector2(341, 241) + Vector2(sin(t * 0.29) * 3.0, sin(t * 0.44) * 3.0) * activity_blend
    var pattern: Array[String] = [
        ".......O........", "......OLO.......", ".....OLLO.......", "...OOLLLLOO.....", "..OLLLLLLLLO....",
        ".OLLLLLLLLLLO...", "OLLLLLLLLLLLLO..", "OLLLLLLLLLLLLO..", ".OLLLLLLLLLLLO..", "..OLLLLLLLLLO...",
        "...OLLLLLLLO....", "....OLLLLLO.....", ".....OLLLO......", "......OLO.......", ".......O........"
    ]
    var palette: Dictionary = {"O": Color(0.4, 0.67, 0.58, 0.36), "L": Color(0.36, 0.64, 0.55, 0.12)}
    draw_set_transform(pos.round(), 0.0, Vector2(2.8, 2.8))
    _pixel_pattern(pattern, palette, Vector2(-7, -18), alpha, false)
    var blink: bool = fmod(t, 6.4) < 0.22
    var breathing: float = 0.62 + sin(t * 0.7) * 0.12
    for x in [-3, 3]:
        draw_rect(Rect2(x - 1, -10, 4, 3), Color(0.55, 0.81, 0.64, alpha * 0.08))
        draw_rect(Rect2(x, -9, 2, 1 if blink else 2), Color(0.62, 0.83, 0.68, alpha * breathing))
    draw_set_transform(Vector2.ZERO)
    for index in range(3):
        var point: Vector2 = pos + Vector2(sin(t * 0.2 + index * 2.0) * 27.0, -25.0 + cos(t * 0.24 + index) * 20.0)
        draw_rect(Rect2(point.round(), Vector2(3, 2)), Color(0.55, 0.76, 0.57, alpha * 0.18))

func _draw_window_life() -> void:
    # These rectangles are confined to existing distant window panes.
    var evening: float = weather_weights[2] + weather_weights[3] * 0.6 + weather_weights[1] * 0.22
    var panes: Array[Rect2] = [Rect2(1303, 223, 21, 21), Rect2(1335, 218, 20, 24), Rect2(1130, 483, 22, 30)]
    for index in range(panes.size()):
        var cycle: float = fmod(clock_time / 45.0 + float(index) * 0.29, 1.0)
        var lit: float = smoothstep(0.12, 0.2, cycle) * (1.0 - smoothstep(0.72, 0.8, cycle))
        draw_rect(panes[index], Color(1.0, 0.78, 0.43, lit * evening * 0.1))
    var shadow_cycle: float = fmod(clock_time, 61.0)
    if shadow_cycle > 12.0 and shadow_cycle < 24.0:
        var visibility: float = sin((shadow_cycle - 12.0) / 12.0 * PI) * 0.16
        var person: Vector2 = Vector2(1328.0 + sin(shadow_cycle * 0.16) * 8.0, 468)
        draw_rect(Rect2(person.round(), Vector2(5, 6)), Color(0.17, 0.24, 0.23, visibility))
        draw_rect(Rect2((person + Vector2(-2, 6)).round(), Vector2(9, 16)), Color(0.17, 0.24, 0.23, visibility))
    # A few new leaf tips join the small pot without moving its painted base.
    var sway: float = sin(clock_time * 0.65) * 1.4 * activity_blend
    var leaf: Color = _ambient_color(Color("6b874c"))
    leaf.a = 0.8
    draw_line(Vector2(233, 672), Vector2(237 + sway, 656), leaf, 2.0)
    draw_rect(Rect2(Vector2(233 + sway, 656).round(), Vector2(6, 3)), leaf)
    draw_rect(Rect2(Vector2(237 + sway, 662).round(), Vector2(6, 3)), leaf)

func set_attraction(id: String) -> void:
    attraction = id if id in ["seeds", "fruit", "flowers", "lantern"] else "seeds"
    queue_redraw()

func get_beacon_levels() -> Array[float]:
    var levels: Array[float] = []
    for index in range(TOWER_BASES.size()):
        var period: float = 5.4 + float(index) * 1.3
        var phase: float = fmod(clock_time + float(index) * 1.65, period) / period
        var pulse: float = smoothstep(0.06, 0.11, phase) * (1.0 - smoothstep(0.22, 0.33, phase))
        levels.append(0.12 + pulse * (0.43 if quiet else 0.84))
    return levels

func _draw_signal_towers() -> void:
    var levels: Array[float] = get_beacon_levels()
    var visibility: float = 1.0 - weather_weights[5] * 0.42 - weather_weights[6] * 0.17
    for index in range(TOWER_BASES.size()):
        var base: Vector2 = TOWER_BASES[index]
        var height: float = TOWER_HEIGHTS[index]
        var top: Vector2 = base - Vector2(0, height)
        var half_span: float = 5.0 if index==0 else 3.2
        var steel: Color = _ambient_color(Color("607b7d") if index==0 else Color("8ca2a1"))
        steel.a = visibility * (0.78 if index==0 else 0.46)
        draw_line(base - Vector2(half_span,0), top, steel, 1.4 if index==0 else 1.0)
        draw_line(base + Vector2(half_span,0), top, steel, 1.4 if index==0 else 1.0)
        draw_line(top, top - Vector2(0,5), steel, 1.0)
        for level in range(1,5):
            var y: float = height * float(level) / 5.0
            var half_width: float = half_span * float(level) / 5.0
            draw_line(top + Vector2(-half_width,y), top + Vector2(half_width,y), steel, 1.0)
            draw_line(top + Vector2(-half_width,y), top + Vector2(half_width+1.0,y+height/5.0), steel, 1.0)
        draw_rect(Rect2(top + Vector2(-5,8),Vector2(10,1)),steel)
        var lamp: Vector2 = top - Vector2(1,6)
        var intensity: float = levels[index] * visibility * (1.0 if index==0 else 0.72)
        draw_rect(Rect2(lamp-Vector2(3,3),Vector2(8,8)),Color(1.0,0.43,0.28,intensity*0.055))
        draw_rect(Rect2(lamp-Vector2(1,1),Vector2(4,4)),Color(1.0,0.56,0.35,intensity*0.24))
        draw_rect(Rect2(lamp,Vector2(2,2)),Color(1.0,0.74,0.49,intensity))

func _water_top(x: float) -> float:
    var shore: Array[Vector2] = [Vector2(285,563),Vector2(470,510),Vector2(620,458),Vector2(700,472),Vector2(780,504),Vector2(945,518),Vector2(1015,550)]
    for index in range(shore.size()-1):
        if x<=shore[index+1].x:
            return lerpf(shore[index].y,shore[index+1].y,clampf((x-shore[index].x)/(shore[index+1].x-shore[index].x),0,1))
    return 605.0

func _is_open_water(point: Vector2) -> bool:
    return point.x>=300.0 and point.x<=945.0 and point.y>_water_top(point.x)+3.0 and point.y<597.0

func _draw_distant_town() -> void:
    var evening: float = weather_weights[2] + weather_weights[3]*0.65 + weather_weights[6]*0.4 + weather_weights[1]*0.17 + weather_weights[7]*0.28
    if evening < 0.01:return
    # Three uneven hamlets follow the natural bends; no artificial light strip.
    var windows: Array[Vector2]=[Vector2(395,409),Vector2(430,381),Vector2(450,378),Vector2(468,387),Vector2(478,406),Vector2(514,414),Vector2(565,407),Vector2(590,427),Vector2(845,430),Vector2(859,432),Vector2(981,392),Vector2(1030,371),Vector2(1052,381),Vector2(1080,394)]
    for index in range(windows.size()):
        var p: Vector2=windows[index]
        var pulse: float=0.74+sin(clock_time*0.09+float(index)*2.3)*0.15
        var a: float=evening*pulse*0.58
        draw_rect(Rect2(p,Vector2(2,3)),Color(1.0,0.78,0.47,a))
        if index%2==0:
            for reflection in range(4):
                var rp: Vector2=Vector2(p.x+sin(clock_time*0.55+reflection+index)*2.0,_water_top(p.x)+12+reflection*15)
                if not _is_open_water(rp):continue
                draw_rect(Rect2(rp.round(),Vector2(4+reflection%3*2,1)),Color(0.97,0.73,0.4,a*(0.19-float(reflection)*0.035)))

func _draw_attraction() -> void:
    match attraction:
        "seeds":
            for index in range(6):
                draw_rect(Rect2(1127+index*7,590+index%2*2,3,2),_ambient_color(Color("c99b5c")))
        "fruit":
            for index in range(3):
                var x: float = 1130+index*14
                draw_rect(Rect2(x,581,10,9),_ambient_color(Color("b35f4e")))
                draw_rect(Rect2(x+2,579,6,3),_ambient_color(Color("cf8461")))
                draw_rect(Rect2(x+5,577,2,4),_ambient_color(Color("6d7d45")))
                draw_rect(Rect2(x+2,582,2,2),_ambient_color(Color("e4b78b")))
        "flowers":
            for index in range(4):
                var p: Vector2 = Vector2(232+index*10,639-index%2*8)
                draw_line(p+Vector2(0,19),p,_ambient_color(Color("738650")),2.0)
                draw_rect(Rect2(p-Vector2(5,1),Vector2(12,4)),_ambient_color(Color("c6b8da")))
                draw_rect(Rect2(p-Vector2(1,5),Vector2(4,12)),_ambient_color(Color("c6b8da")))
                draw_rect(Rect2(p,Vector2(3,3)),_ambient_color(Color("e5cc8c")))
        "lantern":
            var p: Vector2 = Vector2(1196,589)
            var glow: float = 0.65+sin(clock_time*0.65)*0.08
            draw_rect(Rect2(p-Vector2(17,31),Vector2(35,39)),Color(1.0,0.72,0.34,glow*0.07))
            draw_rect(Rect2(p-Vector2(9,23),Vector2(19,24)),_ambient_color(Color("5d6653")))
            draw_rect(Rect2(p-Vector2(6,20),Vector2(13,17)),Color(0.97,0.76,0.42,glow))
            draw_rect(Rect2(p-Vector2(11,26),Vector2(23,4)),_ambient_color(Color("667563")))
            draw_rect(Rect2(p-Vector2(2,31),Vector2(5,5)),_ambient_color(Color("667563")))
            draw_rect(Rect2(p-Vector2(11,1),Vector2(23,4)),_ambient_color(Color("667563")))

func _draw_new_bird(id: String, pos: Vector2, t: float, alpha: float) -> void:
    if id=="egret":
        draw_set_transform(pos.round(),0,Vector2(1.2,1.2))
        var leg: float = sin(t*1.5)*2.0*activity_blend
        draw_line(Vector2(-3,-9),Vector2(-4+leg,1),_visitor_ink("65694e",alpha),1.3)
        draw_line(Vector2(3,-9),Vector2(4-leg,1),_visitor_ink("65694e",alpha),1.3)
        var form: Array[String] = ["...........WWWW.....","..........WCCCCWBBBB","..........WCCCCW....","...........WWCW.....","............WCW.....","............WCW.....","............WCW.....","...........WCW......","...WWWWWWWWCW.......","..WCCCCCCCCWW.......",".WCCCCCCCCCCW.......","WCCCCCCCCCCW........",".WWCCCCCCWW.........","...WWWWWW..........."]
        var neck_palette: Dictionary = {"W":Color("a9bcb5"),"C":Color("eee9cc"),"B":Color("bba16b")}
        for row in range(form.size()):
            _pixel_pattern([form[row]],neck_palette,Vector2(-12 + (roundf(sin(t*0.75)) if row<7 else 0.0),row-24),alpha)
        draw_rect(Rect2(1,-22,1,1),_visitor_ink("344b48",alpha))
        draw_set_transform(Vector2.ZERO)
        draw_line(pos+Vector2(-16,5),pos+Vector2(18,5),Color(0.82,0.88,0.83,alpha*0.2),1.0)
        return
    if id=="swallow":
        draw_set_transform(pos.round(),0,Vector2(2.0,2.0))
        var wing: float = roundf(sin(t*7.0)*5.0*activity_blend)
        var c: Color = _visitor_ink("3c5562",alpha)
        draw_colored_polygon(PackedVector2Array([Vector2(-2,0),Vector2(-12,-10+wing),Vector2(-16,-10+wing),Vector2(-7,3),Vector2(1,3)]),c)
        draw_colored_polygon(PackedVector2Array([Vector2(1,0),Vector2(10,-10+wing),Vector2(15,-10+wing),Vector2(6,3),Vector2(-1,3)]),c)
        draw_colored_polygon(PackedVector2Array([Vector2(-3,2),Vector2(-7,13),Vector2(0,7),Vector2(6,13),Vector2(3,2)]),c)
        draw_rect(Rect2(-3,-5,7,11),c)
        draw_rect(Rect2(-1,0,3,5),_visitor_ink("dfd8b5",alpha))
        draw_rect(Rect2(1,-4,1,1),_visitor_ink("142a36",alpha))
        draw_set_transform(Vector2.ZERO)
        return
    var head: Color = Color("4d958c")
    var body: Color = Color("d59b63")
    var wing: Color = Color("447b93")
    if id=="magpie":head=Color("384f59");body=Color("e2dfc9");wing=Color("415966")
    elif id=="white_eye":head=Color("96a45d");body=Color("d7cc83");wing=Color("748d51")
    var palette: Dictionary = {"O":Color("354b4b"),"H":head,"E":Color("172e38"),"B":Color("7c8065"),"W":wing,"C":body,"T":wing.darkened(0.08),"L":Color("626746")}
    draw_set_transform((pos+Vector2(0,sin(t*1.7)*0.45*activity_blend)).round(),float(_drawing_actor.get("body_tilt",0.0)),Vector2(2.55 * float(_drawing_actor.get("facing",1.0)),2.55))
    var flying: bool = bool(_drawing_actor.get("fly",false))
    for row in range(BIRD_PATTERN.size()):
        var head_shift: float = roundf(sin(t * 0.8)) if row < 5 and not flying else 0.0
        _pixel_pattern([BIRD_PATTERN[row]],palette,Vector2(-9 + head_shift,row-12),alpha)
    if fmod(t + id.length(),5.3) < 0.17:
        draw_rect(Rect2(4,-10,1,1),_visitor_ink(head.to_html(false),alpha))
    if flying:
        var flap: float = sin(t * 15.0)
        var extension: float = 7.0 + float(_drawing_actor.get("travel",1.0)) * 6.0
        _draw_flight_wing(Vector2(-3,-7),Vector2(-8,-3-flap*extension),2.5,_visitor_ink(wing.lightened(0.15).to_html(false),alpha))
        draw_line(Vector2(-5,-8),Vector2(-10,-10-flap*extension),_visitor_ink(wing.darkened(0.2).to_html(false),alpha),1.0)
    if id=="kingfisher":
        draw_rect(Rect2(8,-9,6,1),_visitor_ink("465862",alpha))
        draw_rect(Rect2(4,-6,3,2),_visitor_ink("e3d9b8",alpha))
        var phase: float = fmod(t,16.0)
        if phase>7 and phase<12:
            draw_rect(Rect2(-7,-16+int(t*7)%2*9,7,8),_visitor_ink("68a6ac",alpha))
    elif id=="white_eye":
        draw_rect(Rect2(3,-10,3,3),_visitor_ink("ede8ce",alpha))
        draw_rect(Rect2(4,-9,1,1),_visitor_ink("283f36",alpha))
    elif id=="magpie":
        var tail: float = roundf(sin(t*0.7)*2.0*activity_blend)
        draw_colored_polygon(PackedVector2Array([Vector2(-8,-5),Vector2(-20,-2+tail),Vector2(-25,-2+tail),Vector2(-14,-7),Vector2(-6,-8)]),_visitor_ink("344e5e",alpha))
        draw_rect(Rect2(-5,-8,5,3),_visitor_ink("dedfca",alpha))
    draw_set_transform(Vector2.ZERO)

func _draw_hedgehog(pos: Vector2, t: float, alpha: float) -> void:
    draw_set_transform((pos+Vector2(0,sin(t*2.5)*0.4*activity_blend)).round(),0,Vector2(2.2 * float(_drawing_actor.get("facing",1.0)),2.2))
    var body: Array[String] = [".....O.O.O.O.......","...OOHHOHHOHOO.....","..OHFHFHFHFHFHO....",".OHFHFHFHFHFHFHO...","OHFHFHFHFHFHFHFHOO.","OHFHFHFHFHFHFHCCCCO","OHFHFHFHFHFHCCCCECO",".OHFHFHFHFHCCCCCCCO","..OOFFFFFFCCCCCCOO.","...OOOOOOOOOOOO...."]
    var palette: Dictionary = {"O":Color("536051"),"F":Color("7e7b58"),"H":Color("b2aa7a"),"C":Color("d3bb8b"),"E":Color("273d3c")}
    var face: float = roundf(maxf(0.0, sin(t * 3.3)))
    for row in range(body.size()):
        for col in range(body[row].length()):
            var key: String = body[row].substr(col,1)
            if palette.has(key):
                draw_rect(Rect2(col-10 + (face if col > 12 else 0.0),row-10,1,1),_visitor_ink((palette[key] as Color).to_html(false),alpha))
    draw_rect(Rect2(8+face,-4,2,2),_visitor_ink("344341",alpha))
    var step: float = roundf(sin(t*3.0))
    draw_rect(Rect2(-5+step,0,3,2),_visitor_ink("6a6952",alpha))
    draw_rect(Rect2(5-step,0,3,2),_visitor_ink("6a6952",alpha))
    draw_set_transform(Vector2.ZERO)

func _draw_cat(pos: Vector2, t: float, alpha: float) -> void:
    if str(_drawing_actor.get("phase", "idle")) != "idle":
        var seated: float = float(_drawing_actor.get("land_blend",0.0))
        _draw_walking_cat(pos, t, alpha * (1.0-seated))
        if seated < 0.001: return
        alpha *= seated
    draw_set_transform(pos.round(),0,Vector2(2.5,2.5))
    var body: Array[String] = ["...OO......OO.....","..OFFO....OFFO....","..OFFFOOOOFFFO....","..OFFFFFFFFFFO....","..OFHHFFFFHHFO....","..OFHHFFFFHHFO....","...OFFFCCFFFO.....","....OFFFFFFO......","....OFFFFFFO......","...OFFFFFFFFO.....","..OFFFFFFFFFFO....","..OFFCCCCCCFFO....",".OFFFCCCCCCFFFO...",".OFFFCCCCCCFFFO...",".OFFFCCCCCCFFFO...",".OFFFCCCCCCFFFO...","..OFFCCCCCCFFO....","..OFFFCCCCFFFO....","..OFFFOOOOFFFO....","..OOOO....OOOO...."]
    var palette: Dictionary = {"O":Color("4b5953"),"F":Color("ba9970"),"H":Color("d5c498"),"C":Color("e5d4b0")}
    var groom: bool = str(_drawing_actor.get("pose", "")) == "groom"
    for row in range(body.size()):
        var head_shift: float = roundf(sin(t * 0.5)) if row < 8 else 0.0
        _pixel_pattern([body[row]],palette,Vector2(-9 + head_shift,-21 + row),alpha)
    if groom:
        draw_line(Vector2(-4,-3),Vector2(-6,-12 + sin(t * 4.0)),_visitor_ink("d4bd8d",alpha),3.0)
    var ear_twitch: float = 1.0 if fmod(t, 7.4) > 6.9 else 0.0
    draw_rect(Rect2(-6,-21-ear_twitch,2,2),_visitor_ink("ba9970",alpha))
    var blink: bool = fmod(t,5.1)<0.25
    for x in [-4,3]:
        draw_rect(Rect2(x,-16,2,1 if blink else 2),_visitor_ink("3b5352",alpha))
    draw_rect(Rect2(-1,-13,2,1),_visitor_ink("a97862",alpha))
    draw_line(Vector2(3,-5),Vector2(10,-3),_visitor_ink("9e7c57",alpha),4.0)
    draw_line(Vector2(10,-3),Vector2(16,-2),_visitor_ink("9e7c57",alpha),4.0)
    draw_line(Vector2(16,-2),Vector2(19,-8+sin(t*0.9)*3.0*activity_blend),_visitor_ink("9e7c57",alpha),3.0)
    draw_set_transform(Vector2.ZERO)

func _draw_bat(pos: Vector2, t: float, alpha: float) -> void:
    draw_set_transform(pos.round(),0,Vector2(2.1,2.1))
    var flap: float = sin(t*6.0)*5.0*activity_blend
    var color: Color = _visitor_ink("8d8a9a",alpha)
    for side in [-1.0,1.0]:
        var pts: PackedVector2Array = PackedVector2Array([Vector2(side*2,0),Vector2(side*8,-9+flap),Vector2(side*16,-7+flap),Vector2(side*13,0),Vector2(side*10,-1),Vector2(side*8,4),Vector2(side*5,2),Vector2(side*2,6)])
        draw_colored_polygon(pts,color)
        draw_line(Vector2(side*3,0),Vector2(side*13,-5+flap),_visitor_ink("605f73",alpha),1.0)
    draw_rect(Rect2(-3,-4,6,12),_visitor_ink("5c6574",alpha))
    draw_rect(Rect2(-3,-7,2,4),_visitor_ink("6c6c7e",alpha))
    draw_rect(Rect2(1,-7,2,4),_visitor_ink("6c6c7e",alpha))
    draw_rect(Rect2(-2,-2,1,1),_visitor_ink("d9c897",alpha))
    draw_rect(Rect2(1,-2,1,1),_visitor_ink("d9c897",alpha))
    draw_set_transform(Vector2.ZERO)

func _draw_new_insect(id: String, pos: Vector2, t: float, alpha: float) -> void:
    draw_set_transform(pos.round(),0,Vector2(1.9,1.9))
    if id=="dragonfly":
        var width: float = 12.0+sin(t*13.0)*2.0
        var c: Color = _visitor_ink("c9dfd1",alpha*0.65)
        for y in [-3.0,2.0]:
            draw_colored_polygon(PackedVector2Array([Vector2(-1,y),Vector2(-width,y-4),Vector2(-width-3,y-2),Vector2(-6,y+2)]),c)
            draw_colored_polygon(PackedVector2Array([Vector2(1,y),Vector2(width,y-4),Vector2(width+3,y-2),Vector2(6,y+2)]),c)
        draw_rect(Rect2(-1,-8,3,24),_visitor_ink("6ba2a2",alpha))
        draw_rect(Rect2(-3,-8,7,4),_visitor_ink("8bbaac",alpha))
        draw_rect(Rect2(-3,-8,2,2),_visitor_ink("405d60",alpha))
        draw_rect(Rect2(2,-8,2,2),_visitor_ink("405d60",alpha))
    elif id=="ladybug":
        var form: Array[String] = ["...OOOO...","..OHHOHO..",".ORRRRRRO.","ORRRORRRRO","ORORORORRO","ORRRORRRRO","ORORORORRO",".ORRORRRO.","..ORRROO..","...OOO...."]
        _pixel_pattern(form,{"O":Color("43514a"),"H":Color("e2d5ae"),"R":Color("c86f57")},Vector2(-5,-9),alpha)
        var leg: float=roundf(sin(t*2.0))
        for y in [-6,-3,0]:
            draw_line(Vector2(-4,y),Vector2(-7,y+leg),_visitor_ink("596251",alpha),1.0)
            draw_line(Vector2(4,y),Vector2(7,y-leg),_visitor_ink("596251",alpha),1.0)
    else:
        var form: Array[String] = [".O.....O.","OHO...OHO",".OHO.OHO.","..OHOHO..","..OHHHO..",".OHHHHHO.","OHHHHHHHO","OHHLHLHHO","OHHLHLHHO","OHHLHLHHO","OHHHHHHHO",".OHHHHHO.","..OOOOO.."]
        _pixel_pattern(form,{"O":Color("364b43"),"H":Color("877d59"),"L":Color("b5a574")},Vector2(-4,-15),alpha)
        for y in [-8,-5,-2]:
            var leg: float=roundf(sin(t*1.7+float(y)))
            draw_line(Vector2(-4,y),Vector2(-7,y+leg),_visitor_ink("687456",alpha),1.0)
            draw_line(Vector2(4,y),Vector2(7,y-leg),_visitor_ink("687456",alpha),1.0)
    if id != "dragonfly":
        var antenna: float = sin(t * 1.7) * 1.3
        for side in [-1.0, 1.0]:
            draw_line(Vector2(side*2,-9 if id=="ladybug" else -11),Vector2(side*(5+antenna),-13 if id=="ladybug" else -15),_visitor_ink("687456",alpha),1.0)
    draw_set_transform(Vector2.ZERO)

func _draw_lanterns(t: float, alpha: float) -> void:
    for index in range(9):
        var x: float=450+index*57-t*3.0
        var p: Vector2=Vector2(x,minf(584,_water_top(x)+20+index%3*13)+sin(t*0.5+index)*2.0)
        var c: Color=Color(0.97,0.69,0.36,alpha*0.78)
        draw_rect(Rect2(p-Vector2(5,6),Vector2(10,7)),c)
        draw_rect(Rect2(p-Vector2(3,8),Vector2(6,3)),Color(1.0,0.88,0.58,alpha))
        draw_rect(Rect2(p+Vector2(-7,1),Vector2(14,2)),Color(0.49,0.51,0.42,alpha*0.8))
        for row in range(3):
            var rp: Vector2=p+Vector2(sin(t+row+index)*2-3,6+row*5)
            if _is_open_water(rp):draw_rect(Rect2(rp,Vector2(7+row*2,1)),Color(1.0,0.72,0.39,alpha*(0.24-row*0.06)))

func _rail_y(x: float) -> float:
    if x<550:return lerpf(454,445,clampf((x-440)/110.0,0,1))
    return lerpf(445,436,clampf((x-550)/130.0,0,1))

func _draw_ghost_train(t: float, alpha: float) -> void:
    var front_x: float=466.0+t*6.8
    for index in range(5):
        var x: float=front_x-float(index)*25.0
        if x<440 or x>679:continue
        var p: Vector2=Vector2(x,_rail_y(x)-2)
        draw_rect(Rect2(p-Vector2(0,7),Vector2(23,8)),Color(0.59,0.76,0.77,alpha*0.27))
        draw_rect(Rect2(p-Vector2(1,9),Vector2(25,2)),Color(0.76,0.86,0.82,alpha*0.3))
        for win in range(3):
            draw_rect(Rect2(p+Vector2(3+win*6,-5),Vector2(3,3)),Color(0.98,0.85,0.58,alpha*0.72))
        draw_rect(Rect2(p+Vector2(3,1),Vector2(3,2)),Color(0.66,0.79,0.79,alpha*0.35))
        draw_rect(Rect2(p+Vector2(18,1),Vector2(3,2)),Color(0.66,0.79,0.79,alpha*0.35))
    for segment in range(12):
        var x: float=440+segment*20
        draw_line(Vector2(x,_rail_y(x)+2),Vector2(x+20,_rail_y(x+20)+2),Color(0.7,0.84,0.8,alpha*0.11),1.0)

func _draw_moon_gate(t: float, alpha: float) -> void:
    var center: Vector2=Vector2(860,159)
    var breath: float=sin(t*0.4)*2.0*activity_blend
    for ring in range(3):
        for segment in range(60):
            var angle: float=float(segment)/60.0*TAU
            var p: Vector2=center+Vector2(cos(angle)*(48+ring*3+breath),sin(angle)*(64+ring*3+breath))
            var shimmer: float=0.58+sin(angle*3+t*0.3)*0.17
            draw_rect(Rect2(p.round(),Vector2(2,3)),Color(0.70,0.85,0.92,alpha*shimmer*(1.0-float(ring)*0.25)))
    for index in range(13):
        var p: Vector2=center+Vector2(sin(float(index)*2.4)*34,cos(float(index)*1.7)*46)
        draw_rect(Rect2(p.round(),Vector2(2,2)),Color(0.95,0.91,0.73,alpha*(0.38+sin(t*0.5+index)*0.14)))
    draw_line(center+Vector2(-46,67),center+Vector2(46,67),Color(0.74,0.88,0.91,alpha*0.35),2.0)

func _draw_signal_echo(t: float, alpha: float) -> void:
    var sequence: float=fmod(t,8.4)
    for index in range(TOWER_BASES.size()):
        var local: float=fposmod(sequence-float(index)*2.0,8.4)
        if local>3.0:continue
        var center: Vector2=TOWER_BASES[index]-Vector2(0,TOWER_HEIGHTS[index]+7)
        var phase: float=local/3.0
        var glow: float=alpha*sin(phase*PI)*0.65
        draw_rect(Rect2(center-Vector2(2,2),Vector2(5,5)),Color(0.67,0.91,0.86,glow))
        for point in range(24):
            var angle: float=float(point)/24.0*TAU
            var p: Vector2=center+Vector2(cos(angle),sin(angle)*0.65)*(8+phase*34)
            draw_rect(Rect2(p.round(),Vector2(2,1)),Color(0.61,0.86,0.81,glow*(1-phase)))

func _pixel_oval(center: Vector2, radius: Vector2, color: Color, step: float=3.0, clip_y: float=INF) -> void:
    var y: float=-radius.y
    while y<=radius.y:
        if center.y+y>clip_y:break
        var half_width: float=radius.x*sqrt(maxf(0,1.0-y*y/(radius.y*radius.y)))
        draw_rect(Rect2(Vector2(center.x-half_width,center.y+y).round(),Vector2(maxf(2,half_width*2),step)),color)
        y+=step

func _water_glow(t: float, alpha: float, color: Color, width: float=18.0) -> void:
    for index in range(28):
        var p: Vector2=Vector2(510+fmod(float(index*67),450.0),510+fmod(float(index*31),78.0))
        if not _is_open_water(p):continue
        var wave: float=0.45+sin(t*0.6+float(index)*1.9)*0.2
        var c: Color=color
        c.a=alpha*wave*0.26
        draw_rect(Rect2(p+Vector2(sin(t*0.2+index)*4,0),Vector2(minf(width+index%4*7,945-p.x),2)),c)

func _draw_aurora_crown(t: float, alpha: float) -> void:
    var colors: Array[Color]=[Color("82cabb"),Color("a5cdb4"),Color("a9b2d6"),Color("c5acd2")]
    var center: Vector2=Vector2(863,257)
    for band in range(4):
        for segment in range(72):
            var angle: float=PI+float(segment)/71.0*PI
            var radius: float=147+band*17+sin(t*0.17+float(segment)*0.15)*8
            var p: Vector2=center+Vector2(cos(angle)*radius*1.4,sin(angle)*radius*0.85)
            var height: float=13+sin(float(segment)*0.21+t*0.22)*8+band*2
            var c: Color=colors[band]
            c.a=alpha*(0.24+sin(float(segment)*0.19+t*0.13)*0.05)
            draw_rect(Rect2(p.round(),Vector2(5,height)),c)
            if segment%4==0:
                c.a=alpha*0.40
                draw_rect(Rect2(p.round(),Vector2(2,3)),c)
    for ray in range(9):
        var angle: float=PI+float(ray+1)/10.0*PI
        var p: Vector2=center+Vector2(cos(angle)*235,sin(angle)*145)
        var end: Vector2=center+Vector2(cos(angle)*275,sin(angle)*185)
        draw_line(p.round(),end.round(),Color(0.69,0.87,0.82,alpha*0.24),2.0)
    _water_glow(t,alpha,Color("9acdc7"),22)

func _draw_ember_clouds(t: float, alpha: float) -> void:
    var colors: Array[Color]=[Color("bd8799"),Color("d4a092"),Color("e2b095")]
    for layer in range(3):
        for segment in range(26):
            var x: float=560+segment*23+sin(t*0.065+layer)*12
            var y: float=94+layer*45+sin(segment*0.36+t*0.10+layer)*15
            var width: float=32+sin(segment*1.4)*10
            var c: Color=colors[layer]
            c.a=alpha*(0.30+float(layer)*0.035)
            draw_rect(Rect2(Vector2(x,y).round(),Vector2(width,13+layer*4)),c)
            c.a*=0.7
            draw_rect(Rect2(Vector2(x+8,y-5).round(),Vector2(width-9,5)),c)
            draw_rect(Rect2(Vector2(x+4,y+14+layer*4).round(),Vector2(width-5,4)),c)
    _water_glow(t,alpha,Color("e2bc83"),30)

func _draw_meteor_shower(t: float, alpha: float) -> void:
    var count: int=5 if quiet else 10
    for index in range(count):
        var phase: float=fmod(t+float(index)*2.73,12.0)
        if phase>3.3:continue
        var progress: float=phase/3.3
        var start: Vector2=Vector2(560+fmod(float(index*137),420.0),48+fmod(float(index*31),85.0))
        var end: Vector2=start+Vector2(160+index%3*25,80+index%4*13)
        var p: Vector2=start.lerp(end,progress)
        var light: float=sin(progress*PI)*alpha*0.85
        for trail in range(13):
            var tail: Vector2=p-Vector2(trail*4.0,trail*2.2)
            draw_rect(Rect2(tail.round(),Vector2(3,2)),Color(0.92,0.91,0.74,light*(1-float(trail)/13.0)))
        draw_rect(Rect2(p.round(),Vector2(3,3)),Color(0.97,0.98,0.91,light))

func _draw_deep_one(t: float, alpha: float) -> void:
    # The silhouette rises in the open channel, away from the curved peninsula.
    var emergence: float=smoothstep(0,8,t)
    var center: Vector2=Vector2(654,590-emergence*56+sin(t*0.19)*1.8)
    var skin: Color=Color(0.12,0.28,0.29,alpha*0.82)
    var edge: Color=Color(0.30,0.49,0.47,alpha*0.4)
    for side in [-1.0,1.0]:
        for arm in range(4):
            var points: PackedVector2Array=PackedVector2Array()
            for joint in range(22):
                var u: float=float(joint)/21.0
                var x: float=center.x+side*(22+u*(88+arm*13))
                var y: float=center.y+23+sin(u*PI*1.6+t*0.31+arm*0.78)*(14+arm*2)-u*(19-arm*3)
                y=minf(588,maxf(y,_water_top(x)+11))
                points.append(Vector2(x,y).round())
            for joint in range(points.size()-1):
                var taper: float=1.0-float(joint)/float(points.size())
                draw_line(points[joint],points[joint+1],skin,3+taper*8)
                if joint%2==0:draw_line(points[joint]+Vector2(0,-2),points[joint+1]+Vector2(0,-2),edge,1.0)
    _pixel_oval(center,Vector2(48,45),skin,3,590)
    _pixel_oval(center+Vector2(-7,-12),Vector2(34,31),Color(0.21,0.37,0.35,alpha*0.33),3,590)
    for fold in range(5):
        var x: float=center.x-24+fold*12
        var points: PackedVector2Array=PackedVector2Array()
        for joint in range(11):
            var y: float=center.y+7+joint*4.4
            if y>590:break
            points.append(Vector2(x+sin(joint*0.4+t*0.3+fold)*5,y).round())
        for joint in range(points.size()-1):draw_line(points[joint],points[joint+1],skin,5.0)
    for side in [-1,1]:
        var eye: Vector2=center+Vector2(side*17,-3)
        draw_rect(Rect2(eye-Vector2(5,2),Vector2(10,3)),Color(0.56,0.69,0.48,alpha*0.47*emergence))
        draw_rect(Rect2(eye,Vector2(2,3)),Color(0.15,0.28,0.28,alpha*0.9))
    for ripple in range(4):
        var y: float=566+ripple*7
        var x: float=520+sin(t*0.2+ripple)*8
        draw_line(Vector2(x,y),Vector2(790+cos(t*0.2+ripple)*8,y),Color(0.44,0.66,0.64,alpha*(0.24-ripple*0.035)),2.0)

func _draw_sunken_city(t: float, alpha: float) -> void:
    var rise: float=smoothstep(0,9,t)
    var center: Vector2=Vector2(675,581)
    var stone: Color=Color(0.28,0.49,0.49,alpha*0.62)
    var edge: Color=Color(0.67,0.82,0.71,alpha*0.60)
    for tower in range(7):
        var x: float=center.x-105+tower*34
        var max_height: float=33+float((tower*19)%44)
        if tower==3:max_height=103
        var top: float=center.y-max_height*rise
        top=maxf(top,_water_top(x)+5)
        var height: float=center.y-top
        for step in range(5):
            var y: float=center.y-height*float(step+1)/5.0
            var width: float=36-float(step)*5
            draw_rect(Rect2(Vector2(x-width*0.5,y).round(),Vector2(width,height/5+2)),stone)
            draw_rect(Rect2(Vector2(x-width*0.5,y).round(),Vector2(width,1)),edge)
        if tower%2==0:
            for window in range(3):
                draw_rect(Rect2(x-6+window*5,center.y-height*0.5,2,4),Color(0.88,0.83,0.57,alpha*rise*0.37))
    for step in range(6):
        draw_rect(Rect2(center.x-34-step*7,576+step*2,68+step*14,1),edge)
    _water_glow(t,alpha*0.75,Color("8fbfb1"),16)

func _draw_sky_jellyfish(t: float, alpha: float) -> void:
    var colors: Array[Color]=[Color("a9d4d3"),Color("b6b0d5"),Color("d0bad4"),Color("a3c6dc")]
    for index in range(4):
        var p: Vector2=Vector2(670+index*120+sin(t*0.12+index)*18,145+(index%2)*44-sin(t*0.19+index)*16)
        var radius: float=24+index%3*7
        var pulse: float=1+sin(t*0.8+index)*0.09*activity_blend
        var bell: PackedVector2Array=PackedVector2Array()
        for segment in range(20):
            var angle: float=PI+float(segment)/19.0*PI
            bell.append((p+Vector2(cos(angle)*radius*pulse,sin(angle)*radius*0.72*pulse)).round())
        for segment in range(7,-1,-1):
            bell.append((p+Vector2(-radius+float(segment)/7.0*radius*2,4+sin(segment*PI/2+t*0.5)*2)).round())
        var c: Color=colors[index]
        c.a=alpha*0.27
        draw_colored_polygon(bell,c)
        c.a=alpha*0.59
        for segment in range(19):draw_line(bell[segment],bell[segment+1],c,1.6)
        for strand in range(5):
            var prev: Vector2=p+Vector2((strand-2)*radius*0.28,5)
            for joint in range(1,15):
                var next: Vector2=p+Vector2((strand-2)*radius*0.28+sin(joint*0.39+t*0.5+strand)*5,5+joint*3.3)
                c.a=alpha*(0.43-float(joint)*0.019)
                draw_line(prev.round(),next.round(),c,1.5)
                prev=next
        draw_rect(Rect2(p+Vector2(-2,-7),Vector2(4,4)),Color(0.89,0.94,0.82,alpha*0.55))

func _draw_twin_moons(t: float, alpha: float) -> void:
    var p: Vector2=Vector2(716,166-smoothstep(0,9,t)*35+sin(t*0.13)*2)
    _pixel_oval(p,Vector2(31,31),Color(0.77,0.85,0.88,alpha*0.58),2)
    _pixel_oval(p+Vector2(-10,-8),Vector2(8,6),Color(0.52,0.67,0.73,alpha*0.2),2)
    _pixel_oval(p+Vector2(11,9),Vector2(5,9),Color(0.52,0.67,0.73,alpha*0.18),2)
    for segment in range(68):
        var angle: float=float(segment)/68.0*TAU+t*0.018
        var a: Vector2=Vector2(cos(angle)*68,sin(angle)*20).rotated(-0.25)
        draw_rect(Rect2((p+a).round(),Vector2(2,1)),Color(0.75,0.87,0.9,alpha*0.34))
    _water_glow(t,alpha*0.7,Color("a9c9d4"),13)

func _draw_floating_isles(t: float, alpha: float) -> void:
    var centers: Array[Vector2]=[Vector2(689,214),Vector2(906,171),Vector2(1090,231)]
    for index in range(3):
        var p: Vector2=centers[index]+Vector2(sin(t*0.095+index)*12,cos(t*0.22+index)*6)*activity_blend
        var size: float=1.0-float(index)*0.18
        draw_set_transform(p.round(),0,Vector2(size,size))
        var rock: PackedVector2Array=PackedVector2Array([Vector2(-47,0),Vector2(-32,23),Vector2(-16,27),Vector2(-5,52),Vector2(6,31),Vector2(23,33),Vector2(48,2),Vector2(26,-7),Vector2(-21,-8)])
        draw_colored_polygon(rock,Color(0.40,0.47,0.46,alpha*0.88))
        draw_colored_polygon(PackedVector2Array([Vector2(-47,0),Vector2(-25,7),Vector2(7,2),Vector2(48,2),Vector2(26,-7),Vector2(-21,-8)]),Color(0.54,0.64,0.43,alpha*0.93))
        draw_line(Vector2(-25,8),Vector2(-5,45),Color(0.62,0.65,0.56,alpha*0.45),2)
        draw_line(Vector2(16,8),Vector2(8,28),Color(0.32,0.40,0.43,alpha*0.6),3)
        for tree in range(2):
            var x: float=-16+tree*28
            draw_rect(Rect2(x,-31,4,26),Color(0.46,0.46,0.34,alpha))
            draw_rect(Rect2(x-8,-37,20,11),Color(0.52,0.65,0.43,alpha*0.9))
            draw_rect(Rect2(x-5,-46,14,12),Color(0.63,0.73,0.47,alpha*0.9))
        draw_set_transform(Vector2.ZERO)
        for dust in range(7):
            var phase: float=fmod(t*0.12+dust*0.143,1.0)
            var dot: Vector2=p+Vector2(sin(dust*2.3)*24*size,35+phase*54)
            draw_rect(Rect2(dot.round(),Vector2(2,2)),Color(0.83,0.83,0.60,alpha*(1-phase)*0.48))

func _draw_bioluminescent_tide(t: float, alpha: float) -> void:
    for band in range(6):
        var phase: float=fmod(t*0.045+float(band)/6.0,1.0)
        var y: float=495+phase*94
        var brightness: float=sin(phase*PI)*alpha
        for segment in range(69):
            var x: float=340+segment*9.5
            var p: Vector2=Vector2(x,y+sin(x*0.022+t*0.35+band)*5)
            if not _is_open_water(p) or p.y>588:continue
            draw_rect(Rect2(p.round(),Vector2(12,4+phase*3)),Color(0.25,0.75,0.78,brightness*0.16))
            draw_rect(Rect2((p+Vector2(2,-1)).round(),Vector2(6+segment%3,1)),Color(0.58,0.91,0.84,brightness*0.48))
            if segment%4==0:draw_rect(Rect2(p+Vector2(3,6),Vector2(2,2)),Color(0.60,0.94,0.83,brightness*0.56))

func _draw_constellation_stag(t: float, alpha: float) -> void:
    var p: Vector2=Vector2(712+t*5.4,320+sin(t*0.16)*6)
    var gait: float=sin(t*1.2)*7*activity_blend
    var points: Dictionary={"rump":Vector2(-31,-17),"back":Vector2(8,-24),"chest":Vector2(27,-19),"belly":Vector2(13,0),"hip":Vector2(-23,1),"neck":Vector2(37,-46),"head":Vector2(47,-56),"nose":Vector2(65,-53),"throat":Vector2(43,-39),"front_knee":Vector2(28+gait,20),"front_hoof":Vector2(35+gait,43),"rear_knee":Vector2(-20-gait,21),"rear_hoof":Vector2(-28-gait,42),"far_front":Vector2(18-gait*0.6,40),"far_rear":Vector2(-8+gait*0.6,41),"tail":Vector2(-45,-24),"antler":Vector2(42,-77),"antler_l":Vector2(23,-94),"antler_r":Vector2(58,-96),"branch_l":Vector2(13,-90),"branch_r":Vector2(70,-90),"tip":Vector2(41,-104)}
    var links: Array=[['rump','back'],['back','chest'],['chest','belly'],['belly','hip'],['hip','rump'],['chest','neck'],['neck','head'],['head','nose'],['nose','throat'],['throat','chest'],['chest','front_knee'],['front_knee','front_hoof'],['hip','rear_knee'],['rear_knee','rear_hoof'],['belly','far_front'],['hip','far_rear'],['rump','tail'],['head','antler'],['antler','antler_l'],['antler','antler_r'],['antler_l','branch_l'],['antler_r','branch_r'],['antler','tip']]
    for link: Array in links:
        var a: Vector2=p+(points[link[0]] as Vector2)
        var b: Vector2=p+(points[link[1]] as Vector2)
        draw_line(a.round(),b.round(),Color(0.70,0.84,0.90,alpha*0.48),1.3)
    for key: String in points:
        var point: Vector2=p+(points[key] as Vector2)
        var glow: float=0.7+sin(t*0.43+float(key.length()))*0.16
        draw_rect(Rect2(point.round()-Vector2.ONE,Vector2(3,3)),Color(0.87,0.92,0.82,alpha*glow))
    draw_rect(Rect2((p+Vector2(48,-55)).round(),Vector2(2,2)),Color(1.0,0.95,0.71,alpha))

func _draw_large_bird_flight(actor: Dictionary) -> void:
    var id: String = str(actor["id"])
    var t: float = float(actor["motion_age"])
    var alpha: float = float(actor["alpha"])
    var facing: float = float(actor["facing"])
    var feather: Color = Color("786e58") if id == "owl" else (Color("d8ddc5") if id == "egret" else Color("465459"))
    var light: Color = Color("d3c298") if id == "owl" else (Color("eee9cc") if id == "egret" else Color("e2dfbf"))
    var scale_px: float = 2.7 if id == "owl" else 2.15
    draw_set_transform((actor["pos"] as Vector2).round(),float(actor.get("body_tilt",0.0))*facing,Vector2(scale_px*facing,scale_px))
    var palette: Dictionary = {"O":feather.darkened(0.25),"H":light,"E":Color("253c3b"),"B":Color("b7a06a"),"W":feather,"C":light,"T":feather,"L":Color("736d54")}
    var flap: float = sin(t * (10.0 if id == "owl" else 12.0))
    var landing: float = float(actor.get("land_blend",0.0))
    for side in [-1.0,1.0]:
        var spread: float = (13.0 if id == "egret" else 11.0) * (1.0 - landing * 0.45)
        var tip: Vector2 = Vector2(-5+side*spread,-10-flap*11.0)
        _draw_flight_wing(Vector2(-4,-8),tip-Vector2(-4,-8),3.0,_visitor_ink(feather.to_html(false),alpha*(0.8 if side<0 else 1.0)))
        for feather_index in range(3):
            var offset: Vector2 = Vector2(feather_index*2,feather_index)
            draw_line(tip+offset,tip+offset+Vector2(3,4),_visitor_ink(light.to_html(false),alpha*0.8),1.0)
    _pixel_pattern(BIRD_PATTERN,palette,Vector2(-9,-12),alpha)
    if id == "woodpecker":
        draw_rect(Rect2(2,-13,5,2),_visitor_ink("b75a4c",alpha))
        draw_rect(Rect2(8,-9,5,1),_visitor_ink("5d6861",alpha))
    elif id == "egret":
        draw_line(Vector2(-4,-2),Vector2(-16,-1+landing*3),_visitor_ink("65694e",alpha),1.0)
        draw_line(Vector2(-2,-1),Vector2(-14,2+landing*3),_visitor_ink("65694e",alpha),1.0)
        draw_rect(Rect2(8,-9,7,1),_visitor_ink("bba16b",alpha))
    else:
        draw_rect(Rect2(3,-11,4,4),_visitor_ink("b8a773",alpha))
        draw_rect(Rect2(5,-10,1,2),_visitor_ink("283c3e",alpha))
    draw_set_transform(Vector2.ZERO)

func _draw_walking_cat(pos: Vector2, t: float, alpha: float) -> void:
    var facing: float = float(_drawing_actor.get("facing",-1.0))
    draw_set_transform(pos.round(),0,Vector2(2.3*facing,2.3))
    var fur: Color = _visitor_ink("ba9970",alpha)
    var shadow: Color = _visitor_ink("9e7c57",alpha)
    var step: float = sin(t * 8.0) * 3.0
    # Rear pair is behind the torso, front pair overlaps it; the back stays level.
    for pair in [0,1]:
        for side in [-1.0,1.0]:
            var x: float = -8.0 if pair == 0 else 7.0
            var stride: float = step * side * (-1.0 if pair == 0 else 1.0)
            draw_line(Vector2(x,-7),Vector2(x+stride*0.55,-3),shadow if side<0 else fur,3.0)
            draw_line(Vector2(x+stride*0.55,-3),Vector2(x-stride,0),shadow if side<0 else fur,2.0)
            draw_rect(Rect2(x-stride-1,0,4,1),shadow if side<0 else fur)
    draw_rect(Rect2(-12,-14,23,8),fur)
    draw_rect(Rect2(-9,-7,16,2),_visitor_ink("e5d4b0",alpha))
    var head: Array[String] = ["O.....O..","FFO.OFFO.","FFFFFFFFO","FHHFFHHFO","FHHFFHEFO",".FFFCCFO.","..FFFFO.."]
    _pixel_pattern(head,{"O":Color("4b5953"),"F":Color("ba9970"),"H":Color("d5c498"),"C":Color("e5d4b0"),"E":Color("3b5352")},Vector2(6,-21),alpha)
    draw_rect(Rect2(14,-16,2,1),_visitor_ink("a97862",alpha))
    var tail_tip: Vector2 = Vector2(-23,-20+sin(t*1.6)*3)
    draw_line(Vector2(-11,-12),Vector2(-18,-13),shadow,3.0)
    draw_line(Vector2(-18,-13),tail_tip,shadow,2.0)
    draw_set_transform(Vector2.ZERO)


func _draw_flight_wing(root: Vector2, axis: Vector2, width: float, color: Color) -> void:
    # A convex wing stays valid at every beat, including when the tip passes the
    # body. A hand-warped quad could self-intersect at those exact poses.
    var normal: Vector2 = Vector2(-axis.y,axis.x).normalized() * width
    draw_colored_polygon(PackedVector2Array([root-normal*0.45,root+axis-normal*0.8,root+axis+normal*0.8,root+normal*0.45]),color)
