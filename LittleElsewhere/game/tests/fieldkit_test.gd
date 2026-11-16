extends SceneTree

const StateScript=preload("res://scripts/diary_state.gd")
const TEST_PATH="user://fieldkit_isolated_test.json"
var checks: int=0
var failures: int=0
var main: Control
var original_hash: String=""
var normal_path: String="user://window_diary_demo_save.json"

func _initialize() -> void:
 call_deferred("run")

func check(value: bool, label: String) -> void:
 checks+=1
 if not value:
  failures+=1
  push_error("FIELDKIT_FAIL "+label)
 else:print("FIELDKIT_OK "+label)

func cleanup() -> void:
 for suffix: String in ["",".bak",".tmp"]:
  if FileAccess.file_exists(TEST_PATH+suffix):DirAccess.remove_absolute(TEST_PATH+suffix)

func run() -> void:
 original_hash=FileAccess.get_sha256(normal_path) if FileAccess.file_exists(normal_path) else "missing"
 cleanup()
 var state: Node=StateScript.new()
 state.storage_path_override=TEST_PATH
 state.load_state()
 var before: Dictionary=state.seed_stocks.duplicate()
 check(not state.feed("unknown",3).ok,"unknown food rejected")
 check(not state.feed("millet",0).ok and not state.feed("millet",-2).ok,"nonpositive quantity rejected")
 check(not state.feed("millet",1000).ok and state.seed_stocks==before,"insufficient inventory is atomic")
 var result: Dictionary=state.feed("berries",3)
 check(result.ok and result.used==3 and state.seed_stocks.berries==9,"feeding consumes exact stock")
 check(state.food_percent==74.0 and state.attraction=="fruit","feeding fills tray and changes attraction")
 state.food_percent=99.0
 result=state.feed("millet",10)
 check(result.ok and result.used==1 and state.food_percent==100.0,"near full tray only consumes needed portion")
 before=state.seed_stocks.duplicate()
 check(not state.feed("millet",1).ok and state.seed_stocks==before,"full tray does not waste inventory")
 state.consume_food("sparrow")
 check(state.food_percent==98.0,"actual bird visit consumes tray food")
 state.consume_food("aurora")
 check(state.food_percent==98.0,"scenery and wonders do not consume food")
 check(state.claim_supplies() and not state.claim_supplies(),"daily supply can only be claimed once")
 check(state.set_mix("river",0.31) and not state.set_mix("unknown",0.4),"four channel mixer validates track")
 state.save_state()
 var restored: Node=StateScript.new()
 restored.storage_path_override=TEST_PATH
 restored.load_state()
 check(restored.seed_stocks==state.seed_stocks and restored.food_percent==state.food_percent,"inventory and tray survive reload")
 check(restored.active_seed==state.active_seed and not restored.supplies_available(),"seed and supply claim survive reload")
 check(is_equal_approx(restored.mixer_volumes.river,0.31),"mixer gains survive reload")
 var legacy: Dictionary=restored._read_payload(TEST_PATH)
 legacy.version=2
 for key: String in ["seed_stocks","food_percent","active_seed","last_supply_day","mixer_volumes"]:legacy.erase(key)
 var file: FileAccess=FileAccess.open(TEST_PATH,FileAccess.WRITE)
 file.store_string(JSON.stringify(legacy))
 file.close()
 restored.load_state()
 check(restored.seed_stocks==StateScript.SEED_DEFAULTS and restored.food_percent==68.0,"version two saves migrate without losing usability")
 state.storage_path_override=""
 restored.storage_path_override=""
 state.free()
 restored.free()
 cleanup()
 root.size=Vector2i(1440,810)
 root.content_scale_size=Vector2i(1440,810)
 main=load("res://main.tscn").instantiate()
 root.add_child(main)
 current_scene=main
 main.set_process(false)
 await process_frame
 var diary: Node=root.get_node("DiaryState")
 diary.collection.clear()
 diary.records.clear()
 diary.favorites.clear()
 diary.seed_stocks=StateScript.SEED_DEFAULTS.duplicate()
 diary.food_percent=50.0
 main._refresh_counts()
 check(main.normal_ui.visible and not main.focus_ui.visible,"normal observation starts with compact HUD")
 await click_button("FeedButton")
 check(main.fieldkit.find_child("FeedConfirm",true,false)!=null,"real feed toolbar opens working panel")
 var food_before: float=diary.food_percent
 await click_button("FeedConfirm")
 check(diary.food_percent>food_before,"actual feed click reaches game state")
 diary.food_percent=100.0
 main._refresh_counts()
 check(main.fieldkit.find_child("FeedConfirm",true,false).disabled,"full tray disables actual feed button")
 main.fieldkit.close_panel()
 await click_button("GuideButton")
 check(is_instance_valid(main.modal),"real guide button opens full collection")
 main._close_modal()
 main._fieldkit_action("weather",{"index":1})
 check(main.weather_mode==1 and main.scene_view.weather==1,"weather UI changes world weather")
 diary.discover("butterfly","earlier observation")
 await click_button("FocusButton")
 await click_button("FocusStart")
 check(main.focusing and main.focus_target in [1500.0,2700.0,3600.0] and not main.normal_ui.visible,"focus panel starts real countdown and hides HUD")
 main._process(2.0)
 var focused: float=main.focus_elapsed
 main._fieldkit_action("focus_pause",{})
 main._process(2.0)
 check(main.focus_elapsed==focused,"pause stops timer without stopping world")
 main.scene_view.trigger("sparrow")
 check(main.focus_new_count==1 and not main.toast_panel.visible,"focus discovery enters quiet queue")
 await click_button("QuietQueueButton")
 check(main.fieldkit.get_snapshot().panel=="records","quiet queue opens compact panel")
 check(main.fieldkit.find_child("Visit_sparrow",true,false)!=null and main.fieldkit.find_child("Visit_butterfly",true,false)==null,"quiet queue excludes earlier observations")
 main._fieldkit_action("focus_pause",{})
 main.focus_target=main.focus_elapsed+1.0
 main._process(1.1)
 check(not main.focusing and main.normal_ui.visible,"countdown completes and restores observation")
 main._fieldkit_action("volume",{"track":"river","value":0.42})
 main._change_weather(3)
 check(is_equal_approx(diary.mixer_volumes.river,0.42),"weather switch preserves user's mixer gain")
 var count: int=diary.get_count()
 main._replay("sparrow")
 check(diary.get_count()==count,"animation replay does not award collection")
 check(main.scene_view.get_actor_lifecycle_snapshot("sparrow").phase=="entry","replay restarts existing visitor at entrance")
 check((FileAccess.get_sha256(normal_path) if FileAccess.file_exists(normal_path) else "missing")==original_hash,"test leaves normal save byte-identical")
 print("FIELDKIT_TESTS: %d/%d passed" % [checks-failures,checks])
 quit(1 if failures else 0)

func click_button(button_name: String) -> void:
 var button: Button=main.find_child(button_name,true,false) as Button
 if button==null:
  check(false,"missing button "+button_name)
  return
 # Wait for the popup's short entrance tween before targeting its real rectangle.
 await create_timer(0.25).timeout
 var point: Vector2=button.get_global_rect().get_center()
 var motion: InputEventMouseMotion=InputEventMouseMotion.new()
 motion.position=point
 root.push_input(motion,true)
 await process_frame
 for pressed: bool in [true,false]:
  var event: InputEventMouseButton=InputEventMouseButton.new()
  event.button_index=MOUSE_BUTTON_LEFT
  event.position=point
  event.pressed=pressed
  root.push_input(event,true)
  await process_frame
