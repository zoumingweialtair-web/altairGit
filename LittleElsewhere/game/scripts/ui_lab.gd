extends Control
## Non-persistent UI showroom sharing the original animated scenery.
const Styles = preload("res://scripts/ui_lab_styles.gd")
const Hud = preload("res://scripts/ui_lab_hud.gd")
const Guide = preload("res://scripts/ui_lab_guide.gd")
const ArtGallery = preload("res://scripts/ui_art_gallery.gd")
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
var art_view: Control
var event_button: Button
var sound_button: Button
var visitor_button: Button
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
var _light_preview: bool = false
var _font: SystemFont
@onready var stage = $WeatherStage
@onready var world = $World

func _ready() -> void:
    get_window().content_scale_size = Vector2i(1440,900)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    styles = Styles.all_styles()
    _light_preview = OS.get_cmdline_user_args().has("--ui-light")
    if _light_preview:
        get_window().content_scale_size = Vector2i(1440,852)
        get_window().size = Vector2i(1280,757)
        get_window().title = "Little Elsewhere · 轻量界面 21–30"
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
    art_view = ArtGallery.new()
    art_view.name = "ArtGallery"
    add_child(art_view)
    art_view.hide()
    _build_footer()
    if _light_preview: _compact_footer()
    music = AudioStreamPlayer.new()
    music.stream = load("res://assets/audio/lofi_loop.wav")
    music.volume_db = -19.0
    add_child(music)
    music.finished.connect(func():
        if sound_on: music.play())
    _set_weather(7, true)
    _change_style(20 if _light_preview else 0)
    for arg in OS.get_cmdline_user_args():
        if arg.begins_with("--style="):
            _change_style(clampi(int(arg.trim_prefix("--style=")) - 1, 0, styles.size() - 1))
    if OS.get_cmdline_user_args().has("--ui-lab-test"):
        _run_checks.call_deferred()
    else:
        for arg in OS.get_cmdline_user_args():
            if arg.begins_with("--ui-light-export="):
                _export_light_samples.call_deferred(arg.trim_prefix("--ui-light-export="))
            elif arg.begins_with("--ui-lab-export="):
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
    _footer_button("‹", 24, 44, func(): _step_style(-1))
    scheme_picker = OptionButton.new()
    scheme_picker.name = "SchemePicker"
    scheme_picker.position = Vector2(76, 838)
    scheme_picker.size = Vector2(350, 44)
    for index in range(styles.size()):
        if _light_preview and not bool(styles[index].get("lightweight",false)): continue
        scheme_picker.add_item("%02d   %s  /  %s" % [index + 1, styles[index].name, styles[index].english],index)
    scheme_picker.add_theme_font_size_override("font_size", 16)
    scheme_picker.item_selected.connect(func(item: int): _change_style(scheme_picker.get_item_id(item)))
    footer.add_child(scheme_picker)
    _footer_button("›", 434, 44, func(): _step_style(1))
    weather_picker = OptionButton.new()
    weather_picker.name = "WeatherPicker"
    weather_picker.position = Vector2(496, 838)
    weather_picker.size = Vector2(128, 44)
    for weather_name in WEATHER_NAMES: weather_picker.add_item(weather_name)
    weather_picker.item_selected.connect(func(index): _set_weather(index))
    footer.add_child(weather_picker)
    guide_button = _footer_button("图鉴样册", 638, 126, _toggle_guide)
    event_button = _footer_button("奇遇回放", 778, 126, func(): _on_action("event"))
    focus_button = _footer_button("体验陪伴", 918, 126, func(): _on_action("focus"))
    sound_button = _footer_button("音乐开关", 1058, 126, func(): _on_action("sound"))
    visitor_button = _footer_button("随机来客", 1198, 216, _visitor_action)
    message = Label.new()
    message.position = Vector2(974, 817)
    message.size = Vector2(440, 21)
    message.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    message.add_theme_font_size_override("font_size", 13)
    message.add_theme_color_override("font_color", Color("a8beb6"))
    message.text = "← → 方案 · G 图鉴 · F1 调试 · 示例数据"
    footer.add_child(message)

func get_active_style_kind() -> String:
    if styles.is_empty(): return "interactive"
    return str(styles[style_index].get("kind", "interactive"))

func _is_concept() -> bool:
    return get_active_style_kind() == "concept"

func _visitor_action() -> void:
    if _is_concept():
        art_view.open_original()
        return
    world.trigger(["sparrow", "robin", "squirrel", "woodpecker", "owl", "kingfisher"].pick_random(), false)
    message.text = "新来客正在树上停留"

func _configure_proposal_controls() -> void:
    var concept: bool = _is_concept()
    weather_picker.disabled = concept
    guide_button.text = "适应窗口" if concept else ("返回窗边" if is_instance_valid(guide) else "图鉴样册")
    event_button.text = "放大原画" if concept else "奇遇回放"
    focus_button.text = "缩小原画" if concept else ("结束陪伴" if quiet else "体验陪伴")
    visitor_button.text = "打开原图" if concept else "随机来客"
    message.text = "原画提案 · 滚轮缩放 / 拖动查看 · 双击复位" if concept else "← → 方案 · G 图鉴 · F1 调试 · 示例数据"

func _change_style(index: int) -> void:
    style_index = clampi(index, 0, styles.size() - 1)
    scheme_picker.select(scheme_picker.get_item_index(style_index))
    var concept: bool = _is_concept()
    if concept:
        _close_guide()
        quiet = false
        world.set_quiet(false)
        stage.set_quiet(false)
        hud.hide()
        world.hide()
        stage.hide()
        art_view.show()
        art_view.build(styles[style_index])
    else:
        art_view.hide()
        world.show()
        stage.show()
        hud.show()
        hud.build(styles[style_index], WEATHER_NAMES[weather_index], quiet)
        if is_instance_valid(guide): guide.build(styles[style_index])
    _configure_proposal_controls()
    caption.text = "%02d / %02d   %s  ·  %s%s" % [style_index + 1, styles.size(), styles[style_index].name, "原画提案 / " if concept else "", styles[style_index].tagline]
    if not _exporting and not concept:
        hud.modulate.a = 0.0
        create_tween().tween_property(hud, "modulate:a", 1.0, 0.18)

func _set_weather(index: int, immediate: bool = false) -> void:
    if _is_concept(): return
    weather_index = clampi(index, 0, 7)
    world.clear_atmosphere_events()
    world.set_weather(weather_index)
    stage.set_weather(weather_index, immediate)
    if is_instance_valid(weather_picker): weather_picker.select(weather_index)
    if is_instance_valid(hud) and not styles.is_empty():
        hud.build(styles[style_index], WEATHER_NAMES[weather_index], quiet)

func _set_quiet(value: bool) -> void:
    if _is_concept(): return
    quiet = value
    _close_guide()
    if not _is_light_style():
        world.set_quiet(quiet)
        stage.set_quiet(quiet)
    focus_button.text = "结束陪伴" if quiet else "体验陪伴"
    hud.build(styles[style_index], WEATHER_NAMES[weather_index], quiet)
    message.text = "陪伴中 · 界面收起，来客与风景继续变化" if quiet else "← → 方案 · G 图鉴 · F1 调试 · 示例数据"

func _on_action(action_id: String) -> void:
    if _is_concept() and action_id in ["guide","focus","event","weather"]:
        match action_id:
            "guide": art_view.reset_view()
            "event": art_view.zoom_by(1.25)
            "focus": art_view.zoom_by(0.8)
        return
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
    if _is_concept():
        art_view.reset_view()
        return
    if is_instance_valid(guide): _close_guide()
    else: _open_guide()

func _open_guide() -> void:
    if _is_concept(): return
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
    atmosphere["quiet"] = quiet and not _is_light_style()
    stage.set_atmosphere_state(atmosphere)
    visitor_clock += delta
    if quiet: focus_seconds += delta
    if visitor_clock > 22.0 and not _exporting:
        visitor_clock = 0.0
        world.trigger("sparrow", false)
        world.trigger("squirrel", false)

func _input(event: InputEvent) -> void:
    var gm = get_node_or_null("/root/GMConsole")
    if gm != null and gm.is_open(): return
    if scheme_picker.get_popup().visible or weather_picker.get_popup().visible: return
    if not event is InputEventKey or not event.pressed or event.echo: return
    match event.keycode:
        KEY_LEFT: _step_style(-1)
        KEY_RIGHT: _step_style(1)
        KEY_G: _toggle_guide()
        KEY_W: _on_action("weather")
        KEY_E: _on_action("event")
        KEY_SPACE: _on_action("focus")
        KEY_ESCAPE:
            if is_instance_valid(guide): _close_guide()
            elif quiet: _set_quiet(false)
            elif _is_concept(): art_view.reset_view()
        _: return
    get_viewport().set_input_as_handled()

func _export_samples(directory: String) -> void:
    _exporting = true
    var new_only: bool = OS.get_cmdline_user_args().has("--ui-lab-export-new-only")
    DirAccess.make_dir_recursive_absolute(directory)
    hud.modulate.a = 1.0
    _change_style(0)
    _set_weather(7, true)
    await get_tree().create_timer(1.2).timeout
    var manifest: Array[Dictionary] = []
    for index in range(styles.size()):
        var concept: bool = str(styles[index].get("kind", "interactive")) == "concept"
        if new_only and not concept: continue
        _close_guide()
        _change_style(index)
        await get_tree().create_timer(0.15).timeout
        await RenderingServer.frame_post_draw
        var stem: String = "%02d-%s" % [index + 1, styles[index].id]
        var main_file: String = stem + ("-concept.png" if concept else "-hud.png")
        var main_path: String = directory.path_join(main_file)
        var result: Error = get_viewport().get_texture().get_image().save_png(main_path)
        if result != OK:
            push_error("Unable to export " + main_path)
            get_tree().quit(1)
            return
        var guide_file: String = ""
        if not concept:
            _open_guide()
            await get_tree().create_timer(0.15).timeout
            await RenderingServer.frame_post_draw
            guide_file = stem + "-guide.png"
            result = get_viewport().get_texture().get_image().save_png(directory.path_join(guide_file))
            if result != OK:
                get_tree().quit(1)
                return
        manifest.append({"index":index + 1,"id":styles[index].id,"name":styles[index].name,"english":styles[index].english,"tagline":styles[index].tagline,"kind":"concept" if concept else "interactive","hud":main_file,"guide":guide_file,"art_path":str(styles[index].get("art_path",""))})
        print("UI_EXPORT_OK ", stem)
    _close_guide()
    if not new_only:
        _change_style(4)
        _set_weather(2, true)
        _set_quiet(true)
        await get_tree().create_timer(0.25).timeout
        await RenderingServer.frame_post_draw
        get_viewport().get_texture().get_image().save_png(directory.path_join("quiet-night.png"))
    var file: FileAccess = FileAccess.open(directory.path_join("manifest.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest, "  "))
    file.close()
    print("UI_EXPORT_COMPLETE ",manifest.size()," schemes")
    get_tree().quit()

func _run_checks() -> void:
    _exporting = true
    var failures: Array[String] = []
    var normal_path = "user://window_diary_demo_save.json"
    var normal_before = FileAccess.get_sha256(normal_path) if FileAccess.file_exists(normal_path) else "MISSING"
    if styles.size() != 30: failures.append("style count")
    var ids: Dictionary = {}
    for index in range(styles.size()):
        _change_style(index)
        ids[styles[index].id] = true
        if _is_concept():
            if not bool(art_view.get_snapshot().get("loaded",false)): failures.append("missing proposal " + str(index))
            if hud.visible or world.visible or stage.visible: failures.append("concept must own its presentation")
            art_view.zoom_by(1.5)
            if float(art_view.get_snapshot().get("zoom",1.0)) <= 1.0: failures.append("concept zoom")
            _toggle_guide()
            if float(art_view.get_snapshot().get("zoom",0.0)) != 1.0: failures.append("concept fit-to-window")
            var before_weather: int = weather_index
            _on_action("weather")
            if weather_index != before_weather: failures.append("concept picture cannot simulate weather controls")
            print("UI_LAB_CHECK art ", index + 1, " ", styles[index].id)
            continue
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
        if not _is_light_style() and not world.quiet: failures.append("quiet world")
        _set_quiet(false)
        print("UI_LAB_CHECK style ", index + 1, " ", styles[index].id)
    if ids.size() != styles.size(): failures.append("unique styles")
    _change_style(0)
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

func _is_light_style() -> bool:
    return not styles.is_empty() and bool(styles[style_index].get("lightweight",false))

func _step_style(direction: int) -> void:
    if _light_preview:
        var candidates: Array[int] = []
        for index in range(styles.size()):
            if bool(styles[index].get("lightweight",false)): candidates.append(index)
        _change_style(candidates[posmod(candidates.find(style_index) + direction,candidates.size())])
    else:
        _change_style(posmod(style_index + direction,styles.size()))

func _compact_footer() -> void:
    # Preview controls live below the untouched 1440 x 810 game canvas.
    caption.hide()
    message.hide()
    for child in footer.get_children():
        if child is ColorRect:
            child.size.y = 42
            child.color = Color("e9ede7")
        elif child is Button:
            child.position.y = 816
            child.add_theme_font_size_override("font_size",14)
            child.add_theme_stylebox_override("normal",_panel_style(Color("f7f8f2"),Color("c6cec2"),4))
            child.add_theme_stylebox_override("hover",_panel_style(Color("ffffff"),Color("879d8c"),4))
            child.add_theme_stylebox_override("pressed",_panel_style(Color("dce6dc"),Color("879d8c"),4))
            for key: String in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]:
                child.add_theme_color_override(key,Color("354a41"))
            child.size.y = 30
            child.tooltip_text = "方案预览工具 · 左右切换 / G 图鉴 / W 天气 / E 奇遇 / F1 调试"

func _export_light_samples(directory: String) -> void:
    _exporting = true
    get_window().size = Vector2i(1440,852)
    get_window().content_scale_size = Vector2i(1440,852)
    DirAccess.make_dir_recursive_absolute(directory)
    _change_style(20)
    _set_weather(7,true)
    hud.modulate.a = 1.0
    await get_tree().create_timer(1.2).timeout
    set_process(false)
    world.process_mode = Node.PROCESS_MODE_DISABLED
    stage.process_mode = Node.PROCESS_MODE_DISABLED
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().save_png(directory.path_join("preview-toolbar.png"))
    footer.hide()
    hud.hide()
    await RenderingServer.frame_post_draw
    var baseline: Image = get_viewport().get_texture().get_image().get_region(Rect2i(0,0,1440,810))
    baseline.save_png(directory.path_join("background-reference.png"))
    var manifest: Array[Dictionary] = []
    var failures: Array[String] = []
    for index in range(styles.size()):
        if not bool(styles[index].get("lightweight",false)): continue
        _close_guide()
        _change_style(index)
        hud.hide()
        await RenderingServer.frame_post_draw
        var backdrop: Image = get_viewport().get_texture().get_image().get_region(Rect2i(0,0,1440,810))
        var unchanged: bool = baseline.get_data() == backdrop.get_data()
        if not unchanged: failures.append("Background changed: " + str(styles[index].id))
        hud.show()
        await RenderingServer.frame_post_draw
        var stem: String = "%02d-%s" % [index+1,styles[index].id]
        var main_file: String = stem + "-hud.png"
        var guide_file: String = stem + "-guide.png"
        var main_image: Image = get_viewport().get_texture().get_image().get_region(Rect2i(0,0,1440,810))
        var occupied: float = 0.0
        for rect: Rect2 in hud.get_meta("ui_bounds",[]): occupied += rect.get_area()
        var coverage: float = occupied / (1440.0 * 810.0) * 100.0
        if coverage >= 2.0: failures.append("HUD exceeds 2%: " + stem)
        if main_image.save_png(directory.path_join(main_file)) != OK:
            failures.append("Cannot write " + main_file)
        _open_guide()
        await RenderingServer.frame_post_draw
        var guide_image: Image = get_viewport().get_texture().get_image().get_region(Rect2i(0,0,1440,810))
        var exterior_unchanged: bool = main_image.get_region(Rect2i(0,0,1040,810)).get_data() == guide_image.get_region(Rect2i(0,0,1040,810)).get_data()
        if not exterior_unchanged: failures.append("Guide changes scenery outside drawer: " + stem)
        if guide_image.save_png(directory.path_join(guide_file)) != OK:
            failures.append("Cannot write " + guide_file)
        manifest.append({"index":index+1,"id":styles[index].id,"name":styles[index].name,"english":styles[index].english,"tagline":styles[index].tagline,"hud":main_file,"guide":guide_file,"background_unchanged":unchanged,"hud_area_percent":snappedf(coverage,0.01),"guide_exterior_unchanged":exterior_unchanged})
        print("LIGHT_EXPORT ",stem," background_unchanged=",unchanged)
    _close_guide()
    _change_style(20)
    _set_quiet(true)
    await RenderingServer.frame_post_draw
    get_viewport().get_texture().get_image().get_region(Rect2i(0,0,1440,810)).save_png(directory.path_join("quiet-view.png"))
    var file: FileAccess = FileAccess.open(directory.path_join("manifest.json"),FileAccess.WRITE)
    file.store_string(JSON.stringify(manifest,"  "))
    file.close()
    for failure in failures: push_error(failure)
    print("LIGHT_EXPORT_COMPLETE styles=",manifest.size()," failures=",failures.size())
    get_tree().quit(0 if failures.is_empty() else 1)
