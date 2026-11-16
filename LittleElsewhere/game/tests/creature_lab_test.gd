extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
    run.call_deferred()

func check(ok: bool, message: String) -> void:
    checks += 1
    if not ok:
        failures += 1
        push_error(message)

func button(root_node: Node, value: String) -> Button:
    for child in root_node.get_children():
        if child is Button and child.text == value: return child
    return null

func run() -> void:
    await _test_mode(false)
    await _test_mode(true)
    print("CREATURE_LAB_TEST checks=%d failures=%d" % [checks,failures])
    quit(1 if failures else 0)

func _test_mode(new_only: bool) -> void:
    var lab = load("res://scenes/creature_lab.tscn").instantiate()
    lab.new_birds_only = new_only
    root.add_child(lab)
    current_scene = lab
    await process_frame
    lab.set_process(false)
    check(bool(lab.get_meta("gm_preview_only",false)),"lab is explicitly a no-save preview")
    var expected_count: int = 16 if lab.new_birds_only else 37
    check(lab.picker.item_count == expected_count,"picker includes every creature for selected mode")
    if lab.new_birds_only: check(lab.selected == "pigeon","new-bird mode defaults to pigeon")
    var defs: Dictionary = root.get_node("DiaryState").get_entry_defs()
    for index in range(lab.ids.size()):
        lab.picker.item_selected.emit(index)
        var id: String = lab.ids[index]
        check(lab.selected == id,"picker selects " + id)
        check(lab.picker.get_item_text(index) == str(defs[id]["name"]),"picker uses collection name for " + id)
        for phase_index in range(3):
            button(lab,["入场","停留","离场"][phase_index]).pressed.emit()
            var state: Dictionary = lab.world.get_actor_lifecycle_snapshot(id)
            check(state.get("phase") == ["entry","idle","exit"][phase_index],id + " button reaches the right stage")
            check(state.get("position") == lab.world.get_actor_position(id),id + " preview uses actual scene position")
        button(lab,"进食").pressed.emit()
        check(lab.world.get_actor_lifecycle_snapshot(id).get("phase") == "idle",id + " feeding button stays in observation phase")
        if id in lab.Motion.EXPANSION_BIRDS:
            var feeding: bool = false
            for actor in lab.world.actors:
                if str(actor["id"]) == id: feeding = float(actor.get("feed_blend",0.0)) > 0.5
            check(feeding,id + " feeding button finds real animated food interaction")
        check(not lab.preview_label.text.contains(id),id + " preview displays Chinese names and gestures")
    button(lab,"暂停").pressed.emit()
    var before: float = float(lab.world.actors[0]["age"])
    lab._process(1.0)
    check(is_equal_approx(float(lab.world.actors[0]["age"]),before),"pause holds animation time")
    button(lab,"继续").pressed.emit()
    lab._process(0.25)
    check(float(lab.world.actors[0]["age"]) > before,"resume advances time")
    button(lab,"重播全程").pressed.emit()
    check(lab.world.get_actor_lifecycle_snapshot(lab.selected).get("phase") == "entry","replay restarts entry")
    button(lab,"安静模式").pressed.emit()
    check(lab.world.quiet,"quiet mode button controls world")
    lab.preview_panel.hide()
    button(lab,"放大动作").pressed.emit()
    check(lab.preview_panel.visible and lab.preview.actors.size() == 1,"magnifier displays live creature")
    lab.speed = 4.0
    before = float(lab.world.actors[0]["age"])
    lab._process(0.25)
    check(absf(float(lab.world.actors[0]["age"])-before-1.0) < 0.001,"speed scales playback")
    lab._select(0)
    button(lab,"依次看 %d 种" % lab.ids.size()).pressed.emit()
    lab._seek("exit")
    lab._process(2.0)
    check(lab.selected == lab.ids[1],"sequence advances to next species after departure")
    lab.queue_free()
    await process_frame
