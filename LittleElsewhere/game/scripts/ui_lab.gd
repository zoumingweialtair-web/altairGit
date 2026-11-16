extends Control
## A separate, non-persistent design showroom for ten native Godot interfaces.
const Styles = preload("res://scripts/ui_lab_styles.gd")
const Hud = preload("res://scripts/ui_lab_hud.gd")
const Guide = preload("res://scripts/ui_lab_guide.gd")
const WEATHER_NAMES = ["晴日", "听雨", "月夜", "夕照", "落雪", "晨雾", "风雨", "晨曦"]
const EVENTS = ["aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const EVENT_WEATHERS = [2, 3, 2, 5, 5, 2, 2, 0, 2, 2]
var styles: Array[Dictionary] = []
var style_index: int = 0
var weather_index: int = 7
var quiet: bool = false
var sound_on: bool = false
var guide: Control
var _guide_state: Dictionary = {}
var hud: Control
var footer: Control
var scheme_picker: OptionButton
var weather_picker: OptionButton
var guide_button: Button
var focus_button: Button
var caption: Label
var message: Label
var music: AudioStreamPlayer
var event_index: int = 0
var visitor_clock: float = 0.0
var focus_seconds: float = 0.0
var _exporting: bool = false
var _font: SystemFont
@onready var stage = $WeatherStage
@onready var world = $World

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    styles = Styles.all_styles()
    _font = SystemFont.new()
    _font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Arial"])
    var ui_theme = Theme.new()
    ui_theme.default_font = _font
    ui_theme.default_font_size = 16
    theme = ui_theme
    DiaryState.set_process(false)
    world.set_layered_weather_enabled(true)
    world.set_painted_atmospheres(stage.get_painted_atmosphere_ids())
    stage.painted_atmospheres_changed.connect(world.set_painted_atmospheres)
    world.bird_selected.connect(_open_bird)
    hud = Hud.new()
    hud.name = "StyleHUD"
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.action.connect(_on_action)
    add_child(hud)
    _build_footer()
    music = AudioStreamPlayer.new()
    music.stream = load("res://assets/audio/lofi_loop.wav")
    music.volume_db = -19.0
    add_child(music)
    music.finished.connect(func():
        if sound_on: music.play())
    _set_weather(7, true)
    _change_style(0)
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--style="):
            _change_style(clampi(int(arg.trim_prefix("--style=")) - 1, 0, 9))
    if OS.get_cmdline_user_args().has("--ui-lab-test"):
        _run_checks.call_deferred()
    else:
        for arg in OS.get_cmdline_user_args():
            if arg.begins_with("--ui-lab-export="):
                _export_samples.call_deferred(arg.trim_prefix("--ui-lab-export="))

func _panel_style(fill: Color, border: Color, radius: int = 7) -> StyleBoxFlat:
    var box = StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(1)
    box.set_corner_radius_all(radius)
    box.content_margin_left = 10
    box.content_margin_right = 10
    return box

func _footer_button(text_value: String, x: float, width: float, callback: Callable) -> Button:
    var button = Button.new()
    button.text = text_value
    button.position = Vector2(x, 838)
    button.size = Vector2(width, 44)
    button.add_theme_color_override("font_color", Color("eff2ed"))
    button.add_theme_color_override("font_hover_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _panel_style(Color("263a3d"), Color("576b6c")))
    button.add_theme_stylebox_override("hover", _panel_style(Color("3d5557"), Color("afc9c1")))
    button.add_theme_stylebox_override("pressed", _panel_style(Color("49665e"), Color("afc9c1")))
    button.pressed.connect(callback)
    footer.add_child(button)
    return button

func _build_footer() -> void:
    footer = Control.new()
    footer.name = "ShowroomControls"
    footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(footer)
    var base = ColorRect.new()
    base.color = Color("142629")
    base.position = Vector2(0, 810)
    base.size = Vector2(1440, 90)
    footer.add_child(base)
    caption = Label.new()
    caption.position = Vector2(24, 817)
    caption.size = Vector2(950, 22)
    caption.add_theme_font_size_override("font_size", 14)
    caption.add_theme_color_override("font_color", Color("c0d2cb"))
    footer.add_child(caption)
    _footer_button("‹", 24, 44, func(): _change_style(posmod(style_index - 1, styles.size())))
    scheme_picker = OptionButton.new()
    scheme_picker.name = "SchemePicker"
    scheme_picker.position = Vector2(76, 838)
    scheme_picker.size = Vector2(350, 44)
    for index in range(styles.size()):
        scheme_picker.add_item("%02d   %s  /  %s" % [index + 1, styles[index].name, styles[index].english])
    scheme_picker.add_theme_font_size_override("font_size", 16)
    scheme_picker.item_selected.connect(_change_style)
    footer.add_child(scheme_picker)
    _footer_button("›", 434, 44, func(): _change_style((style_index + 1) % styles.size()))
    weather_picker = OptionButton.new()
    weather_picker.name = "WeatherPicker"
    weather_picker.position = Vector2(496, 838)
    weather_picker.size = Vector2(128, 44)
    for weather_name in WEATHER_NAMES: weather_picker.add_item(weather_name)
    weather_picker.item_selected.connect(func(index): _set_weather(index))
    footer.add_child(weather_picker)
    guide_button = _footer_button("图鉴样册", 638, 126, _toggle_guide)
    _footer_button("奇遇回放", 778, 126, func(): _on_action("event"))
    focus_button = _footer_button("体验陪伴", 918, 126, func(): _on_action("focus"))
    _footer_button("音乐开关", 1058, 126, func(): _on_action("sound"))
    _footer_button("随机来客", 1198, 216, func():
        world.trigger(["sparrow", "robin", "squirrel", "woodpecker", "owl", "kingfisher"].pick_random(), false)
        message.text = "新来客正在树上停留")
    message = Label.new()
    message.position = Vector2(974, 817)
    message.size = Vector2(440, 21)
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    message.add_theme_font_size_override("font_size", 13)
    message.add_theme_color_override("font_color", Color("a8beb6"))
    message.text = "← → 切换方案 · G 图鉴 · 空格陪伴 · 示例数据"
    footer.add_child(message)

func _change_style(index: int) -> void:
    style_index = clampi(index, 0, styles.size() - 1)
    scheme_picker.select(style_index)
    hud.build(styles[style_index], WEATHER_NAMES[weather_index], quiet)
    if is_instance_valid(guide): guide.build(styles[style_index])
    caption.text = "%02d / 10   %s  ·  %s" % [style_index + 1, styles[style_index].name, styles[style_index].tagline]
    if not _exporting:
        hud.modulate.a = 0.0
        create_tween().tween_property(hud, "modulate:a", 1.0, 0.18)

func _set_weather(index: int, immediate: bool = false) -> void:
    weather_index = clampi(index, 0, 7)
    world.clear_atmosphere_events()
    world.set_weather(weather_index)
    stage.set_weather(weather_index, immediate)
    if is_instance_valid(weather_picker): weather_picker.select(weather_index)
    if is_instance_valid(hud) and not styles.is_empty():
        hud.build(styles[style_index], WEATHER_NAMES[weather_index], quiet)

func _set_quiet(value: bool) -> void:
    quiet = value
    _close_guide()
    world.set_quiet(quiet)
    stage.set_quiet(quiet)
    focus_button.text = "结束陪伴" if quiet else "体验陪伴"
    hud.build(styles[style_index], WEATHER_NAMES[weather_index], quiet)
    message.text = "陪伴中 · 界面收起，来客与风景继续变化" if quiet else "← → 切换方案 · G 图鉴 · 空格陪伴 · 示例数据"

func _on_action(action_id: String) -> void:
    match action_id:
        "guide": _toggle_guide()
        "focus": _set_quiet(not quiet)
        "weather": _set_weather((weather_index + 1) % 8)
        "event":
            _replay(EVENTS[event_index % EVENTS.size()])
            event_index += 1
        "sound":
            sound_on = not sound_on
            if sound_on: music.play()
            else: music.stop()
            message.text = "轻音乐已开启" if sound_on else "轻音乐已关闭"

func _open_bird(id: String) -> void:
    if id not in Guide.IDS:
        message.text = "%s来访 · 图鉴样册展示六种示例" % DiaryState.get_entry_defs().get(id, {}).get("name", id)
        return
    _open_guide()
    guide.select_entry(id)

func _toggle_guide() -> void:
    if is_instance_valid(guide): _close_guide()
    else: _open_guide()

func _open_guide() -> void:
    if quiet: _set_quiet(false)
    if is_instance_valid(guide): return
    guide = Guide.new()
    guide.name = "GuidePreview"
    add_child(guide)
    guide.closed.connect(_close_guide)
    guide.replay_requested.connect(_replay)
    guide.restore_preview_state(_guide_state)
    guide.build(styles[style_index])
    guide_button.text = "返回窗边"

func _close_guide() -> void:
    if is_instance_valid(guide):
        _guide_state = guide.get_preview_state()
        remove_child(guide)
        guide.queue_free()
        guide = null
    if is_instance_valid(guide_button): guide_button.text = "图鉴样册"

func _replay(id: String) -> void:
    _close_guide()
    var at = EVENTS.find(id)
    if at >= 0: _set_weather(EVENT_WEATHERS[at])
    elif id in ["owl", "luna_moth"]: _set_weather(2)
    else: _set_weather(7)
    world.trigger(id, false)
    message.text = "正在回放 · %s" % DiaryState.get_entry_defs().get(id, {}).get("name", id)

func _process(delta: float) -> void:
    var atmosphere: Dictionary = world.get_atmosphere_state()
    atmosphere["quiet"] = quiet
    stage.set_atmosphere_state(atmosphere)
    visitor_clock += delta
    if quiet: focus_seconds += delta
    if visitor_clock > 22.0 and not _exporting:
        visitor_clock = 0.0
        world.trigger("sparrow", false)
        world.trigger("squirrel", false)

func _shortcut_input(event: InputEvent) -> void:
    if scheme_picker.get_popup().visible or weather_picker.get_popup().visible: return
    if not event is InputEventKey or not event.pressed or event.echo: return
    match event.keycode:
        KEY_LEFT: _change_style(posmod(style_index - 1, styles.size()))
        KEY_RIGHT: _change_style((style_index + 1) % styles.size())
        KEY_G: _toggle_guide()
        KEY_W: _on_action("weather")
        KEY_E: _on_action("event")
        KEY_SPACE: _on_action("focus")
        KEY_ESCAPE:
            if is_instance_valid(guide): _close_guide()
            elif quiet: _set_quiet(false)
    get_viewport().set_input_as_handled()

func _export_samples(directory: String) -> void:
    _exporting = true
    DirAccess.make_dir_recursive_absolute(directory)
    hud.modulate.a = 1.0
    _set_weather(7, true)
    await get_tree().create_timer(1.2).timeout
    var manifest: Array[Dictionary] = []
    for index in range(styles.size()):
        _close_guide()
        _change_style(index)
        await get_tree().create_timer(0.20).timeout
        await RenderingServer.frame_post_draw
        var stem: String = "%02d-%s" % [index + 1, styles[index].id]
        var main_path = directory.path_join(stem + "-hud.png")
        var result = get_viewport().get_texture().get_image().save_png(main_path)
        if result != OK:
            push_error("Unable to export " + main_path)
            get_tree().quit(1)
            return
        _open_guide()
        await get_tree().create_timer(0.20).timeout
        await RenderingServer.frame_post_draw
        var guide_path = directory.path_join(stem + "-guide.png")
        result = get_viewport().get_texture().get_image().save_png(guide_path)
        if result != OK:
            push_error("Unable to export " + guide_path)
            get_tree().quit(1)
            return
        manifest.append({"index":index + 1,"id":styles[index].id,"name":styles[index].name,"english":styles[index].english,"tagline":styles[index].tagline,"hud":stem + "-hud.png","guide":stem + "-guide.png"})
        print("UI_EXPORT_OK ", stem)
    _close_guide()
    _change_style(4)
    _set_weather(2, true)
    _set_quiet(true)
    await get_tree().create_timer(0.25).timeout
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(directory.path_join("quiet-night.png"))
    var file = FileAccess.open(directory.path_join("manifest.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest, "  "))
    file.close()
    print("UI_EXPORT_COMPLETE 10 HUD + 10 guides + quiet mode")
    get_tree().quit()

func _run_checks() -> void:
    _exporting = true
    var failures: Array[String] = []
    var normal_path = "user://window_diary_demo_save.json"
    var normal_before = FileAccess.get_sha256(normal_path) if FileAccess.file_exists(normal_path) else "MISSING"
    if styles.size() != 10: failures.append("style count")
    var ids: Dictionary = {}
    for index in range(styles.size()):
        _change_style(index)
        ids[styles[index].id] = true
        _open_guide()
        guide.select_entry("sparrow")
        var known: Dictionary = guide.get_snapshot()
        if not known.get("known", false): failures.append("known entry in style " + str(index))
        if int(known.get("visible_count", 0)) != 6: failures.append("six example entries")
        guide.select_entry("twin_moons")
        var unknown: Dictionary = guide.get_snapshot()
        if unknown.get("known", true): failures.append("unknown entry stays hidden")
        var replay = guide.find_child("ReplayButton", true, false) as Button
        if replay == null or not replay.disabled: failures.append("unknown replay is disabled")
        guide.select_entry("sparrow")
        var favorite = guide.find_child("FavoriteButton", true, false) as Button
        if favorite == null:
            failures.append("favorite action missing")
        else:
            var prior: bool = guide.get_snapshot().get("favorited", false)
            favorite.pressed.emit()
            if bool(guide.get_snapshot().get("favorited", false)) == prior: failures.append("favorite action")
        var expected_favorite: bool = guide.get_snapshot().get("favorited", false)
        _close_guide()
        _open_guide()
        if bool(guide.get_snapshot().get("favorited", false)) != expected_favorite: failures.append("favorite retained after closing")
        _close_guide()
        _set_quiet(true)
        if not world.quiet: failures.append("quiet world")
        _set_quiet(false)
        print("UI_LAB_CHECK style ", index + 1, " ", styles[index].id)
    if ids.size() != 10: failures.append("unique styles")
    _set_weather(1, true)
    if stage.weather != 1 or world.weather != 1: failures.append("weather synchronization")
    _replay("aurora_crown")
    if world.get_atmosphere_state().get("id", "") != "aurora_crown": failures.append("event replay")
    if weather_index != 2: failures.append("replay compatible weather")
    _on_action("sound")
    if not music.playing: failures.append("music playback")
    _on_action("sound")
    var normal_after = FileAccess.get_sha256(normal_path) if FileAccess.file_exists(normal_path) else "MISSING"
    if normal_before != normal_after: failures.append("normal save modified")
    if DiaryState._save_path() != "": failures.append("preview persistence is not disabled")
    for failure in failures: push_error("UI_LAB_CHECK " + failure)
    print("UI_LAB_TEST styles=", styles.size(), " failures=", failures.size(), " save_unchanged=", normal_before == normal_after)
    get_tree().quit(0 if failures.is_empty() else 1)
