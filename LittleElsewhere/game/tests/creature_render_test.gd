extends SceneTree
## Run with a real renderer to catch invalid geometry and visually verify every species.
const Preview = preload("res://scripts/creature_preview.gd")
const Motion = preload("res://scripts/visitor_motion.gd")
var previews: Array[Node2D] = []
var failures: int = 0

func _initialize() -> void:
    run.call_deferred()

func run() -> void:
    root.content_scale_size = Vector2i(1440,900)
    var backdrop = ColorRect.new()
    backdrop.color = Color("e8e6d7")
    backdrop.size = Vector2(1440,900)
    root.add_child(backdrop)
    for index in range(Motion.IDS.size()):
        var preview = Preview.new()
        root.add_child(preview)
        preview.position = Vector2(100+index%7*203,205+int(index/7)*270)
        preview.scale = Vector2(1.6,1.6)
        preview.actors.append(Motion.spawn(Motion.IDS[index],Vector2.ZERO,0))
        previews.append(preview)
        var label = Label.new()
        label.position = preview.position+Vector2(-70,20)
        label.text = Motion.IDS[index]
        label.add_theme_color_override("font_color",Color("344d48"))
        root.add_child(label)
    # The same renderer executes all entry, idle and departure pose families.
    # Deliberately include sin extrema and the former flat-wing crossover.
    # Image checks use irregular samples to avoid aliasing periodic wingbeats.
    for phase in ["entry","idle","exit"]:
        var signatures: Dictionary = {}
        for id in Motion.IDS: signatures[id] = []
        for frame in range(64):
            for preview in previews:
                var id: String = str(preview.actors[0]["id"])
                preview.seek_actor_phase(id,phase,frame/64.0)
                preview.actors[0]["pos"] = Vector2.ZERO
                preview.actors[0]["motion_age"] = frame * PI / 24.0
                preview.queue_redraw()
            await RenderingServer.frame_post_draw
            if frame in [0,5,13,21,32,39,49,61]:
                var frame_image: Image = root.get_texture().get_image()
                if frame_image == null or frame_image.is_empty():
                    failures += 1
                    continue
                for preview in previews:
                    var id: String = str(preview.actors[0]["id"])
                    var area: Rect2i = Rect2i(Vector2i(preview.position)-Vector2i(95,190),Vector2i(190,210))
                    var signature: int = hash(frame_image.get_region(area).get_data())
                    if not signatures[id].has(signature): signatures[id].append(signature)
                if phase == "idle" and frame == 21:
                    var output: String = "res://../artifacts/creature_animation_review/all_creatures.png"
                    for arg in OS.get_cmdline_user_args():
                        if arg.begins_with("--render-sheet="): output = arg.trim_prefix("--render-sheet=")
                    if frame_image.save_png(output) != OK: failures += 1
        for id in Motion.IDS:
            if signatures[id].size() < 2:
                failures += 1
                push_error("No rendered body-part animation for %s in %s" % [id,phase])
    print("CREATURE_RENDER_TEST species=21 phases=3 poses=64 drawings=4032 animated_checks=63 failures=",failures)
    quit(1 if failures else 0)
