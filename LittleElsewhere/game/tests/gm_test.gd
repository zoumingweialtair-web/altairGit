extends SceneTree
## Run: --headless --path game --script res://tests/gm_test.gd -- --test-mode --capture
## A unique override file exercises real persistence; --capture protects the autoload before/after it.
const Commands = preload("res://scripts/gm_commands.gd")
const Styles = preload("res://scripts/ui_lab_styles.gd")
const NORMAL_PATH: String = "user://window_diary_demo_save.json"
const WEATHER_IDS: Array[String] = ["sun","rain","night","dusk","snow","fog","storm","dawn"]
const CATEGORY_COUNTS: Dictionary = {"birds":10,"animals":4,"insects":7,"scenery":8,"wonders":21}


var checks: int = 0
var failures: int = 0
var backend: RefCounted
var state: Node
var scene: Node
var test_path: String = ""
var formal_files: Dictionary = {}
var owned_backups: Dictionary = {}
var original_time_scale: float = 1.0
var original_master_db: float = 0.0

func _initialize() -> void:
    for suffix: String in ["", ".bak", ".tmp", ".unreadable"]:
        var path: String=NORMAL_PATH+suffix
        formal_files[path]={"exists":FileAccess.file_exists(path),"hash":FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""}
    _run.call_deferred()

func check(ok: bool, label: String) -> void:
    checks+=1
    if ok:print("PASS ",label)
    else:
        failures+=1
        push_error("GM_TEST "+label)

func command(line: String, expected: bool=true) -> Dictionary:
    var result: Dictionary=backend.execute(line,scene)
    check(bool(result.get("ok",false))==expected,"command "+line+(" accepts" if expected else " rejects"))
    if bool(result.get("ok",false))!=expected:print("COMMAND_RESULT ",result)
    return result

func _reset_fixture() -> void:
    state.collection.clear()
    state.records.clear()
    state.favorites.clear()
    state._tokens.clear()
    state.simulation_count=0
    state.rare_misses=0
    state.last_seen_unix=1700000000.0
    state.seconds_focused=0.0
    state.save_state()

func _run() -> void:
    if not OS.get_cmdline_user_args().has("--capture"):
        check(false,"run GM tests with --test-mode --capture so even autoload teardown cannot touch normal progress")
        quit(1)
        return
    backend=Commands.new()
    state=root.get_node("DiaryState")
    state.set_process(false)
    test_path="user://window_diary_gm_test_save_%d_%d.json" % [OS.get_process_id(),Time.get_ticks_usec()]
    check(not FileAccess.file_exists(test_path),"unique test file starts absent")
    state.storage_path_override=test_path
    state.load_state()
    original_time_scale=Engine.time_scale
    original_master_db=AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master"))
    scene=load("res://main.tscn").instantiate()
    var fixture: GDScript=GDScript.new()
    fixture.source_code="extends \"res://scripts/main.gd\"\nfunc _capture() -> void:\n    pass\n"
    check(fixture.reload()==OK,"runtime main fixture compiles after autoload initialization")
    scene.set_script(fixture)
    root.add_child(scene)
    current_scene=scene
    scene.set_process(false)
    scene.get_node("World").set_process(false)
    scene.get_node("WeatherStage").set_process(false)
    await process_frame
    _reset_fixture()
    _test_information_and_validation()
    _test_weather_and_replays()
    _test_collection_and_profiles()
    _test_world_controls()
    _test_persistence()
    await _test_scene_roundtrip()
    current_scene=null
    scene.queue_free()
    await process_frame
    await _test_preview_mode()
    _cleanup()
    print("GM_TEST checks=%d failures=%d" % [checks,failures])
    quit(0 if failures==0 else 1)

func _test_information_and_validation() -> void:
    var catalog: Array=backend.catalog()
    var names: Dictionary={}
    var documented: bool=true
    for item: Dictionary in catalog:
        var name_value: String=str(item.get("name",""))
        if name_value.is_empty() or names.has(name_value) or str(item.get("usage","")).is_empty() or str(item.get("description","")).is_empty():documented=false
        names[name_value]=true
    check(documented and catalog.size()>=20,"catalog contains distinct documented whitelist commands")
    check(backend.complete("wea").has("weather"),"completion finds weather")
    check(backend.complete("spawn ki").has("spawn kingfisher"),"completion includes real creature IDs")
    check(backend.complete("event tw").has("event twin_moons"),"completion includes rare events")
    command("help event")
    var ids: Dictionary=command("ids all")
    check(str(ids.message).contains("50") and str(ids.message).contains("aurora_crown"),"ID catalog exposes all 50 entries")
    command("status")
    for invalid: String in ["unknown_command","weather moon","weather -1","weather 8","spawn absent","event absent","spawn aurora_crown","event sparrow","collect absent","favorite sparrow on","weather sun extra","weather sun\ncollect all","ids invalid"]:
        command(invalid,false)
    check(state.get_count()==0,"invalid commands and unknown favorites do not grant discoveries")

func _test_weather_and_replays() -> void:
    var world: Node=scene.get_node("World")
    var stage: Node=scene.get_node("WeatherStage")
    for i: int in range(WEATHER_IDS.size()):
        command("weather "+WEATHER_IDS[i])
        check(scene.weather_mode==i and world.weather==i and stage.weather==i,"weather reaches main, actors and layered scenery: "+WEATHER_IDS[i])
        check(not scene.scenery_recordable,"GM weather does not farm scenery: "+WEATHER_IDS[i])
    var before: int=scene.weather_mode
    command("weather 999",false)
    check(scene.weather_mode==before,"rejected weather leaves scene unchanged")
    for clock_name: String in {"dawn":7,"day":0,"dusk":3,"night":2}:
        command("time "+clock_name)
        check(scene.weather_mode==int({"dawn":7,"day":0,"dusk":3,"night":2}[clock_name]),"time selects an atmosphere: "+clock_name)
    var definitions: Dictionary=state.get_entry_defs()
    for id: String in definitions:
        var category: String=str(definitions[id].get("category",""))
        if category=="scenery":continue
        backend.execute("clear all",scene)
        var prefix: String="event " if category=="wonders" else "spawn "
        var result: Dictionary=backend.execute(prefix+id,scene)
        check(bool(result.ok) and world.get_active_event_ids().has(id),"uncollected entry can visibly replay: "+id)
        check(scene.weather_mode in definitions[id]["weather_ids"],"replay picks compatible weather: "+id)
    check(state.get_count()==0 and state.records.is_empty(),"all creature and wonder replays leave collection and records untouched")
    command("spawn sparrow")
    command("event aurora_crown")
    command("clear actors")
    check(world.actors.is_empty() and world.get_active_event_ids().has("aurora_crown"),"clear actors preserves active wonders")
    command("spawn kingfisher")
    command("clear events")
    check(world.spectacles.is_empty() and world.get_active_event_ids().has("kingfisher"),"clear events preserves creatures")
    command("clear all")
    check(world.get_active_event_ids().is_empty(),"clear all empties both world lists")

func _test_collection_and_profiles() -> void:
    for category: String in CATEGORY_COUNTS:
        _reset_fixture()
        command("collect "+category)
        var correct: bool=state.get_count()==int(CATEGORY_COUNTS[category])
        for id: String in state.collection:
            correct=correct and str(state.get_entry_defs()[id].category)==category and int(state.collection[id].count)==1
        check(correct,"category grants exactly its entries once: "+category)
    _reset_fixture()
    command("collect all")
    check(state.get_count()==50 and state.records.size()==50,"collect all grants 50 distinct observations")
    var old_count: int=int(state.collection.sparrow.count)
    command("collect sparrow")
    check(int(state.collection.sparrow.count)==old_count+1 and state.get_count()==50,"recollecting an entry increases visits without duplicate definitions")
    command("visits sparrow 5")
    var profile: Dictionary=state.get_profile("sparrow")
    check(profile.visits==5 and profile.keepsake_unlocked and profile.bond_label=="熟悉的邻居","five visits unlock the memento and familiar bond")
    command("visits sparrow 10")
    check(state.get_profile("sparrow").bond_label=="窗边老友","ten visits produce the longtime friend bond")
    for bad: String in ["visits sparrow 0","visits sparrow 1001","visits sparrow 2.5","visits aurora_crown 5"]:
        command(bad,false)
    check(state.get_profile("sparrow").visits==10,"invalid visit counts preserve the previous relationship")
    command("favorite sparrow on")
    command("favorite sparrow on")
    check(state.favorites.count("sparrow")==1,"favorite on is idempotent")
    command("favorite sparrow off")
    check(not state.is_favorite("sparrow"),"favorite off removes the selection")
    var cursor: float=state.last_seen_unix
    var simulations: int=state.simulation_count
    command("offline 24")
    check(state.simulation_count==simulations+1 and not state.records.is_empty() and state.last_seen_unix==cursor,"offline simulation adds records without changing the real cursor")
    simulations=state.simulation_count
    for invalid: String in ["offline 0","offline 169","offline -1","offline 1.5"]:command(invalid,false)
    check(state.simulation_count==simulations and state.last_seen_unix==cursor,"invalid offline ranges cannot simulate or change the cursor")

func _test_world_controls() -> void:
    var world: Node=scene.get_node("World")
    for id: String in ["seeds","fruit","flowers","lantern"]:
        command("decor "+id)
        check(state.attraction==id and world.attraction==id,"decoration updates state and visible world: "+id)
    command("decor unknown",false)
    check(state.attraction=="lantern","invalid decoration is non-mutating")
    command("focus on")
    check(scene.focusing and world.quiet and not scene.normal_ui.visible and scene.focus_ui.visible,"focus mode hides normal UI and quiets visitors")
    command("focus off")
    check(not scene.focusing and not world.quiet and scene.normal_ui.visible,"focus mode restores the normal scene")
    for speed: String in ["0.1","8","1"]:
        command("speed "+speed)
        check(is_equal_approx(Engine.time_scale,float(speed)),"speed reaches the running engine: "+speed)
    for bad: String in ["speed 0","speed 8.1","speed -1","speed nan","speed inf"]:command(bad,false)
    check(is_equal_approx(Engine.time_scale,1.0),"invalid speeds preserve normal time")
    command("pause on")
    check(paused,"pause freezes the scene tree")
    command("pause toggle")
    check(not paused,"pause toggle resumes the world")
    command("pause off")
    command("layers")
    var cloud: CanvasItem=scene.get_node("WeatherStage/FarClouds") as CanvasItem
    command("layer farclouds off")
    check(not cloud.visible,"case-insensitive layer command hides the actual layer")
    command("layer FarClouds on")
    check(cloud.visible,"layer on restores the layer")
    command("layer ../World off",false)
    check(world.visible and cloud.visible,"layer names cannot escape the allowed scene layers")
    command("audio music off")
    check(not state.music_on,"music preference changes")
    command("audio music on")
    check(state.music_on,"music preference restores")
    command("audio ambience off")
    check(not state.ambience_on,"ambience preference changes")
    command("volume music -22")
    check(is_equal_approx(scene.music_player.volume_db,-22.0),"volume reaches the actual audio player")
    command("volume music 1",false)
    check(is_equal_approx(scene.music_player.volume_db,-22.0),"invalid volume leaves the player unchanged")
    command("style 1",false)

func _register_backup(result: Dictionary, expected_collection: Dictionary) -> void:
    var path: String=str(result.get("backup_path",""))
    var owned: bool=path.begins_with("user://gm_backups/gm-") and FileAccess.file_exists(path)
    check(owned,"backup returns an existing managed backup path")
    if not owned:return
    var payload: Dictionary=state._read_payload(path)
    check(not payload.is_empty() and _equivalent(payload.get("collection",{}),expected_collection),"backup contains the complete pre-operation collection")
    if not payload.is_empty():owned_backups[path]=FileAccess.get_sha256(path)

func _test_persistence() -> void:
    command("favorite sparrow on")
    command("save now")
    check(state._save_path()==test_path and FileAccess.file_exists(test_path),"save writes only the unique override file")
    var expected: Dictionary=state.collection.duplicate(true)
    var saved_hash: String=FileAccess.get_sha256(test_path)
    for invalid: String in ["save reset","save reset confirm","save reset CONFIRM extra"]:
        command(invalid,false)
        check(state.collection==expected and FileAccess.get_sha256(test_path)==saved_hash,"unconfirmed reset preserves memory and disk: "+invalid)
    var backup: Dictionary=command("save backup")
    _register_backup(backup,expected)
    if str(backup.get("backup_path","")).begins_with("user://gm_backups/"):
        check(FileAccess.get_sha256(backup.backup_path)==FileAccess.get_sha256(test_path),"backup is byte-identical to the saved source")
    state.collection.clear()
    state.favorites.clear()
    command("save reload")
    check(_equivalent(state.collection,expected) and state.is_favorite("sparrow"),"reload restores persisted collection and favorites")
    var reset: Dictionary=command("save reset CONFIRM")
    _register_backup(reset,expected)
    check(state.get_count()==0 and state.records.is_empty() and state.favorites.is_empty(),"confirmed reset clears collection records and favorites")
    check(state.attraction=="seeds" and state.seconds_focused==0.0,"confirmed reset restores progression settings")
    check(state._read_payload(test_path).get("collection",{}).is_empty(),"reset persists its empty state to the isolated file")
    _check_formal_files()

func _equivalent(first: Variant, second: Variant) -> bool:
    # JSON saves intentionally serialize floating timestamps with finite precision.
    return JSON.parse_string(JSON.stringify(first))==JSON.parse_string(JSON.stringify(second))

func _test_scene_roundtrip() -> void:
    command("collect sparrow")
    command("visits sparrow 3")
    command("favorite sparrow on")
    command("decor fruit")
    state.seconds_focused=123.0
    state.rare_misses=2
    state.simulation_count=7
    command("save now")
    var original_hash: String=FileAccess.get_sha256(test_path)
    var original_state: Dictionary={}
    for property: String in ["collection","records","favorites","attraction","seconds_focused","music_on","ambience_on","world_seed","last_seen_unix","timezone_bias_minutes","last_summary","rare_misses","simulation_count","_tokens","_batch_mutation","_tick_elapsed"]:
        var value: Variant=state.get(property)
        original_state[property]=value.duplicate(true) if value is Dictionary or value is Array else value
    var processing: bool=state.is_processing()
    command("ui lab")
    await process_frame
    await process_frame
    scene=current_scene
    check(is_instance_valid(scene) and scene.has_method("_change_style"),"game-to-lab command loads the actual preview scene")
    if not is_instance_valid(scene):return
    scene.set_process(false)
    scene.get_node("World").set_process(false)
    scene.get_node("WeatherStage").set_process(false)
    check(state._save_path().is_empty(),"runtime lab guard takes precedence over the persistent override path")
    command("collect all")
    command("visits sparrow 999")
    command("favorite sparrow off")
    command("decor lantern")
    command("save reset CONFIRM")
    command("collect owl")
    check(FileAccess.get_sha256(test_path)==original_hash,"lab data commands leave the original game save byte-identical")
    command("ui game")
    await process_frame
    await process_frame
    scene=current_scene
    check(is_instance_valid(scene) and scene.has_method("_change_weather") and not scene.has_method("_change_style"),"lab-to-game command restores the real game scene")
    if not is_instance_valid(scene):return
    scene.set_process(false)
    scene.get_node("World").set_process(false)
    scene.get_node("WeatherStage").set_process(false)
    var restored: bool=true
    for property: String in original_state:
        restored=restored and _equivalent(state.get(property),original_state[property])
    check(restored,"round trip restores all original progress and session fields")
    check(state._save_path()==test_path and state.is_processing()==processing,"round trip restores persistent path and processing state")
    check(FileAccess.get_sha256(test_path)==original_hash,"returning to the game does not rewrite the original save")
    _check_formal_files()

func _test_preview_mode() -> void:
    state.storage_path_override=""
    check(state._save_path().is_empty(),"capture mode resumes no-file persistence after removing override")
    state.load_state()
    scene=load("res://scenes/ui_lab.tscn").instantiate()
    root.add_child(scene)
    current_scene=scene
    scene.set_process(false)
    scene.get_node("World").set_process(false)
    scene.get_node("WeatherStage").set_process(false)
    await process_frame
    for n: int in range(1,11):
        command("style "+str(n))
        check(scene.style_index==n-1,"style selects the real UI scheme: "+str(n))
    command("style quiet_glass")
    check(scene.style_index==1,"style accepts a named scheme")
    command("style 0",false)
    var style_count: int = Styles.all_styles().size()
    command("style "+str(style_count+1),false)
    check(scene.style_index==1,"invalid styles keep the current scheme")
    check(style_count==20,"ten original schemes and ten concept-art proposals are available")
    var style_picker: OptionButton=root.get_node("GMConsole").find_child("StylePicker",true,false) as OptionButton
    check(style_picker!=null and style_picker.item_count==style_count,"GM picker includes every registered scheme")
    command("style "+str(style_count))
    check(scene.style_index==style_count-1 and scene.get_active_style_kind()=="concept","GM selects proposal 20 as static concept art")
    var old_weather: int=scene.weather_index
    var old_actor_count: int=scene.world.actors.size()
    var old_event_count: int=scene.world.spectacles.size()
    var old_sky_visible: bool=scene.stage.get_node("Sky").visible
    for blocked: String in ["weather rain","time dusk","spawn squirrel","event aurora_crown","focus on","guide sparrow","layer Sky off","layers","clear actors"]:
        var rejected: Dictionary=command(blocked,false)
        check(str(rejected.get("message","")).contains("原画"),"concept command explains the static proposal boundary")
    check(scene.weather_index==old_weather and scene.world.actors.size()==old_actor_count and scene.world.spectacles.size()==old_event_count and scene.stage.get_node("Sky").visible==old_sky_visible,"blocked visual commands leave live-scene state unchanged")
    check(backend.complete("style 2").has("style 20"),"numeric completion includes the last proposal")
    command("style mossbound_storybook")
    check(scene.style_index==10,"GM accepts a new concept art ID")
    command("style quiet_glass")
    command("collect all")
    check(state.get_count()==50 and state._save_path().is_empty(),"preview collection commands remain in memory")
    command("guide twin_moons")
    var snapshot: Dictionary=scene.guide.get_snapshot()
    check(snapshot.visible_count==6 and snapshot.selected=="twin_moons" and not snapshot.known,"preview sample guide stays independent of GM memory collection")
    command("save backup",false)
    command("save reload",false)
    var result: Dictionary=command("save reset CONFIRM")
    check(str(result.get("backup_path","")).is_empty() and state.get_count()==0,"preview reset needs no file and clears only transient data")
    _check_formal_files()
    current_scene=null
    scene.queue_free()
    await process_frame

func _check_formal_files() -> void:
    var unchanged: bool=true
    for path: String in formal_files:
        var old: Dictionary=formal_files[path]
        unchanged=unchanged and FileAccess.file_exists(path)==bool(old.exists)
        if bool(old.exists):unchanged=unchanged and FileAccess.get_sha256(path)==str(old.hash)
    check(unchanged,"formal save and its backup/temp/recovery companions remain byte-identical")

func _cleanup() -> void:
    paused=false
    Engine.time_scale=original_time_scale
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),original_master_db)
    state.set_process(false)
    state.storage_path_override=""
    for suffix: String in ["", ".bak", ".tmp", ".unreadable"]:
        var path: String=test_path+suffix
        if not test_path.is_empty() and test_path.begins_with("user://window_diary_gm_test_save_") and FileAccess.file_exists(path):DirAccess.remove_absolute(path)
    for path: String in owned_backups:
        if FileAccess.file_exists(path) and FileAccess.get_sha256(path)==str(owned_backups[path]):DirAccess.remove_absolute(path)
    check(not FileAccess.file_exists(test_path),"unique test save is cleaned after validation")
    _check_formal_files()
