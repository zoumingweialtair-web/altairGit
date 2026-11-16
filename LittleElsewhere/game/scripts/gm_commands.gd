extends RefCounted
## Explicit GM command whitelist. No expression evaluation, shell or arbitrary paths.
const StateData = preload("res://scripts/diary_state.gd")
const Styles = preload("res://scripts/ui_lab_styles.gd")
const WEATHER_IDS: Array[String] = ["sun", "rain", "night", "dusk", "snow", "fog", "storm", "dawn"]
const WEATHER_NAMES: Array[String] = ["晴日", "听雨", "月夜", "夕照", "落雪", "晨雾", "风雨", "晨曦"]
const CATEGORIES: Array[String] = ["birds", "animals", "insects", "scenery", "wonders"]
const LAYER_NAMES: Array[String] = ["Sky", "Stars", "FarClouds", "EventSky", "Mountains", "FarMist", "Water", "EventWater", "TownShore", "Tree", "NearRainSnow", "Foreground"]
const SAMPLE_IDS: Array[String] = ["sparrow", "kingfisher", "owl", "luna_moth", "aurora_crown", "twin_moons"]

func catalog() -> Array[Dictionary]:
    return [
        _entry("help", "help [command]", "查看命令与参数说明。", "信息", "help event"),
        _entry("ids", "ids [all|birds|animals|insects|scenery|wonders]", "列出全部 50 项或指定分类的 ID。", "信息", "ids wonders"),
        _entry("status", "status", "查看场景、存档模式、天气、收藏与倍速。", "信息", "status"),
        _entry("weather", "weather <sun|rain|night|dusk|snow|fog|storm|dawn|0..7>", "切换八种天气，调试切换不奖励风景收录。", "世界", "weather snow"),
        _entry("time", "time <dawn|day|dusk|night>", "切换游戏晨曦、晴日、夕照或月夜；不修改电脑时钟。", "世界", "time night"),
        _entry("speed", "speed <0.1..8>", "设置动画与游戏运行倍速，1 为正常速度。", "世界", "speed 2"),
        _entry("pause", "pause <on|off|toggle>", "暂停或恢复世界；GM 控制台继续工作。", "世界", "pause toggle"),
        _entry("spawn", "spawn <creature_id>", "回放鸟类、动物或虫类，自动匹配天气；不增加收录。", "来客与奇遇", "spawn kingfisher"),
        _entry("motion", "motion <creature_id> <entry|idle|exit> [0..1]", "预览任意生物的进入、停留或离开动画阶段，自动匹配天气；不增加收录。", "来客与奇遇", "motion squirrel idle 0.5"),
        _entry("depart", "depart <creature_id>", "让现场来客从当前位置自然离开；不增加收录。", "来客与奇遇", "depart sparrow"),
        _entry("event", "event <wonder_id>", "回放任意奇遇并匹配天气；不增加收录。", "来客与奇遇", "event aurora_crown"),
        _entry("clear", "clear <actors|events|all>", "移除现有来客、奇遇或全部；后续自然来访仍继续。", "来客与奇遇", "clear events"),
        _entry("collect", "collect <id|all|birds|animals|insects|scenery|wonders>", "为指定条目或分类各增加一次观察并保存。", "收集", "collect all"),
        _entry("visits", "visits <creature_id> <1..1000>", "设置生物累计来访次数，可验证熟悉度与五次纪念物。", "收集", "visits sparrow 5"),
        _entry("favorite", "favorite <id> <on|off>", "设置已收录条目的珍藏状态。", "收集", "favorite sparrow on"),
        _entry("offline", "offline <1..168>", "模拟离开指定小时并生成记录，不修改真实离线游标或电脑时钟。", "收集", "offline 24"),
        _entry("decor", "decor <seeds|fruit|flowers|lantern>", "切换吸引来客的窗边布置并保存。", "陪伴", "decor fruit"),
        _entry("food", "food <status|stock <sunflower|millet|berries> <0..999>|level <0..100>>", "查看食物状态，或调整种子库存、食盘余量；按当前存档模式保存。", "陪伴", "food stock millet 36"),
        _entry("focus", "focus <on|off>", "进入或结束安静陪伴模式。", "陪伴", "focus on"),
        _entry("audio", "audio <music|ambience> <on|off>", "开关轻音乐或自然声。", "声音", "audio ambience on"),
        _entry("volume", "volume <master|music|rain|forest|river> <-60..0>", "设置当前音量 dB；天气切换会重新混音。", "声音", "volume music -22"),
        _entry("layers", "layers", "列出十二个独立场景图层及显示状态。", "美术", "layers"),
        _entry("layer", "layer <layer_name> <on|off>", "独立显示或隐藏一个图层；名称不区分大小写。", "美术", "layer NearRainSnow off"),
        _entry("guide", "guide [id]", "打开图鉴；UI 方案中只提供六项独立样册。", "界面", "guide sparrow"),
        _entry("ui", "ui <game|lab>", "切换主游戏或 UI 方案预览；包含可交互方案与静态原画提案。", "界面", "ui lab"),
        _entry("style", "style <1..%d|style_id>" % Styles.all_styles().size(), "在 UI 演示中切换方案。", "界面", "style quiet_glass"),
        _entry("screenshot", "screenshot", "由控制台保存当前画面截图。", "美术", "screenshot"),
        _entry("save", "save <status|now|backup|reload|reset CONFIRM>", "查看、保存、备份、重读或重置当前存档；重置必须确认且先备份。", "存档", "save backup")
    ]

func _entry(name_value: String, usage: String, description: String, category: String, example: String) -> Dictionary:
    return {"name":name_value,"usage":usage,"description":description,"category":category,"example":example}

func _ok(message: String, extra: Dictionary = {}) -> Dictionary:
    var result: Dictionary = {"ok":true,"message":message}
    result.merge(extra, true)
    return result

func _error(message: String) -> Dictionary:
    return {"ok":false,"message":message}

func _usage(command: String) -> Dictionary:
    for item in catalog():
        if item.name == command: return _error("用法：" + str(item.usage))
    return _error("未知命令。输入 help 查看命令。")

func _defs() -> Dictionary:
    return StateData.ENTRY_DEFS

func _is_lab(scene: Node) -> bool:
    return is_instance_valid(scene) and scene.has_method("_change_style") and scene.has_method("_set_weather")

func _is_concept(scene: Node) -> bool:
    return _is_lab(scene) and scene.has_method("get_active_style_kind") and str(scene.call("get_active_style_kind")) == "concept"

func _state(scene: Node) -> Node:
    return scene.get_node_or_null("/root/DiaryState") if is_instance_valid(scene) and scene.is_inside_tree() else null

func _world(scene: Node) -> Node:
    return scene.get_node_or_null("World") if is_instance_valid(scene) else null

func _stage(scene: Node) -> Node:
    return scene.get_node_or_null("WeatherStage") if is_instance_valid(scene) else null

func _mode(state: Node) -> String:
    var path: String = str(state.call("_save_path"))
    if path.is_empty(): return "预览模式：仅当前进程内数据，不读写存档；UI 图鉴样册另行独立"
    if path.ends_with("window_diary_fieldkit_demo.json"): return "独立口袋观察站演示存档"
    if path.ends_with("window_diary_gm_save.json"): return "独立 GM 调试存档"
    if path.ends_with("window_diary_demo_save.json"): return "正式游戏存档：数据命令会保存"
    return "独立/测试存档"

func _persisted_message(state: Node, message: String) -> Dictionary:
    if str(state.call("_save_path")).is_empty():
        message += "\n仅修改本次预览状态，不写存档；六项图鉴样册不随此变化。"
    return _ok(message)

func _switch_weather(scene: Node, index: int) -> bool:
    if _is_lab(scene):
        scene.call("_set_weather", index)
        _sync_lab_ambience(scene)
        return true
    if scene.has_method("_change_weather"):
        scene.call("_change_weather", index, false)
        return true
    return false

func _weather_index(value: String) -> int:
    if value.is_valid_int():
        var index: int = int(value)
        return index if index >= 0 and index < 8 else -1
    var index: int = WEATHER_IDS.find(value.to_lower())
    if index >= 0: return index
    if value.to_lower() == "sunny": return 0
    return WEATHER_NAMES.find(value)

func _weather_of(scene: Node) -> int:
    if _is_lab(scene): return int(scene.get("weather_index"))
    return int(scene.get("weather_mode")) if scene.has_method("_change_weather") else 0

func execute(line: String, scene: Node) -> Dictionary:
    var clean: String = line.strip_edges()
    if clean.begins_with("/"): clean = clean.substr(1).strip_edges()
    if clean.is_empty(): return _ok("输入 help 查看命令；Tab 补全命令与 ID。")
    if clean.length() > 256 or clean.contains("\n") or clean.contains("\r"):
        return _error("一次只允许一条不超过 256 字符的命令。")
    var args: PackedStringArray = clean.replace("\t", " ").split(" ", false)
    var command: String = args[0].to_lower()
    if command == "help":
        if args.size() > 2: return _usage(command)
        var entries: Array[String] = []
        for item in catalog():
            if args.size() == 1 or str(item.name) == args[1].to_lower():
                entries.append(str(item.usage) + "\n  " + str(item.description))
        return _ok("\n".join(entries)) if not entries.is_empty() else _error("没有这个命令。输入 help 查看命令。")
    if command == "ids":
        if args.size() > 2: return _usage(command)
        var category: String = args[1].to_lower() if args.size() == 2 else "all"
        if category != "all" and category not in CATEGORIES: return _usage(command)
        var names: Array[String] = []
        for id in _defs():
            if category == "all" or str(_defs()[id].get("category", "")) == category:
                names.append(str(id) + "  " + str(_defs()[id].get("name", "")))
        return _ok("%s · %d 项\n%s" % [category, names.size(), "\n".join(names)])
    if not is_instance_valid(scene) or not scene.is_inside_tree(): return _error("当前游戏场景尚未准备好。")
    var state: Node = _state(scene)
    if state == null: return _error("当前场景没有 DiaryState。")
    if _is_concept(scene) and command in ["weather","time","spawn","motion","depart","event","focus","guide","layer","layers","clear"]:
        return _error("当前是静态 UI 原画提案，画中控件不执行动态操作。请用 style 21 到 style 30 切到轻量交互方案，体验天气、来客和图鉴。")
    match command:
        "status":
            if args.size() != 1: return _usage(command)
            var stage: Node = _stage(scene)
            var world: Node = _world(scene)
            var actor_count: int = world.get("actors").size() if world != null else 0
            var event_count: int = world.get("spectacles").size() if world != null else 0
            var visual_note: String = "当前展示：静态原画提案；以下天气与来客为后台状态，不会改变原画。\n" if _is_concept(scene) else ""
            return _ok(visual_note + "%s\n场景：%s · 天气：%s · 倍速：%.2f · 暂停：%s\n收录：%d / %d · 来客：%d · 奇遇：%d\n独立图层：%s" % [_mode(state), "UI Lab" if _is_lab(scene) else "Game", WEATHER_NAMES[clampi(_weather_of(scene),0,7)], Engine.time_scale, "是" if scene.get_tree().paused else "否", state.call("get_count"), _defs().size(), actor_count, event_count, "可用" if stage != null else "不可用"])
        "weather":
            if args.size() != 2: return _usage(command)
            var index: int = _weather_index(args[1])
            if index < 0: return _usage(command)
            return _ok("天气已切为" + WEATHER_NAMES[index] + "；本次切换不收录风景。") if _switch_weather(scene,index) else _error("当前场景不支持天气。")
        "time":
            if args.size() != 2: return _usage(command)
            var values: Dictionary = {"dawn":7,"day":0,"dusk":3,"night":2}
            if not values.has(args[1].to_lower()): return _usage(command)
            var index: int = values[args[1].to_lower()]
            return _ok("游戏氛围已切为" + WEATHER_NAMES[index] + "；电脑时间未改变。") if _switch_weather(scene,index) else _error("当前场景不支持天气。")
        "speed":
            if args.size() != 2 or not args[1].is_valid_float(): return _usage(command)
            var speed: float = float(args[1])
            if not is_finite(speed) or speed < 0.1 or speed > 8.0: return _usage(command)
            Engine.time_scale = speed
            return _ok("游戏倍速 %.2f×" % speed)
        "pause":
            if args.size() != 2 or args[1].to_lower() not in ["on","off","toggle"]: return _usage(command)
            scene.get_tree().paused = not scene.get_tree().paused if args[1].to_lower() == "toggle" else args[1].to_lower() == "on"
            return _ok("世界已暂停；GM 仍可操作。" if scene.get_tree().paused else "世界已继续运行。")
        "spawn", "event":
            if args.size() != 2: return _usage(command)
            return _play_entry(scene, args[1].to_lower(), command == "event")
        "motion":
            if args.size() < 3 or args.size() > 4 or args[2].to_lower() not in ["entry","idle","exit"]: return _usage(command)
            var progress: float = 0.0
            if args.size() == 4:
                if not args[3].is_valid_float(): return _usage(command)
                progress = float(args[3])
                if not is_finite(progress) or progress < 0.0 or progress > 1.0: return _usage(command)
            return _motion(scene,args[1].to_lower(),args[2].to_lower(),progress)
        "depart":
            if args.size() != 2: return _usage(command)
            var id: String = args[1].to_lower()
            if not _defs().has(id) or _defs()[id].get("category","") not in ["birds","animals","insects"]: return _error("depart 仅接受鸟类、动物或虫类 ID。")
            var world: Node = _world(scene)
            if world == null or not world.has_method("request_actor_departure"): return _error("当前场景没有来客动画系统。")
            if not bool(world.call("request_actor_departure",id)): return _error("这位来客当前不在窗边，可先使用 spawn " + id + "。")
            return _ok("%s 正从当前位置离开；没有增加收录或来访次数。" % _defs()[id].name)
        "clear":
            if args.size() != 2 or args[1].to_lower() not in ["actors","events","all"]: return _usage(command)
            var world: Node = _world(scene)
            if world == null: return _error("当前场景没有可清理的世界。")
            if args[1].to_lower() in ["actors","all"]: world.get("actors").clear()
            if args[1].to_lower() in ["events","all"]:
                world.get("spectacles").clear()
                if _stage(scene) != null: _stage(scene).call("set_atmosphere_state",{})
            world.call("queue_redraw")
            return _ok("已清理 " + args[1] + "；自然随机来访仍会继续。")
        "collect":
            if args.size() != 2: return _usage(command)
            return _collect(state, args[1].to_lower())
        "visits":
            if args.size() != 3 or not args[2].is_valid_int(): return _usage(command)
            var id: String = args[1].to_lower()
            var count: int = int(args[2])
            if not _defs().has(id) or _defs()[id].get("category", "") not in ["birds","animals","insects"]: return _error("visits 仅接受 birds / animals / insects 的合法 ID。")
            if count < 1 or count > 1000: return _usage(command)
            state.set("_batch_mutation", true)
            if not state.get("collection").has(id): state.call("discover",id,"GM 设置来访次数")
            state.get("collection")[id]["count"] = count
            state.set("_batch_mutation", false)
            _save_and_notify(state)
            return _persisted_message(state,"%s 累计来访已设为 %d 次。" % [_defs()[id].name,count])
        "favorite":
            if args.size() != 3 or args[2].to_lower() not in ["on","off"]: return _usage(command)
            var id: String = args[1].to_lower()
            if not _defs().has(id): return _error("未知条目 ID。")
            if not state.get("collection").has(id): return _error("请先用 collect " + id + " 收录该条目，再设置珍藏。")
            var target: bool = args[2].to_lower() == "on"
            if bool(state.call("is_favorite",id)) != target: state.call("toggle_favorite",id)
            return _persisted_message(state,"%s：%s" % [_defs()[id].name,"已珍藏" if target else "已取消珍藏"])
        "offline":
            if args.size() != 2 or not args[1].is_valid_int(): return _usage(command)
            var hours: int = int(args[1])
            if hours < 1 or hours > 168: return _usage(command)
            var generated: Array = state.call("simulate_offline",hours)
            return _persisted_message(state,"模拟离开 %d 小时，生成 %d 条记录；没有改变电脑时间或真实离线游标。" % [hours,generated.size()])
        "decor":
            if args.size() != 2 or args[1].to_lower() not in ["seeds","fruit","flowers","lantern"]: return _usage(command)
            var id: String = args[1].to_lower()
            state.call("set_attraction",id)
            if _world(scene) != null: _world(scene).call("set_attraction",id)
            return _persisted_message(state,"窗边布置已切为 " + str(state.call("get_attraction_defs")[id].name) + "。")
        "food":
            return _food(state,args)
        "focus":
            if args.size() != 2 or args[1].to_lower() not in ["on","off"]: return _usage(command)
            var enabled: bool = args[1].to_lower() == "on"
            if _is_lab(scene): scene.call("_set_quiet",enabled)
            elif scene.has_method("_start_focus"):
                if enabled and not bool(scene.get("focusing")): scene.call("_start_focus")
                elif not enabled and bool(scene.get("focusing")): scene.call("_end_focus")
            else: return _error("当前场景没有陪伴模式。")
            return _ok("已进入安静陪伴。" if enabled else "已结束陪伴。",{"close":true})
        "audio":
            if args.size() != 3 or args[1].to_lower() not in ["music","ambience"] or args[2].to_lower() not in ["on","off"]: return _usage(command)
            return _audio(scene,state,args[1].to_lower(),args[2].to_lower() == "on")
        "volume":
            if args.size() != 3 or args[1].to_lower() not in ["master","music","rain","forest","river"] or not args[2].is_valid_float(): return _usage(command)
            var db: float = float(args[2])
            if not is_finite(db) or db < -60.0 or db > 0.0: return _usage(command)
            return _volume(scene,args[1].to_lower(),db)
        "layers":
            if args.size() != 1: return _usage(command)
            var stage: Node = _stage(scene)
            if stage == null: return _error("独立场景图层不可用。")
            var lines: Array[String] = []
            for layer_name in LAYER_NAMES:
                var item: CanvasItem = stage.get_node_or_null(NodePath(layer_name)) as CanvasItem
                if item != null: lines.append(layer_name + "  " + ("on" if item.visible else "off"))
            return _ok("独立图层：\n" + "\n".join(lines))
        "layer":
            if args.size() != 3 or args[2].to_lower() not in ["on","off"]: return _usage(command)
            var selected: String = ""
            for layer_name in LAYER_NAMES:
                if layer_name.to_lower() == args[1].to_lower(): selected = layer_name
            if selected.is_empty(): return _error("未知图层。输入 layers 查看十二个合法图层名。")
            var stage: Node = _stage(scene)
            var layer: CanvasItem = stage.get_node_or_null(NodePath(selected)) as CanvasItem if stage != null else null
            if layer == null: return _error("当前场景缺少该图层。")
            layer.visible = args[2].to_lower() == "on"
            return _ok(selected + " 已" + ("显示。" if layer.visible else "隐藏。"))
        "guide":
            if args.size() > 2: return _usage(command)
            var id: String = args[1].to_lower() if args.size() == 2 else ""
            if not id.is_empty() and not _defs().has(id): return _error("未知图鉴 ID。")
            if _is_lab(scene):
                if not id.is_empty() and id not in SAMPLE_IDS: return _error("UI Lab 样册只含六种示例；请用 ui game 查看全部图鉴。")
                scene.call("_open_guide")
                if not id.is_empty(): scene.get("guide").call("select_entry",id)
            elif scene.has_method("_show_collection"): scene.call("_show_collection",id)
            else: return _error("当前场景没有图鉴入口。")
            return _ok("图鉴已打开。",{"close":true})
        "ui":
            if args.size() != 2 or args[1].to_lower() not in ["game","lab"]: return _usage(command)
            return _change_ui(scene,state,args[1].to_lower())
        "style":
            if args.size() != 2: return _usage(command)
            if not _is_lab(scene): return _error("style 仅在 UI Lab 有效；先执行 ui lab。")
            var index: int = -1
            if args[1].is_valid_int(): index = int(args[1]) - 1
            else:
                var styles: Array[Dictionary] = Styles.all_styles()
                for i in range(styles.size()):
                    if str(styles[i].id) == args[1].to_lower(): index = i
            if index < 0 or index >= Styles.all_styles().size(): return _usage(command)
            scene.call("_change_style",index)
            return _ok("已切到方案 %02d · %s%s。" % [index + 1, Styles.all_styles()[index].name, " · 静态原画提案" if _is_concept(scene) else ""])
        "screenshot":
            if args.size() != 1: return _usage(command)
            return _ok("正在准备当前画面截图。",{"screenshot":true})
        "save":
            return _save_command(args,scene,state)
        _:
            return _error("未知命令“" + command + "”。输入 help 查看白名单命令。")

func _play_entry(scene: Node, id: String, wonder: bool) -> Dictionary:
    if not _defs().has(id): return _error("未知 ID。使用 ids wonders 或 ids birds 查看。")
    var data: Dictionary = _defs()[id]
    var category: String = str(data.get("category",""))
    if wonder and category != "wonders": return _error("event 仅接受奇遇 ID。")
    if not wonder and category not in ["birds","animals","insects"]: return _error("spawn 仅接受鸟类、动物或虫类 ID。")
    var world: Node = _world(scene)
    if world == null: return _error("当前场景没有来客与奇遇系统。")
    var allowed: Array = data.get("weather_ids",[0])
    var target: int = _weather_of(scene)
    if not allowed.has(target): target = int(allowed[0]) if not allowed.is_empty() else 0
    if _is_lab(scene):
        scene.call("_set_quiet",false)
        _switch_weather(scene,target)
        world.call("trigger",id,false)
    elif scene.has_method("_replay"):
        if bool(scene.get("focusing")): scene.call("_end_focus")
        scene.call("_replay",id)
    else:
        _switch_weather(scene,target)
        world.call("trigger",id,false)
    return _ok("正在回放 %s；天气已匹配，不增加收藏或观察次数。" % data.name)

func _motion(scene: Node, id: String, phase: String, progress: float) -> Dictionary:
    if not _defs().has(id) or _defs()[id].get("category","") not in ["birds","animals","insects"]:
        return _error("motion 仅接受鸟类、动物或虫类 ID。")
    var world: Node = _world(scene)
    if world == null or not world.has_method("seek_actor_phase"): return _error("当前场景没有来客动画系统。")
    var played: Dictionary = _play_entry(scene,id,false)
    if not bool(played.get("ok",false)): return played
    if not bool(world.call("seek_actor_phase",id,phase,progress)): return _error("来客尚未进入场景，请先匹配天气后重试。")
    return _ok("%s · %s 阶段 %.0f%%；不增加收录或来访次数。" % [_defs()[id].name,{"entry":"进入","idle":"停留","exit":"离开"}[phase],progress*100.0],{"lifecycle":world.call("get_actor_lifecycle_snapshot",id)})

func _food(state: Node, args: PackedStringArray) -> Dictionary:
    if args.size() == 2 and args[1].to_lower() == "status":
        var stocks: Dictionary = state.get("seed_stocks")
        return _ok("食盘余量 %.0f%% · 当前食物 %s\n葵花籽 sunflower：%d · 小米 millet：%d · 浆果 berries：%d\n%s" % [float(state.get("food_percent")),str(state.get("active_seed")),int(stocks.get("sunflower",0)),int(stocks.get("millet",0)),int(stocks.get("berries",0)),_mode(state)])
    if args.size() == 4 and args[1].to_lower() == "stock":
        var id: String = args[2].to_lower()
        if not StateData.SEED_DEFAULTS.has(id) or not args[3].is_valid_int(): return _usage("food")
        var amount: int = int(args[3])
        if amount < 0 or amount > 999: return _usage("food")
        state.get("seed_stocks")[id] = amount
        _save_and_notify(state)
        return _persisted_message(state,"%s 库存已设为 %d。" % [id,amount])
    if args.size() == 3 and args[1].to_lower() == "level":
        if not args[2].is_valid_float(): return _usage("food")
        var level: float = float(args[2])
        if not is_finite(level) or level < 0.0 or level > 100.0: return _usage("food")
        state.set("food_percent",level)
        _save_and_notify(state)
        return _persisted_message(state,"食盘余量已设为 %.0f%%。" % level)
    return _usage("food")

func _collect(state: Node, selector: String) -> Dictionary:
    var selected: Array[String] = []
    if _defs().has(selector): selected.append(selector)
    elif selector == "all" or selector in CATEGORIES:
        for id in _defs():
            if selector == "all" or _defs()[id].get("category","") == selector: selected.append(str(id))
    else: return _error("未知条目或分类。使用 ids 查看；支持 all、birds、animals、insects、scenery、wonders。")
    state.set("_batch_mutation",true)
    for id in selected: state.call("discover",id,"GM 调试收录")
    state.set("_batch_mutation",false)
    _save_and_notify(state)
    return _persisted_message(state,"已为 %d 项各增加一次观察；目前收录 %d / %d。" % [selected.size(),state.call("get_count"),_defs().size()])

func _save_and_notify(state: Node) -> void:
    state.call("save_state")
    state.emit_signal("changed")

func _player(scene: Node, channel: String, create: bool = false) -> AudioStreamPlayer:
    if not _is_lab(scene):
        if scene.has_method("_update_audio"): return scene.get(channel + "_player") as AudioStreamPlayer
        return null
    if channel == "music": return scene.get("music") as AudioStreamPlayer
    var node_name: String = "GMAudio" + channel.capitalize()
    var player: AudioStreamPlayer = scene.get_node_or_null(NodePath(node_name)) as AudioStreamPlayer
    if player == null and create:
        player = AudioStreamPlayer.new()
        player.name = node_name
        player.stream = load("res://assets/audio/" + channel + "_loop.wav")
        player.volume_db = -25.0
        scene.add_child(player)
        player.finished.connect(func():
            if is_instance_valid(scene) and bool(scene.get_meta("gm_ambience",false)): player.play())
    return player

func _sync_lab_ambience(scene: Node) -> void:
    if not _is_lab(scene): return
    var enabled: bool = bool(scene.get_meta("gm_ambience",false))
    for channel in ["rain","forest","river"]:
        var player: AudioStreamPlayer = _player(scene,channel,enabled)
        if player == null: continue
        var audible: bool = enabled and (channel != "rain" or _weather_of(scene) in [1,6])
        if audible:
            player.volume_db = -18.0 if channel == "rain" else -25.0
            if not player.playing: player.play()
        else: player.stop()

func _audio(scene: Node, state: Node, channel: String, enabled: bool) -> Dictionary:
    state.set("music_on" if channel == "music" else "ambience_on",enabled)
    if _is_lab(scene):
        if channel == "music":
            scene.set("sound_on",enabled)
            var player: AudioStreamPlayer = _player(scene,"music")
            if player != null:
                if enabled: player.play()
                else: player.stop()
        else:
            scene.set_meta("gm_ambience",enabled)
            _sync_lab_ambience(scene)
    elif scene.has_method("_update_audio"):
        scene.call("_update_audio",false)
        for player_channel in (["music"] if channel == "music" else ["rain","forest","river"]):
            var player: AudioStreamPlayer = _player(scene,player_channel)
            if enabled and player != null and not player.playing: player.play()
    else: return _error("当前场景没有声音控制。")
    state.call("save_state")
    return _persisted_message(state,("轻音乐" if channel == "music" else "自然声") + ("已开启。" if enabled else "已关闭。"))

func _volume(scene: Node, channel: String, db: float) -> Dictionary:
    if channel == "master":
        var bus: int = AudioServer.get_bus_index("Master")
        if bus < 0: return _error("Master 音频总线不存在。")
        AudioServer.set_bus_volume_db(bus,db)
    else:
        var player: AudioStreamPlayer = _player(scene,channel,true)
        if player == null: return _error("当前场景缺少该音轨。")
        if not _is_lab(scene) and scene.has_method("_update_audio"):
            var tween: Tween = scene.get("audio_tween") as Tween
            if tween != null and tween.is_running(): tween.kill()
        player.volume_db = db
    return _ok("%s 音量为 %.1f dB。天气切换会重新应用天气混音。" % [channel,db])

func _saved_state_matches(state: Node, payload: Dictionary) -> bool:
    if payload.is_empty(): return false
    # Match the exact persisted schema. JSON round-tripping normalizes integer
    # representations and the serializer's floating-point timestamp precision.
    var expected: Dictionary = {"version":StateData.SAVE_VERSION}
    for field in ["collection","records","favorites","attraction","seed_stocks","food_percent","active_seed","last_supply_day","mixer_volumes","seconds_focused","music_on","ambience_on","world_seed","last_seen_unix","rare_misses","simulation_count","timezone_bias_minutes"]:
        expected[field] = state.get(field)
    expected["tokens"] = state.get("_tokens")
    var normalized: Variant = JSON.parse_string(JSON.stringify(expected))
    return normalized is Dictionary and payload == normalized
func _backup_current(state: Node) -> Dictionary:
    var source: String = str(state.call("_save_path"))
    if source.is_empty(): return _error("当前是无存档预览模式，没有可备份的游戏文件。")
    state.call("save_state")
    if not FileAccess.file_exists(source): return _error("当前存档未能保存，已拒绝备份和重置。")
    var payload: Dictionary = state.call("_read_payload",source)
    if not _saved_state_matches(state,payload):
        return _error("存档保存或校验失败，已拒绝备份和重置。")
    var directory: String = "user://gm_backups"
    var code: Error = DirAccess.make_dir_recursive_absolute(directory)
    if code != OK: return _error("无法创建备份目录；未重置进度。")
    var stamp: String = Time.get_datetime_string_from_system().replace(":","-").replace("T","-")
    var target: String = directory.path_join("gm-" + stamp + "-" + str(Time.get_ticks_usec()) + ".json")
    if FileAccess.file_exists(target): return _error("备份文件名发生冲突；未覆盖备份或重置。")
    code = DirAccess.copy_absolute(source,target)
    if code != OK or not FileAccess.file_exists(target): return _error("备份复制失败；未重置进度。")
    if FileAccess.get_sha256(source) != FileAccess.get_sha256(target): return _error("备份完整性校验失败；未重置进度。")
    return _ok("当前进度已备份到 " + ProjectSettings.globalize_path(target),{"backup_path":target})

func _save_command(args: PackedStringArray, scene: Node, state: Node) -> Dictionary:
    if args.size() < 2: return _usage("save")
    var action: String = args[1].to_lower()
    if action != "reset" and args.size() != 2: return _usage("save")
    var path: String = str(state.call("_save_path"))
    match action:
        "status":
            return _ok(_mode(state) + "\n当前文件：" + (path if not path.is_empty() else "无") + "\n文件存在：" + ("是" if not path.is_empty() and FileAccess.file_exists(path) else "否"))
        "now", "write":
            if path.is_empty(): return _ok("预览状态仅在内存中，本次不会写入游戏存档。")
            state.call("save_state")
            var payload: Dictionary = state.call("_read_payload",path)
            if not _saved_state_matches(state,payload): return _error("存档保存校验失败。")
            return _ok("当前进度已保存：" + path)
        "backup": return _backup_current(state)
        "reload":
            if path.is_empty(): return _error("无存档预览模式不能重读磁盘存档。")
            if not FileAccess.file_exists(path): return _error("当前还没有可重读的存档。")
            if state.call("_read_payload",path).is_empty(): return _error("当前存档不可读；未覆盖内存中的进度。")
            state.call("load_state")
            state.emit_signal("changed")
            _refresh_scene_state(scene,state)
            return _ok("已重读当前存档：" + path)
        "reset":
            if args.size() != 3 or args[2] != "CONFIRM": return _error("重置会清空当前模式的收藏与记录。先备份，再输入：save reset CONFIRM")
            var backup_path: String = ""
            if not path.is_empty():
                var backup: Dictionary = _backup_current(state)
                if not bool(backup.ok): return backup
                backup_path = str(backup.get("backup_path",""))
            _reset_state(state)
            _refresh_scene_state(scene,state)
            return _ok("当前游戏状态已重置。" + ("\n原进度备份：" + ProjectSettings.globalize_path(backup_path) if not backup_path.is_empty() else "仅清空本次预览内存；正常存档没有改变。"),{"backup_path":backup_path})
        _: return _usage("save")

func _reset_state(state: Node) -> void:
    state.get("collection").clear()
    state.get("records").clear()
    state.get("favorites").clear()
    state.get("_tokens").clear()
    state.set("attraction","seeds")
    state.set("seed_stocks",StateData.SEED_DEFAULTS.duplicate())
    state.set("food_percent",68.0)
    state.set("active_seed","millet")
    state.set("last_supply_day","")
    state.set("mixer_volumes",StateData.MIX_DEFAULTS.duplicate())
    state.set("seconds_focused",0.0)
    state.set("music_on",true)
    state.set("ambience_on",true)
    state.set("world_seed",int(Time.get_unix_time_from_system()) ^ 734729)
    state.set("last_seen_unix",Time.get_unix_time_from_system())
    state.set("timezone_bias_minutes",int(Time.get_time_zone_from_system().get("bias",0)))
    state.set("last_summary","")
    state.set("rare_misses",0)
    state.set("simulation_count",0)
    state.set("_tick_elapsed",0.0)
    state.set("_batch_mutation",false)
    _save_and_notify(state)

func _refresh_scene_state(scene: Node, state: Node) -> void:
    if _world(scene) != null: _world(scene).call("set_attraction",str(state.get("attraction")))
    if scene.has_method("_refresh_counts"): scene.call("_refresh_counts")
    if scene.has_method("_update_audio"): scene.call("_update_audio",false)


func _snapshot_state(state: Node) -> Dictionary:
    var snapshot: Dictionary = {}
    for field in ["collection","records","favorites","attraction","seed_stocks","food_percent","active_seed","last_supply_day","mixer_volumes","seconds_focused","music_on","ambience_on","world_seed","last_seen_unix","timezone_bias_minutes","last_summary","rare_misses","simulation_count","storage_path_override","_tokens","_batch_mutation","_tick_elapsed"]:
        var value: Variant = state.get(field)
        snapshot[field] = value.duplicate(true) if value is Dictionary or value is Array else value
    snapshot["_gm_processing"] = state.is_processing()
    return snapshot

func _restore_snapshot(state: Node, snapshot: Dictionary) -> void:
    for field in snapshot:
        if str(field) == "_gm_processing": continue
        var value: Variant = snapshot[field]
        state.set(field, value.duplicate(true) if value is Dictionary or value is Array else value)
    state.set_process(bool(snapshot.get("_gm_processing",true)))

func _change_ui(scene: Node, state: Node, destination: String) -> Dictionary:
    var from_lab: bool = _is_lab(scene)
    var to_lab: bool = destination == "lab"
    if from_lab == to_lab:
        return _ok("已经位于 " + destination + "。\n" + _mode(state))
    var before: Dictionary = _snapshot_state(state)
    var had_game_snapshot: bool = state.has_meta("gm_game_snapshot")
    var old_game_snapshot: Variant = state.get_meta("gm_game_snapshot",{})
    var had_preview_flag: bool = state.has_meta("gm_preview_only")
    var old_preview_flag: bool = bool(state.get_meta("gm_preview_only",false))
    if to_lab:
        state.set_meta("gm_game_snapshot",{"state":before,"had_preview_flag":had_preview_flag,"preview_flag":old_preview_flag})
        state.set_meta("gm_preview_only",true)
        state.set_process(false)
    elif had_game_snapshot:
        var saved: Dictionary = old_game_snapshot
        _restore_snapshot(state,saved.get("state",{}))
        if bool(saved.get("had_preview_flag",false)): state.set_meta("gm_preview_only",bool(saved.get("preview_flag",false)))
        elif state.has_meta("gm_preview_only"): state.remove_meta("gm_preview_only")
        state.remove_meta("gm_game_snapshot")
    else:
        # A process launched as --ui-lab keeps its existing no-save mode even in Game.
        state.set_process(true)
    scene.get_tree().paused = false
    Engine.time_scale = 1.0
    var target: String = "res://scenes/ui_lab.tscn" if to_lab else "res://main.tscn"
    var code: Error = scene.get_tree().change_scene_to_file(target)
    if code != OK:
        _restore_snapshot(state,before)
        if had_preview_flag: state.set_meta("gm_preview_only",old_preview_flag)
        elif state.has_meta("gm_preview_only"): state.remove_meta("gm_preview_only")
        if had_game_snapshot: state.set_meta("gm_game_snapshot",old_game_snapshot)
        elif state.has_meta("gm_game_snapshot"): state.remove_meta("gm_game_snapshot")
        return _error("切换场景失败：" + error_string(code))
    state.emit_signal("changed")
    return _ok("已切换到 " + destination + "。\n" + _mode(state) + ("\n返回主游戏时会恢复进入样册前的进度。" if to_lab else ""),{"close":true})
func complete(prefix: String) -> Array[String]:
    var text: String = prefix.replace("\t"," ").to_lower()
    var slash: bool = text.begins_with("/")
    if slash: text = text.substr(1)
    var candidates: Array[String] = []
    for item in catalog(): candidates.append(str(item.name))
    for weather in WEATHER_IDS: candidates.append("weather " + weather)
    for time_name in ["dawn","day","dusk","night"]: candidates.append("time " + time_name)
    for category in ["all","birds","animals","insects","scenery","wonders"]:
        candidates.append("ids " + category)
        candidates.append("collect " + category)
    for id in _defs():
        var category: String = str(_defs()[id].get("category",""))
        if category in ["birds","animals","insects"]:
            candidates.append("spawn " + str(id))
            candidates.append("depart " + str(id))
            for phase: String in ["entry","idle","exit"]:
                candidates.append("motion " + str(id) + " " + phase)
                candidates.append("motion " + str(id) + " " + phase + " 0.5")
            candidates.append("visits " + str(id) + " 5")
        if category == "wonders": candidates.append("event " + str(id))
        candidates.append("collect " + str(id))
        candidates.append("guide " + str(id))
        candidates.append("favorite " + str(id) + " on")
        candidates.append("favorite " + str(id) + " off")
    for option in ["on","off","toggle"]: candidates.append("pause " + option)
    for option in ["on","off"]:
        candidates.append("focus " + option)
        candidates.append("audio music " + option)
        candidates.append("audio ambience " + option)
        for layer in LAYER_NAMES: candidates.append("layer " + layer + " " + option)
    for category in ["actors","events","all"]: candidates.append("clear " + category)
    for id in ["seeds","fruit","flowers","lantern"]: candidates.append("decor " + id)
    for seed_id: String in StateData.SEED_DEFAULTS:
        candidates.append("food stock " + seed_id + " " + str(StateData.SEED_DEFAULTS[seed_id]))
    candidates.append_array(["food status","food level 0","food level 100"])
    for option in ["status","now","backup","reload","reset"]: candidates.append("save " + option)
    for channel in ["master","music","rain","forest","river"]: candidates.append("volume " + channel + " -22")
    for style in Styles.all_styles(): candidates.append("style " + str(style.id))
    for style_index in range(Styles.all_styles().size()): candidates.append("style " + str(style_index + 1))
    candidates.append_array(["ui game","ui lab","speed 1","offline 24","screenshot"])
    var result: Array[String] = []
    for candidate in candidates:
        var suggestion: String = ("/" if slash else "") + candidate
        if candidate.to_lower().begins_with(text) and not result.has(suggestion): result.append(suggestion)
    return result
