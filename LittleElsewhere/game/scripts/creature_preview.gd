extends "res://scripts/window_scene.gd"
## Uses the exact game drawing code, isolated from locomotion and save state.
func _ready() -> void:
    set_process(false)

func _draw() -> void:
    if actors.is_empty(): return
    var actor: Dictionary = actors[0]
    _drawing_actor = actor
    if str(actor["id"]) in TREE_VISITORS: _draw_tree_visitor(actor)
    elif str(actor["id"]) == "butterfly": _draw_butterfly(actor)
    else: _draw_bird(actor)
    _drawing_actor = {}

func show_actor(source: Dictionary, source_world: Node) -> void:
    actors.clear()
    if not source.is_empty():
        var actor: Dictionary = source.duplicate(true)
        actor["pos"] = Vector2.ZERO
        actors.append(actor)
    weather = source_world.weather
    quiet = source_world.quiet
    activity_blend = source_world.activity_blend
    weather_weights.assign(source_world.weather_weights)
    atmosphere_tint = source_world.atmosphere_tint
    atmosphere_tint_strength = source_world.atmosphere_tint_strength
    queue_redraw()
