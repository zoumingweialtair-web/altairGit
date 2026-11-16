extends RefCounted
## Deterministic visitor locomotion. Life uses real elapsed time; quiet only slows gestures.
const IDS: Array[String] = ["sparrow", "tit", "robin", "woodpecker", "owl", "kingfisher", "swallow", "magpie", "white_eye", "egret", "squirrel", "hedgehog", "cat", "bat", "butterfly", "luna_moth", "jewel_beetle", "fireflies", "dragonfly", "ladybug", "stag_beetle"]
const BIRDS: Array[String] = ["sparrow", "tit", "robin", "woodpecker", "owl", "kingfisher", "swallow", "magpie", "white_eye", "egret"]
const AIRBORNE: Array[String] = ["swallow", "bat", "butterfly", "luna_moth", "fireflies", "dragonfly"]
const CRAWLERS: Array[String] = ["squirrel", "jewel_beetle", "ladybug", "stag_beetle"]
const SHELTER_WEATHER: Array[int] = [1, 2, 4, 5, 6]

static func duration(id: String, weather: int) -> float:
    if id in ["sparrow", "tit", "robin", "butterfly"]:
        return 40.0 if weather in SHELTER_WEATHER else (34.0 if weather == 3 else 26.0)
    return 36.0

static func entry_duration(id: String) -> float:
    if id in CRAWLERS: return 5.5
    if id == "hedgehog": return 5.2
    if id == "cat": return 4.0
    if id in ["egret", "owl"]: return 4.4
    if id in ["butterfly", "luna_moth", "fireflies"]: return 4.6
    return 3.5

static func exit_duration(id: String) -> float:
    return 5.0 if id in CRAWLERS or id == "hedgehog" else 4.0

static func spawn(id: String, anchor: Vector2, weather: int) -> Dictionary:
    var actor: Dictionary = {"id":id, "age":0.0, "pos":anchor, "start":anchor, "anchor":anchor,
        "fly":false, "alpha":1.0, "facing":1.0, "motion_age":0.0, "phase":"entry",
        "phase_progress":0.0, "duration":duration(id,weather), "entry_duration":entry_duration(id),
        "exit_duration":exit_duration(id), "pose":"arrive", "weather":weather, "travel":1.0,
        "land_blend":0.0, "body_tilt":0.0, "idle_age":0.0}
    sample(actor, weather, 1.0)
    return actor

static func request_departure(actor: Dictionary) -> void:
    if str(actor.get("phase", "")) == "exit": return
    actor["forced_exit_age"] = float(actor["age"])
    actor["exit_from"] = actor["pos"]
    actor["duration"] = float(actor["age"]) + float(actor["exit_duration"])
    actor["phase"] = "exit"
    actor["phase_progress"] = 0.0

static func advance(actor: Dictionary, delta: float, weather: int, activity: float) -> bool:
    if str(actor["id"]) == "butterfly" and weather in SHELTER_WEATHER:
        request_departure(actor)
    var previous: Vector2 = actor["pos"]
    actor["age"] = float(actor["age"]) + maxf(0.0, delta)
    actor["motion_age"] = float(actor["motion_age"]) + maxf(0.0, delta) * (0.35 + 0.65 * activity)
    sample(actor, weather, activity)
    var movement: Vector2 = (actor["pos"] as Vector2) - previous
    if absf(movement.x) > 0.03:
        actor["facing"] = 1.0 if movement.x > 0 else -1.0
    actor["body_tilt"] = clampf(movement.y / maxf(1.0, absf(movement.x)) * 0.12, -0.24, 0.24) if bool(actor["fly"]) else 0.0
    return float(actor["age"]) > float(actor["duration"])

static func sample(actor: Dictionary, weather: int, activity: float) -> void:
    var id: String = str(actor["id"])
    var age: float = float(actor["age"])
    var enter: float = float(actor["entry_duration"])
    var leave: float = float(actor["exit_duration"])
    var end: float = float(actor["duration"])
    var exit_at: float = float(actor.get("forced_exit_age", end - leave))
    var anchor: Vector2 = actor["anchor"]
    actor["alpha"] = 1.0
    actor["travel"] = 0.0
    actor["land_blend"] = 1.0
    actor["fly"] = id in AIRBORNE
    actor["idle_age"] = maxf(0.0, age - enter)
    if age >= exit_at:
        var p: float = clampf((age - exit_at) / leave, 0.0, 1.0)
        actor["phase"] = "exit"
        actor["phase_progress"] = p
        if not actor.has("exit_from"):
            actor["exit_from"] = idle_position(actor, exit_at, weather, activity)
        var exit_target: Vector2 = exit_endpoint(id, anchor)
        actor["pos"] = route(id, actor["exit_from"], exit_target, p, false)
        actor["facing"] = 1.0 if exit_target.x >= (actor["exit_from"] as Vector2).x else -1.0
        actor["travel"] = smoothstep(0.0, 0.17, p)
        actor["land_blend"] = 1.0 - smoothstep(0.0, 0.18, p)
        actor["fly"] = id in BIRDS or id in AIRBORNE
        actor["pose"] = "takeoff" if p < 0.18 and bool(actor["fly"]) else ("depart" if bool(actor["fly"]) else "walk")
        if id in CRAWLERS: actor["pose"] = "climb"
    elif age < enter:
        var p: float = clampf(age / enter, 0.0, 1.0)
        actor["phase"] = "entry"
        actor["phase_progress"] = p
        var entry_start: Vector2 = entry_endpoint(id, anchor)
        actor["pos"] = route(id, entry_start, anchor, p, true)
        actor["facing"] = 1.0 if anchor.x >= entry_start.x else -1.0
        actor["travel"] = 1.0 - smoothstep(0.72, 1.0, p)
        actor["land_blend"] = smoothstep(0.77, 1.0, p)
        actor["fly"] = id in BIRDS or id in AIRBORNE
        actor["pose"] = "land" if p > 0.77 and bool(actor["fly"]) else ("arrive" if bool(actor["fly"]) else "walk")
        if id in CRAWLERS: actor["pose"] = "climb"
    else:
        actor["phase"] = "idle"
        actor["phase_progress"] = clampf((age - enter) / maxf(0.1, exit_at - enter), 0.0, 1.0)
        actor["pos"] = idle_position(actor, age, weather, activity)
        actor["pose"] = idle_pose(id, float(actor["motion_age"]), bool(actor["fly"]))
        if bool(actor["fly"]): actor["travel"] = 1.0
    # Weather relocation eases from the actual current location, including midflight.
    if actor.has("relocate_from") and str(actor["phase"]) == "idle":
        var relocation: float = clampf((age - float(actor["relocate_at"])) / 1.8, 0.0, 1.0)
        actor["pos"] = (actor["relocate_from"] as Vector2).lerp(actor["pos"], smoothstep(0.0, 1.0, relocation))
        actor["fly"] = relocation < 0.98 or bool(actor["fly"])
        if relocation >= 1.0: actor.erase("relocate_from")

static func entry_endpoint(id: String, anchor: Vector2) -> Vector2:
    if id in CRAWLERS: return Vector2(anchor.x - 22.0, 890.0)
    if id == "hedgehog": return Vector2(-100, anchor.y)
    if id == "cat": return Vector2(1550, anchor.y)
    if id == "egret": return Vector2(1540, 370)
    if id in ["owl", "magpie", "tit"]: return Vector2(-110, 40)
    if id in ["butterfly", "luna_moth", "fireflies"]: return Vector2(-120, anchor.y + 65)
    if id in ["swallow", "bat", "dragonfly"]: return Vector2(1550, anchor.y - 65)
    return Vector2(-110, anchor.y - 115)

static func exit_endpoint(id: String, anchor: Vector2) -> Vector2:
    if id in CRAWLERS: return Vector2(anchor.x + 12, 900)
    if id == "hedgehog": return Vector2(-100, anchor.y)
    if id == "cat": return Vector2(1550, anchor.y)
    if id in ["owl", "tit", "magpie", "woodpecker"]: return Vector2(-130, -100)
    if id in ["butterfly", "luna_moth", "fireflies"]: return Vector2(-140, anchor.y - 90)
    return Vector2(1560, maxf(-90, anchor.y - 210))

static func route(id: String, from: Vector2, to: Vector2, p: float, incoming: bool) -> Vector2:
    var eased: float = smoothstep(0.0, 1.0, p)
    var pos: Vector2 = from.lerp(to, eased)
    var envelope: float = sin(p * PI)
    if id in CRAWLERS:
        pos.x += sin(p * TAU * 4) * 2.5 * envelope
    elif id in ["cat", "hedgehog"]:
        pos.y -= absf(sin(p * PI * 9)) * 1.5 * envelope
    elif id == "egret":
        pos.y -= envelope * (42 if incoming else 100)
    elif id in ["butterfly", "luna_moth", "fireflies"]:
        pos.y += sin(p * TAU * 1.7) * 24 * envelope
        pos.x += sin(p * TAU * 2) * 13 * envelope
    else:
        pos.y -= envelope * (68 if incoming else 100)
    return pos

static func idle_position(actor: Dictionary, age: float, weather: int, activity: float) -> Vector2:
    var id: String = str(actor["id"])
    var anchor: Vector2 = actor["anchor"]
    var t: float = maxf(0.0, age - float(actor["entry_duration"]))
    actor["fly"] = id in AIRBORNE
    if id in ["sparrow", "tit", "robin"] and weather not in SHELTER_WEATHER:
        var feeder: Vector2 = Vector2(1147, 590)
        if id == "tit": feeder += Vector2(-49, -2)
        if id == "robin": feeder += Vector2(39, -4)
        if age >= 7.0 and age < 11.0:
            actor["fly"] = true
            return route(id, anchor, feeder, (age - 7.0) / 4.0, true)
        if age >= 11.0: return feeder
    match id:
        "kingfisher":
            var cycle: float = fmod(t, 16.0)
            if cycle > 7.0 and cycle < 12.0:
                actor["fly"] = true
                var dive: float = sin((cycle - 7.0) / 5.0 * PI)
                return anchor.lerp(Vector2(696,500), dive)
        "swallow": return anchor + Vector2(sin(t * 0.30) * 190, sin(t * 0.60) * 32) * activity
        "bat": return anchor + Vector2(sin(t * 0.35) * 122, sin(t * 0.70) * 42) * activity
        "butterfly": return anchor + Vector2(sin(t * 0.40) * 58, sin(t * 0.83) * 21) * activity
        "luna_moth": return anchor + Vector2(sin(t * 0.28) * 46, sin(t * 0.37) * 20) * activity
        "dragonfly": return anchor + Vector2(sin(t * 0.34) * 58, sin(t * 0.58) * 17) * activity
        "fireflies": return anchor + Vector2(sin(t * 0.18) * 11, sin(t * 0.14) * 7) * activity
        "white_eye":
            var hop: float = smoothstep(0.0, 1.0, fmod(t, 8.0) / 0.65)
            var direction: float = 1 if int(t / 8.0) % 2 == 0 else -1
            return anchor + Vector2((hop if direction > 0 else 1.0 - hop) * 17.0, -sin(hop * PI) * 8) * activity
        "jewel_beetle", "ladybug", "stag_beetle": return anchor + Vector2(sin(t * 0.19) * 3, -sin(t * 0.10) * 15)
        "hedgehog": return anchor + Vector2(sin(t * 0.15) * 12, 0)
        "egret": return anchor + Vector2(sin(t * 0.13) * 8, 0)
    return anchor

static func idle_pose(id: String, t: float, flying: bool) -> String:
    if flying: return "hover" if id in ["dragonfly", "luna_moth", "fireflies"] else "glide"
    match id:
        "squirrel": return "nibble"
        "woodpecker": return "peck" if fmod(t, 4.4) < 1.1 else "listen"
        "owl": return "watch"
        "cat": return "groom" if fmod(t, 12.0) > 9.0 else "sit"
        "hedgehog": return "sniff"
        "egret": return "wade"
        "jewel_beetle", "ladybug", "stag_beetle": return "crawl"
        "tit": return "preen" if fmod(t, 8.0) > 5.5 else "perch"
        "robin": return "sing" if fmod(t, 8.0) > 5.0 else "perch"
        "sparrow": return "peck" if fmod(t, 4.0) > 2.6 else "perch"
    return "perch"
