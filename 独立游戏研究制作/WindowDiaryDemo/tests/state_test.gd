extends SceneTree

var failed: int = 0
var checks: int = 0
const TEST_PATH: String = "user://window_diary_demo_state_isolated_test.json"
const StateScript: Script = preload("res://scripts/diary_state.gd")
const EXPECTED_BIRDS: Array[String] = ["sparrow", "tit", "robin", "woodpecker", "owl", "kingfisher", "swallow", "magpie", "white_eye", "egret"]
const EXPECTED_ANIMALS: Array[String] = ["squirrel", "hedgehog", "cat", "bat"]
const EXPECTED_INSECTS: Array[String] = ["butterfly", "luna_moth", "jewel_beetle", "fireflies", "dragonfly", "ladybug", "stag_beetle"]
const EXPECTED_VISITORS: Array[String] = ["sparrow", "tit", "robin", "butterfly", "squirrel", "woodpecker", "owl", "luna_moth", "jewel_beetle", "fireflies", "kingfisher", "swallow", "magpie", "white_eye", "egret", "hedgehog", "cat", "bat", "dragonfly", "ladybug", "stag_beetle"]
const EXPECTED_SCENERY: Array[String] = ["scene_sun", "scene_rain", "scene_night", "scene_dusk", "scene_snow", "scene_fog", "scene_storm", "scene_dawn"]
const EXPECTED_WONDERS: Array[String] = ["ufo", "meteor", "supernova", "aurora", "star_whale", "time_ripple", "tree_spirit", "lanterns", "ghost_train", "moon_gate", "signal_echo", "aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]
const EXPANSION_WONDERS: Dictionary = {"aurora_crown": [2], "ember_clouds": [3], "meteor_shower": [2], "deep_one": [2, 5, 6], "sunken_city": [5, 2], "sky_jellyfish": [2], "twin_moons": [2], "floating_isles": [0, 7, 5], "bioluminescent_tide": [2, 3], "constellation_stag": [2]}
const NEW_ENTRIES: Array[String] = ["squirrel", "woodpecker", "owl", "luna_moth", "jewel_beetle", "fireflies", "aurora", "star_whale", "time_ripple", "tree_spirit", "kingfisher", "swallow", "magpie", "white_eye", "egret", "hedgehog", "cat", "bat", "dragonfly", "ladybug", "stag_beetle", "lanterns", "ghost_train", "moon_gate", "signal_echo", "scene_fog", "scene_storm", "scene_dawn", "aurora_crown", "ember_clouds", "meteor_shower", "deep_one", "sunken_city", "sky_jellyfish", "twin_moons", "floating_isles", "bioluminescent_tide", "constellation_stag"]

func check(condition: bool, label: String) -> void:
 checks += 1
 if condition:
  print("PASS ", label)
 else:
  failed += 1
  push_error("FAIL " + label)

func new_state() -> Node:
 var state: Node = StateScript.new()
 state.storage_path_override = TEST_PATH
 state.load_state()
 return state

func clean_test_files() -> void:
 for suffix in ["", ".bak", ".tmp", ".unreadable"]:
  if FileAccess.file_exists(TEST_PATH + suffix):
   DirAccess.remove_absolute(TEST_PATH + suffix)

func check_command_line_isolation() -> void:
 var args: PackedStringArray = OS.get_cmdline_user_args()
 if not (args.has("--test-mode") or args.has("--ui-test")):
  check(false, "run state tests with --test-mode or --ui-test to isolate autoload")
  return
 const normal_path: String = "user://window_diary_demo_save.json"
 var existed: bool = FileAccess.file_exists(normal_path)
 var previous_bytes: PackedByteArray = FileAccess.get_file_as_bytes(normal_path) if existed else PackedByteArray()
 var probe: Node = StateScript.new()
 # Deliberately do not set storage_path_override: exercise the real CLI path.
 probe.load_state()
 probe.discover("sparrow", "isolated CLI regression check", "cli_isolation_probe")
 check(probe._save_path() == "user://window_diary_demo_test_save.json", "CLI test invocation chooses separate save file")
 check(FileAccess.file_exists("user://window_diary_demo_test_save.json"), "CLI discovery writes the test file")
 if existed:
  check(FileAccess.get_file_as_bytes(normal_path) == previous_bytes, "CLI discovery leaves existing normal save byte-identical")
 else:
  check(not FileAccess.file_exists(normal_path), "CLI discovery does not create a normal save")
 if args.has("--ui-test") and not args.has("--test-mode"):
  check(probe._save_path() != normal_path, "ui-test alone is isolated without test-mode")
 probe.free()
func check_profiles_and_pools(state: Node) -> void:
 check(state.get_attraction_defs().size() == 4 and state.attraction == "seeds", "four decorations and default seed tray are available")
 var profile_metadata: bool = true
 for id: String in EXPECTED_VISITORS:
  var profile: Dictionary = state.get_profile(id)
  for field: String in ["personality", "preference", "keepsake_name", "keepsake_description", "bond_label"]:
   if str(profile.get(field, "")).is_empty(): profile_metadata = false
  if not state.get_attraction_defs().has(profile.get("attraction_id", "")): profile_metadata = false
 check(profile_metadata, "all biological visitors have individual profiles preferences and keepsakes")
 check(state.get_profile("invalid").is_empty() and state.get_profile("scene_fog").is_empty() and state.get_profile("star_whale").is_empty(), "scenery wonders and unknown ids have no invented visitor relationship")
 check(state.get_profile("cat").visits == 0 and not state.get_profile("cat").keepsake_unlocked and state.get_count() == 0, "reading an undiscovered profile does not discover or award a visit")
 var pool_ids_valid: bool = true
 var weights_correct: bool = true
 var coverage: Dictionary = {}
 for decor: String in state.get_attraction_defs():
  state.set_attraction(decor)
  for weather: int in range(8):
   var visit_pool: Array[String] = state.get_visit_pool(weather)
   var rare_pool: Array[String] = state.get_rare_pool(weather)
   if visit_pool.is_empty() or rare_pool.is_empty(): pool_ids_valid = false
   var all_ids: Array[String] = visit_pool + rare_pool
   for id: String in all_ids:
    if not state.get_entry_defs().has(id):
     pool_ids_valid = false
     continue
    var definition: Dictionary = state.get_entry_defs()[id]
    if not definition.get("weather_ids", []).has(weather) or definition.get("category", "") == "scenery": pool_ids_valid = false
    coverage[id] = true
   for id: String in EXPECTED_VISITORS + EXPECTED_WONDERS:
    var definition: Dictionary = state.get_entry_defs()[id]
    var expected_weight: int = (3 if definition.get("attraction_id", "") == decor else 1) if definition.get("weather_ids", []).has(weather) else 0
    if all_ids.count(id) != expected_weight: weights_correct = false
 check(pool_ids_valid, "every weather and decoration has valid compatible nonempty event pools")
 check(weights_correct, "preferred decor adds two weights while every compatible species retains its base chance")
 check(coverage.size() == EXPECTED_VISITORS.size() + EXPECTED_WONDERS.size(), "every visitor and wonder can appear naturally in a compatible weather")
 check(state.get_rare_pool(5).has("kingfisher") and not state.get_rare_pool(6).has("kingfisher") and state.get_visit_pool(3).has("bat") and not state.get_visit_pool(0).has("bat"), "water birds and evening animals respect their weather conditions")
 check(not state.get_visit_pool(-99).is_empty() and not state.get_rare_pool(99).is_empty(), "out of range weather falls back safely")
 state.set_attraction("fruit")
 check(not state.set_attraction("invalid") and state.attraction == "fruit" and state.get_count() == 0, "invalid decor cannot replace a valid choice or award observations")

func check_new_wonder_conditions(state: Node) -> void:
 var matching: bool = true
 var collection_only: bool = true
 for id: String in EXPANSION_WONDERS:
  if state.get_entry_defs()[id].get("weather_ids", []) != EXPANSION_WONDERS[id]: matching = false
  if not state.get_profile(id).is_empty(): collection_only = false
  for weather: int in range(8):
   if state.get_rare_pool(weather).has(id) != EXPANSION_WONDERS[id].has(weather): matching = false
 check(matching, "all ten new wonders appear only in their specified weather pools")
 check(collection_only, "new wonders do not alter the twenty one biological visitor profiles")
 check(state.get_rare_pool(2).count("aurora") == 1 and state.get_rare_pool(2).count("aurora_crown") == 1 and state.get_entry_defs()["aurora"]["name"] != state.get_entry_defs()["aurora_crown"]["name"], "original aurora and new crown remain distinct equally reachable encounters")

func check_full_previous_save() -> void:
 var original_collection: Dictionary = {}
 for id: String in StateScript.ENTRY_DEFS:
  if not EXPANSION_WONDERS.has(id):
   original_collection[id] = {"name":StateScript.ENTRY_DEFS[id]["name"], "count":7, "first_seen":"旧版首次", "last_seen":"旧版最近", "last_weather":"月夜"}
 var old_payload: Dictionary = {"version":2, "collection":original_collection,
  "records":[{"id":"aurora", "name":"极光", "note":"原有奇遇", "time":"旧版最近"}],
  "favorites":["sparrow", "aurora", "scene_fog"], "attraction":"fruit", "seconds_focused":77.0,
  "world_seed":123, "last_seen_unix":1728000000.0, "rare_misses":4, "simulation_count":2,
  "tokens":{"previous-save-token":true}}
 var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
 file.store_string(JSON.stringify(old_payload))
 file.close()
 var state: Node = new_state()
 var preserved: bool = state.get_count() == original_collection.size()
 for id: String in original_collection:
  if not state.collection.has(id) or int(state.collection[id].get("count",0)) != 7: preserved = false
 for id: String in EXPANSION_WONDERS:
  if state.collection.has(id): preserved = false
 check(preserved and original_collection.size() == 40, "all forty previous entries retain counts and new wonders remain undiscovered")
 check(state.is_favorite("aurora") and state.is_favorite("scene_fog") and state.attraction == "fruit" and state.get_profile("sparrow").keepsake_unlocked and state.rare_misses == 4, "full previous save keeps favorites decor keepsakes and rare progress")
 for id: String in EXPANSION_WONDERS:
  state.discover(id, "新增奇遇", "new_wonder:" + id)
 state.free()
 state = new_state()
 check(state.get_count() == StateScript.ENTRY_DEFS.size() and state.get_count() == 50 and int(state.collection["aurora"]["count"]) == 7 and int(state.collection["aurora_crown"]["count"]) == 1, "expanded fifty entry save preserves both old and new wonder histories")
 state.free()

func _initialize() -> void:
 check_command_line_isolation()
 clean_test_files()
 var state: Node = new_state()
 state.timezone_bias_minutes = 0
 var base: float = 20000.0 * 86400.0 + 8.0 * 3600.0
 var expected_ids: Array[String] = []
 expected_ids.append_array(EXPECTED_VISITORS)
 expected_ids.append_array(EXPECTED_SCENERY)
 expected_ids.append_array(EXPECTED_WONDERS)
 var definitions_match: bool = state.get_entry_defs().size() == expected_ids.size()
 for id: String in expected_ids:
  if not state.get_entry_defs().has(id): definitions_match = false
 check(definitions_match, "field guide contains every planned visitor scenery and wonder")
 var category_counts: Dictionary = {"birds":0, "animals":0, "insects":0, "scenery":0, "wonders":0}
 var metadata_complete: bool = true
 for entry: Dictionary in state.get_entry_defs().values():
  var category: String = str(entry.get("category", ""))
  if category_counts.has(category):
   category_counts[category] += 1
  for field: String in ["habitat", "behavior", "condition", "description", "hint", "color"]:
   if str(entry.get(field, "")).is_empty(): metadata_complete = false
 check(category_counts == {"birds":EXPECTED_BIRDS.size(), "animals":EXPECTED_ANIMALS.size(), "insects":EXPECTED_INSECTS.size(), "scenery":EXPECTED_SCENERY.size(), "wonders":EXPECTED_WONDERS.size()}, "field guide contains 10 birds 4 animals 7 insects 8 scenery and 21 wonders")
 check(metadata_complete, "every definition has field guide details")
 var offline_ids: Array[String] = []
 offline_ids.append_array(StateScript.NORMAL_IDS)
 offline_ids.append_array(StateScript.RARE_IDS)
 var offline_pools_match: bool = offline_ids.size() == EXPECTED_VISITORS.size() + EXPECTED_WONDERS.size()
 for id: String in EXPECTED_VISITORS + EXPECTED_WONDERS:
  if offline_ids.count(id) != 1: offline_pools_match = false
 for id: String in EXPECTED_SCENERY:
  if offline_ids.has(id): offline_pools_match = false
 check(offline_pools_match, "offline pools cover all visitors and wonders once without unlocking scenery")
 check_profiles_and_pools(state)
 check_new_wonder_conditions(state)
 check(not state.toggle_favorite("ufo") and state.favorites.is_empty(), "undiscovered entries cannot be favorited")
 check(state.settle_offline(base).is_empty(), "new save has no invented prehistory")
 check(state.discover("sparrow", "test", "one"), "first discovery returns true")
 check(not state.discover("sparrow", "duplicate", "one"), "duplicate token is ignored")
 check(int(state.collection["sparrow"]["count"]) == 1, "duplicate does not increment count")
 check(not state.discover("sparrow", "again", "two"), "repeat species is not a first discovery")
 check(int(state.collection["sparrow"]["count"]) == 2, "new occurrence increments count")
 check(not state.discover("invalid"), "unknown entry rejected")
 check(state.toggle_favorite("sparrow") and state.is_favorite("sparrow"), "discovered entry can be favorited")
 var observations_before_context: int = int(state.collection["sparrow"]["count"])
 var records_before_context: int = state.records.size()
 state.record_context("sparrow", "雨幕")
 check(int(state.collection["sparrow"]["count"]) == observations_before_context and state.records.size() == records_before_context, "weather context does not duplicate observations")
 check(state.collection["sparrow"].get("last_weather", "") == "雨幕", "weather context is attached")
 state.seconds_focused = 123.5
 state.music_on = false
 state.world_seed = 777
 state.save_state()
 state.free()
 state = new_state()
 check(state.attraction == "fruit", "decoration choice survives reload")
 check(state.get_count() == 1 and int(state.collection["sparrow"]["count"]) == 2, "collection survives reload")
 check(state.is_favorite("sparrow") and state.collection["sparrow"].get("last_weather", "") == "雨幕", "favorite and weather context survive reload")
 check(not state.toggle_favorite("sparrow") and not state.is_favorite("sparrow"), "favorite can be removed without removing discovery")
 check(is_equal_approx(state.seconds_focused, 123.5) and not state.music_on, "settings and focus survive reload")
 check(is_equal_approx(state.last_seen_unix, base), "settlement cursor survives reload")
 check(state.settle_offline(base - 100).is_empty() and is_equal_approx(state.last_seen_unix, base), "clock rollback cannot duplicate or rewind")
 var natural: Array = state.settle_offline(base + 2.0 * 86400.0)
 check(natural.size() >= 6 and natural.size() <= 8, "two days produce six ordinary and at most two rare events")
 var record_count: int = state.records.size()
 check(state.settle_offline(base + 2.0 * 86400.0).is_empty() and state.records.size() == record_count, "same timestamp cannot settle twice")
 state.save_state()
 state.free()
 state = new_state()
 check(state.settle_offline(base + 2.0 * 86400.0).is_empty(), "reopening cannot farm settled time")
 var cursor: float = state.last_seen_unix
 var pity: int = state.rare_misses
 var simulated: Array = state.simulate_offline(24)
 check(simulated.size() == 4, "24-hour demonstration produces four illustrative records")
 check(is_equal_approx(cursor, state.last_seen_unix) and pity == state.rare_misses, "demonstration does not move real clock or pity")
 check(state.last_summary.contains("演示"), "simulated summary is labeled")
 state.save_state()
 state.free()
 var broken: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
 broken.store_string("{broken file")
 broken.close()
 state = new_state()
 check(state.last_summary.contains("备份") and state.get_count() > 0, "corrupted primary recovers backup")
 state.last_seen_unix = base
 var catch_up: Array = state.settle_offline(base + 90.0 * 86400.0)
 check(catch_up.size() >= 90 and catch_up.size() <= 120, "catch-up work is bounded to 30 days")
 check(state.last_summary.contains("30 天") and state.last_summary.contains("未补算"), "catch-up cap is explicitly disclosed")
 state.rare_misses = 6
 state.last_seen_unix = base + 100.0 * 86400.0 + 11.0 * 3600.0
 state.settle_offline(base + 100.0 * 86400.0 + 12.0 * 3600.0)
 check(state.rare_misses == 0, "seventh rare check is guaranteed and resets pity")
 state.free()
 clean_test_files()
 var legacy: Dictionary = {"version":1, "collection":{"sparrow":{"name":"麻雀", "count":4,"first_seen":"旧日期", "last_seen":"旧日期"}},"records":[{"id":"sparrow", "name":"麻雀", "note":"旧版记录", "time":"旧日期"}],"world_seed":123,"last_seen_unix":base}
 var legacy_file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
 legacy_file.store_string(JSON.stringify(legacy))
 legacy_file.close()
 state = new_state()
 check(state.get_count() == 1 and int(state.collection["sparrow"]["count"]) == 4, "version one save preserves original collections")
 check(state.favorites.is_empty() and state.records.size() == 1, "legacy save receives empty favorites and preserves records")
 check(state.attraction == "seeds" and state.get_profile("sparrow").visits == 4 and not state.get_profile("sparrow").keepsake_unlocked, "legacy observations restore affinity and default decoration without resetting counts")
 check(state.discover("scene_rain", "风景观察", "scene:rain"), "new scenery entry unlocks normally")
 state.record_context("scene_rain", "听雨")
 state.toggle_favorite("scene_rain")
 state.free()
 state = new_state()
 check(state.get_count() == 2 and state.is_favorite("scene_rain"), "upgraded save persists scenery and favorite alongside legacy entries")
 check(int(state._read_payload(TEST_PATH).get("version",0)) == StateScript.SAVE_VERSION, "legacy save is written as current version")
 state.rare_misses = 5
 state.simulation_count = 3
 state.seconds_focused = 987.5
 state.save_state()
 state.free()
 state = new_state()
 check(state.get_count() == 2 and int(state.collection["sparrow"]["count"]) == 4 and state.is_favorite("scene_rain"), "existing version two collections counts and favorites survive expanded definitions")
 check(state.collection["scene_rain"].get("last_weather", "") == "听雨" and state.rare_misses == 5 and state.simulation_count == 3 and is_equal_approx(state.seconds_focused, 987.5), "existing version two context pity simulation and focus survive expansion")
 state.discover("sparrow", "第五次相遇", "keepsake:fifth")
 check(state.get_profile("sparrow").visits == 5 and state.get_profile("sparrow").keepsake_unlocked, "fifth genuine observation unlocks the visitor keepsake")
 state.discover("sparrow", "重复第五次", "keepsake:fifth")
 state.get_profile("sparrow")
 state.record_context("sparrow", "晨曦")
 state.toggle_favorite("sparrow")
 state.set_attraction("lantern")
 check(state.get_profile("sparrow").visits == 5, "duplicate tokens profile reads context favorites and decor cannot increase affinity")
 var new_entries_discovered: bool = true
 for id: String in NEW_ENTRIES:
  if not state.discover(id, "新增访客与奇遇", "expanded:" + id): new_entries_discovered = false
  state.toggle_favorite(id)
 check(new_entries_discovered, "every new visitor and wonder can be discovered and saved")
 state.free()
 state = new_state()
 check(state.get_profile("sparrow").visits == 5 and state.get_profile("sparrow").keepsake_unlocked and state.attraction == "lantern", "keepsake and decor survive reload using the original observation count")
 var new_entries_preserved: bool = state.get_count() == 2 + NEW_ENTRIES.size()
 for id: String in NEW_ENTRIES:
  if not state.collection.has(id) or not state.is_favorite(id):
   new_entries_preserved = false
  elif int(state.collection[id]["count"]) != 1:
   new_entries_preserved = false
 check(new_entries_preserved, "all expanded entries and favorites survive reload alongside legacy progress")
 check(not state.discover("star_whale", "重复记录", "expanded:star_whale") and int(state.collection["star_whale"]["count"]) == 1, "new wonder tokens remain deduplicated across reload")
 state.collection.erase("jewel_beetle")
 state.favorites.erase("jewel_beetle")
 for id: String in StateScript.RARE_IDS:
  if id != "jewel_beetle" and not state.collection.has(id): state.discover(id, "保底测试", "rare_setup:" + id)
 state.rare_misses = 6
 state.timezone_bias_minutes = 0
 var rare_slot: float = base + 200.0 * 86400.0 + 12.0 * 3600.0
 state.last_seen_unix = rare_slot - 1.0
 var rare_result: Array = state.settle_offline(rare_slot)
 check(rare_result.size() == 1 and str(rare_result[0].get("id", "")) == "jewel_beetle" and state.rare_misses == 0, "expanded rare guarantee prioritizes an undiscovered rare visitor")
 var simulated_rare_ids: Array[String] = []
 var simulation_cursor: float = state.last_seen_unix
 var simulation_pity: int = state.rare_misses
 for i: int in range(StateScript.RARE_IDS.size()):
  var batch: Array = state.simulate_offline(24)
  simulated_rare_ids.append(str(batch[-1]["id"]))
 var simulation_covers_rare_pool: bool = true
 for id: String in StateScript.RARE_IDS:
  if simulated_rare_ids.count(id) != 1: simulation_covers_rare_pool = false
 check(simulation_covers_rare_pool, "repeated offline demonstrations rotate through every rare visitor and wonder")
 check(is_equal_approx(state.last_seen_unix, simulation_cursor) and state.rare_misses == simulation_pity, "expanded simulations still preserve real settlement cursor and pity")
 state.free()
 clean_test_files()
 check_full_previous_save()
 clean_test_files()
 print("STATE TESTS: ", checks - failed, "/", checks, " passed")
 quit(0 if failed == 0 else 1)
