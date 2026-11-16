extends Control
## Native no-save visitor animation workbench, using the live World and WeatherStage.
const Preview = preload("res://scripts/creature_preview.gd")
const NAMES: Dictionary = {"sparrow":"麻雀", "tit":"山雀", "robin":"知更鸟", "woodpecker":"啄木鸟", "owl":"林鸮", "kingfisher":"翠鸟", "swallow":"燕子", "magpie":"喜鹊", "white_eye":"绣眼鸟", "egret":"白鹭", "squirrel":"松鼠", "hedgehog":"刺猬", "cat":"猫", "bat":"蝙蝠", "butterfly":"白蝶", "luna_moth":"月蛾", "jewel_beetle":"宝石甲虫", "fireflies":"萤火虫", "dragonfly":"蜻蜓", "ladybug":"瓢虫", "stag_beetle":"锹甲"}
const WEATHER_NAMES: Array[String] = ["晴日", "听雨", "月夜", "夕照", "落雪", "晨雾", "风雨", "晨曦"]
var ids: Array[String] = []
var selected: String = "sparrow"
var playing: bool = true
var speed: float = 1.0
var loop: bool = true
var sequence: bool = false
var exporting: bool = false
var picker: OptionButton
var weather_picker: OptionButton
var play_button: Button
var phase_label: Label
var preview_label: Label
var progress_bar: ProgressBar
var preview_panel: Panel
var preview: Node2D
@onready var world = $World
@onready var stage = $WeatherStage

func _enter_tree() -> void:
    set_meta("gm_preview_only",true)

func _ready() -> void:
    get_window().title = "Little Elsewhere · 来客动作检视"
    get_window().content_scale_size = Vector2i(1440,900)
    DiaryState.set_process(false)
    world.set_process(false)
    world.set_layered_weather_enabled(true)
    world.set_painted_atmospheres(stage.get_painted_atmosphere_ids())
    stage.painted_atmospheres_changed.connect(world.set_painted_atmospheres)
    var font = SystemFont.new()
    font.font_names = PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Arial"])
    var ui_theme = Theme.new()
    ui_theme.default_font = font
    ui_theme.default_font_size = 15
    theme = ui_theme
    ids = world.get_creature_ids()
    _build_controls()
    var requested_phase: String = "entry"
    var requested_progress: float = 0.0
    var capture_dir: String = ""
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--creature="): selected = arg.trim_prefix("--creature=")
        elif arg.begins_with("--phase="): requested_phase = arg.trim_prefix("--phase=")
        elif arg.begins_with("--phase-progress="): requested_progress = float(arg.trim_prefix("--phase-progress="))
        elif arg.begins_with("--creature-frames="): capture_dir = arg.trim_prefix("--creature-frames=")
    if selected not in ids: selected = ids[0]
    _select(ids.find(selected))
    world.seek_actor_phase(selected, requested_phase, requested_progress)
    if not capture_dir.is_empty(): _export_frames.call_deferred(capture_dir)

func _box(fill: String, border: String) -> StyleBoxFlat:
    var box = StyleBoxFlat.new()
    box.bg_color = Color(fill)
    box.border_color = Color(border)
    box.set_border_width_all(1)
    box.set_corner_radius_all(7)
    box.content_margin_left = 12
    box.content_margin_right = 12
    return box

func _button(text_value: String, at: Vector2, size_value: Vector2, callback: Callable) -> Button:
    var button = Button.new()
    button.text = text_value
    button.position = at
    button.size = size_value
    button.add_theme_stylebox_override("normal",_box("e3e4d3","aeb9a9"))
    button.add_theme_stylebox_override("hover",_box("f4edda","879d8c"))
    button.add_theme_stylebox_override("pressed",_box("cbd5c3","728c7d"))
    button.add_theme_color_override("font_color",Color("344d48"))
    button.add_theme_color_override("font_hover_color",Color("344d48"))
    button.add_theme_color_override("font_pressed_color",Color("344d48"))
    button.pressed.connect(callback)
    add_child(button)
    return button

func _label(text_value: String, at: Vector2, font_size: int = 15) -> Label:
    var label = Label.new()
    label.text = text_value
    label.position = at
    label.add_theme_color_override("font_color",Color("344d48"))
    label.add_theme_font_size_override("font_size",font_size)
    add_child(label)
    return label

func _build_controls() -> void:
    var footer = Panel.new()
    footer.position = Vector2(0,810)
    footer.size = Vector2(1440,90)
    footer.add_theme_stylebox_override("panel",_box("e8e6d7","a3b4a5"))
    add_child(footer)
    _label("来客动作检视",Vector2(20,822),18)
    picker = OptionButton.new()
    picker.position = Vector2(170,820)
    picker.size = Vector2(190,34)
    for id in ids: picker.add_item(str(NAMES.get(id,id)))
    picker.item_selected.connect(_select)
    add_child(picker)
    _button("重播全程",Vector2(372,820),Vector2(94,34),func(): _restart())
    play_button = _button("暂停",Vector2(476,820),Vector2(68,34),func():
        playing = not playing
        play_button.text = "暂停" if playing else "继续")
    for index in range(3):
        var phase: String = ["entry","idle","exit"][index]
        _button(["入场","停留","离场"][index],Vector2(554+index*72,820),Vector2(64,34),func(): _seek(phase))
    var speed_picker = OptionButton.new()
    speed_picker.position = Vector2(778,820)
    speed_picker.size = Vector2(91,34)
    for value in [0.25,0.5,1.0,2.0,4.0]: speed_picker.add_item("%s×" % value)
    speed_picker.select(2)
    speed_picker.item_selected.connect(func(index: int): speed = [0.25,0.5,1.0,2.0,4.0][index])
    add_child(speed_picker)
    weather_picker = OptionButton.new()
    weather_picker.position = Vector2(879,820)
    weather_picker.size = Vector2(100,34)
    for name_value in WEATHER_NAMES: weather_picker.add_item(name_value)
    weather_picker.item_selected.connect(func(index: int):
        world.set_weather(index)
        stage.set_weather(index,false))
    add_child(weather_picker)
    _button("安静模式",Vector2(989,820),Vector2(104,34),func():
        world.set_quiet(not world.quiet)
        stage.set_quiet(world.quiet))
    _button("依次看 21 种",Vector2(1103,820),Vector2(132,34),func(): sequence = not sequence)
    _button("放大动作",Vector2(1245,820),Vector2(112,34),func(): preview_panel.visible = not preview_panel.visible)
    phase_label = _label("",Vector2(20,867),14)
    progress_bar = ProgressBar.new()
    progress_bar.position = Vector2(590,872)
    progress_bar.size = Vector2(340,9)
    progress_bar.show_percentage = false
    progress_bar.add_theme_stylebox_override("background",_box("d2d9ca","c3ccbc"))
    progress_bar.add_theme_stylebox_override("fill",_box("799d8d","799d8d"))
    add_child(progress_bar)
    _label("独立预览 · 不写入收集记录    空格：暂停   ← / →：切换",Vector2(963,866),12)
    preview_panel = Panel.new()
    preview_panel.position = Vector2(1060,52)
    preview_panel.size = Vector2(340,276)
    preview_panel.clip_contents = true
    preview_panel.add_theme_stylebox_override("panel",_box("e8e6d7","8da594"))
    preview_panel.visible = false
    add_child(preview_panel)
    preview_label = Label.new()
    preview_label.position = Vector2(16,12)
    preview_label.add_theme_color_override("font_color",Color("344d48"))
    preview_panel.add_child(preview_label)
    preview = Preview.new()
    preview.position = Vector2(170,205)
    preview.scale = Vector2(2.5,2.5)
    preview_panel.add_child(preview)

func _select(index: int) -> void:
    selected = ids[wrapi(index,0,ids.size())]
    picker.select(ids.find(selected))
    var mode: int = 2 if selected in ["owl","luna_moth","bat","fireflies","stag_beetle"] else 7
    world.set_weather(mode)
    stage.set_weather(mode,true)
    weather_picker.select(mode)
    _restart()

func _restart() -> void:
    world.actors.clear()
    world.spectacles.clear()
    world.trigger(selected,false)
    playing = true
    play_button.text = "暂停"
    _refresh()

func _seek(phase: String) -> void:
    if world.get_actor_lifecycle_snapshot(selected).is_empty(): _restart()
    world.seek_actor_phase(selected,phase,0.0)
    _refresh()

func _process(delta: float) -> void:
    if exporting: return
    if playing: world._process(delta * speed)
    if world.get_actor_lifecycle_snapshot(selected).is_empty() and playing and loop:
        if sequence: _select(ids.find(selected)+1)
        else: _restart()
    _refresh()

func _refresh() -> void:
    var state: Dictionary = world.get_actor_lifecycle_snapshot(selected)
    if state.is_empty():
        phase_label.text = "已经离场 · 随时重播"
        preview.show_actor({},world)
        return
    var phase: String = {"entry":"入场", "idle":"停留", "exit":"离场"}.get(str(state["phase"]),"")
    phase_label.text = "%s  ·  %s %d%%  ·  %.1f / %.0f 秒  ·  %s%s" % [NAMES[selected],phase,float(state["phase_progress"])*100,float(state["age"]),float(state["duration"]),"安静" if world.quiet else "自然"," · 依次观看中" if sequence else ""]
    preview_label.text = "%s · %s\n%s" % [NAMES[selected],phase,str(state["pose"])]
    progress_bar.value = float(state["age"])/float(state["duration"])*100
    for actor in world.actors:
        if str(actor["id"]) == selected:
            preview.show_actor(actor,world)
            break

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo: return
    if event.keycode == KEY_SPACE:
        playing = not playing
        play_button.text = "暂停" if playing else "继续"
    elif event.keycode == KEY_RIGHT: _select(ids.find(selected)+1)
    elif event.keycode == KEY_LEFT: _select(ids.find(selected)-1)

func _export_frames(directory: String) -> void:
    exporting = true
    playing = false
    preview_panel.show()
    DirAccess.make_dir_recursive_absolute(directory)
    # Native rendering of the real sprites: 16 poses per phase for visual review.
    for phase in ["entry","idle","exit"]:
        for frame in range(16):
            var p: float = lerpf(0.20,0.85,frame/15.0) if phase != "idle" else lerpf(0.25,0.34,frame/15.0)
            world.seek_actor_phase(selected,phase,p)
            _refresh()
            await RenderingServer.frame_post_draw
            var image: Image = get_viewport().get_texture().get_image()
            if phase == "idle" and frame == 0:
                image.save_png(directory.path_join("%s_scene.png" % selected))
            var ratio: Vector2 = Vector2(image.get_size()) / Vector2(1440,900)
            var crop: Image = image.get_region(Rect2i(Vector2i(preview_panel.position * ratio),Vector2i(preview_panel.size * ratio)))
            var error: Error = crop.save_png(directory.path_join("%s_%s_%02d.png" % [selected,phase,frame]))
            if error != OK:
                push_error("Could not export creature preview")
                get_tree().quit(1)
                return
    print("CREATURE_FRAMES exported 48 native frames for ",selected," to ",directory)
    get_tree().quit()
