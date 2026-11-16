extends SceneTree
## Exact tier boundaries, reachable species, old-save migration and offline parity.
const StateScript: Script = preload("res://scripts/diary_state.gd")
const TEST_PATH: String = "user://window_diary_bird_expansion_isolated_test.json"
const REAL_PATH: String = "user://window_diary_demo_save.json"
const NEW_BIRDS: Array[String] = ["pigeon", "crow", "cockatiel", "dough_bird", "dandelion_bird", "paper_bird", "cloud_bird", "yarn_bird", "clockwork_bird", "alien_bird", "twin_bird", "invisible_bird", "shadow_bird", "inverted_bird", "galaxy_bird", "crescent_bird"]
const TIERS: Array[String] = ["普通", "罕见", "稀有", "神秘", "传说"]
var checks: int = 0
var failed: int = 0

func check(value: bool, label: String) -> void:
 checks += 1
 if value: print("PASS ", label)
 else:
  failed += 1
  push_error("FAIL " + label)

func rng_for(seed_value: int) -> RandomNumberGenerator:
 var rng: RandomNumberGenerator = RandomNumberGenerator.new()
 rng.seed = seed_value
 return rng

func new_state() -> Node:
 var state: Node = StateScript.new()
 state.storage_path_override = TEST_PATH
 state.load_state()
 return state

func cleanup() -> void:
 for suffix: String in ["", ".bak", ".tmp", ".unreadable"]:
  if FileAccess.file_exists(TEST_PATH + suffix): DirAccess.remove_absolute(TEST_PATH + suffix)

func exact_tiers(state: Node) -> void:
 var counts: Array[int] = [0, 0, 0, 0, 0]
 for ticket: int in range(10000): counts[TIERS.find(state.bird_tier_for_roll(ticket))] += 1
 check(counts == [9000, 690, 200, 100, 10], "all 10000 integer tickets give exactly 90 / 6.9 / 2 / 1 / 0.1 percent")
 var boundaries: Dictionary = {0:"普通", 8999:"普通", 9000:"罕见", 9689:"罕见", 9690:"稀有", 9889:"稀有", 9890:"神秘", 9989:"神秘", 9990:"传说", 9999:"传说"}
 var correct: bool = true
 for ticket: int in boundaries:
  if state.bird_tier_for_roll(ticket) != boundaries[ticket]: correct = false
 check(correct, "both edges of every rarity interval are correct")
 check(state.bird_tier_for_roll(-1) == "普通" and state.bird_tier_for_roll(10000) == "传说", "GM ticket bounds clamp safely")

func pools_and_selection(state: Node) -> void:
 var defs: Dictionary = state.get_entry_defs()
 var birds: int = 0
 var creatures: int = 0
 var complete: bool = true
 for id: String in defs:
  var definition: Dictionary = defs[id]
  if str(definition.category) in ["birds", "animals", "insects"]: creatures += 1
  if definition.category != "birds": continue
  birds += 1
  if not StateScript.BIRD_IDS.has(id) or not TIERS.has(definition.rarity): complete = false
  for key: String in ["name", "behavior", "condition", "description", "hint", "habitat", "personality", "preference", "favorite_seed", "keepsake_name", "keepsake_description"]:
   if str(definition.get(key, "")).is_empty(): complete = false
 check(defs.size() == 66 and birds == 26 and creatures == 37 and complete, "66 guide entries include 26 complete bird profiles and 37 creatures")
 check(defs.owl.rarity == "罕见" and defs.kingfisher.rarity == "罕见" and defs.egret.rarity == "普通", "existing bird IDs keep the requested new tiers")
 var disjoint: bool = true
 for id: String in StateScript.NORMAL_IDS + StateScript.RARE_IDS:
  if StateScript.BIRD_IDS.has(id): disjoint = false
 check(disjoint, "legacy normal and wonder pools cannot bypass bird tiers")
 var valid: bool = true
 for decoration: String in StateScript.ATTRACTION_DEFS:
  state.attraction = decoration
  for weather: int in range(8):
   for tier: String in TIERS:
    var pool: Array[String] = state.get_bird_pool(weather, tier)
    if pool.is_empty(): valid = false
    for id: String in StateScript.BIRD_TIER_IDS[tier]:
     if not pool.has(id): valid = false
    for id: String in pool:
     if defs[id].rarity != tier: valid = false
 check(valid, "every tier and all 26 species keep a base chance in all weather and decorations")
 state.attraction = "flowers"
 check(state.get_bird_pool(1, "神秘").count("invisible_bird") > state.get_bird_pool(0, "神秘").count("invisible_bird"), "weather increases a species preference within its tier")
 state.attraction = "seeds"
 state.active_seed = "millet"
 state.food_percent = 68.0
 var fed_weight: int = state.get_bird_pool(0, "普通").count("pigeon")
 state.food_percent = 0.0
 check(fed_weight == state.get_bird_pool(0, "普通").count("pigeon") + 2, "food bonus applies only while the matching tray has food")
 state.food_percent = 68.0
 # Find deterministic fixtures, not a Monte Carlo probability estimate.
 # Exact percentages were established by exhaustive integer tickets above.
 var seen: Dictionary = {}
 var tier_seeds: Dictionary = {}
 for candidate_seed: int in range(10000):
  var probe: RandomNumberGenerator = rng_for(candidate_seed)
  var tier: String = state.bird_tier_for_roll(probe.randi_range(0, 9999))
  if not tier_seeds.has(tier): tier_seeds[tier] = candidate_seed
  seen[state.select_bird(0, rng_for(candidate_seed))] = true
  if seen.size() == 26 and tier_seeds.size() == 5: break
 check(seen.size() == 26 and tier_seeds.size() == 5, "actual bird sampler reaches all 26 birds, including every approved new character")
 var tier_stable: bool = true
 var second_stage_correct: bool = true
 for tier: String in tier_seeds:
  for weather: int in range(8):
   for decoration: String in StateScript.ATTRACTION_DEFS:
    state.attraction = decoration
    var reference: RandomNumberGenerator = rng_for(int(tier_seeds[tier]))
    reference.randi_range(0, 9999)
    var pool: Array[String] = state.get_bird_pool(weather, tier)
    var expected: String = pool[reference.randi_range(0, pool.size() - 1)]
    state.rare_misses = 0
    var actual: String = state.select_bird(weather, rng_for(int(tier_seeds[tier])))
    state.rare_misses = 6
    var with_pity: String = state.select_bird(weather, rng_for(int(tier_seeds[tier])))
    if defs[actual].rarity != tier or actual != with_pity: tier_stable = false
    if actual != expected: second_stage_correct = false
 check(tier_stable, "weather decoration and old wonder pity never change the selected bird tier")
 check(second_stage_correct, "species selection consumes the second RNG roll inside its selected tier")
 check(state.collection.is_empty() and state.records.is_empty() and state.rare_misses == 6, "sampling alone cannot grant collection records or advance pity")
 for weather: int in [1, 4, 5, 6]:
  check(defs[state.select_visit(weather, rng_for(90))].category == "birds", "weather %d uses a bird when no compatible ordinary animal exists" % weather)

func offline_parity(state: Node) -> void:
 state.attraction = "seeds"
 state.active_seed = "millet"
 state.food_percent = 68.0
 state.world_seed = 777
 state.timezone_bias_minutes = 0
 state.rare_misses = 4
 var day_index: int = 20000
 var start: float = float(day_index) * 86400.0
 state.last_seen_unix = start
 var expected: Array[String] = []
 for hour: int in [6, 12, 18]:
  var rng: RandomNumberGenerator = rng_for(hash("%d:%d:%d" % [state.world_seed, day_index, hour]))
  expected.append(state.select_visit({6:7, 12:0, 18:3}[hour], rng))
 var records: Array = state.settle_offline(start + 18.0 * 3600.0)
 var actual: Array[String] = []
 for record: Dictionary in records: actual.append(str(record.id))
 check(actual == expected and records.size() == 3, "offline daytime visits use exactly the online visitor sampler with time-of-day light")
 check(state.rare_misses == 4, "bird settlement never consumes or resets wonder pity")
 var count_before: int = state.records.size()
 check(state.settle_offline(start + 18.0 * 3600.0).is_empty() and state.records.size() == count_before, "repeated offline timestamp cannot grant duplicate birds")
 var cursor: float = state.last_seen_unix
 var pity: int = state.rare_misses
 state.simulate_offline(24)
 check(state.last_seen_unix == cursor and state.rare_misses == pity, "offline demonstration preserves real cursor and wonder pity")

func old_save_migration() -> void:
 cleanup()
 var old_collection: Dictionary = {}
 for id: String in StateScript.ENTRY_DEFS:
  if not NEW_BIRDS.has(id):
   old_collection[id] = {"name":StateScript.ENTRY_DEFS[id].name, "count":7, "first_seen":"old first", "last_seen":"old last", "last_weather":"雨幕"}
 var payload: Dictionary = {"version":3, "collection":old_collection,
  "records":[{"id":"owl", "name":"猫头鹰", "note":"old observation", "time":"old last"}],
  "favorites":["owl", "kingfisher", "scene_rain"], "attraction":"fruit", "seed_stocks":{"sunflower":17, "millet":29, "berries":8}, "food_percent":42.0, "active_seed":"berries", "seconds_focused":987.0,
  "world_seed":777, "last_seen_unix":1728000000.0, "timezone_bias_minutes":0,
  "rare_misses":6, "simulation_count":8, "tokens":{"old-token":true}}
 var file: FileAccess = FileAccess.open(TEST_PATH, FileAccess.WRITE)
 file.store_string(JSON.stringify(payload))
 file.close()
 var state: Node = new_state()
 var preserved: bool = old_collection.size() == 50 and state.collection.size() == 50
 for id: String in old_collection:
  var restored: Dictionary = state.collection.get(id, {})
  if int(restored.get("count", 0)) != 7: preserved = false
  for key: String in ["name", "first_seen", "last_seen", "last_weather"]:
   if str(restored.get(key, "")) != str(old_collection[id][key]): preserved = false
 for id: String in NEW_BIRDS:
  if state.collection.has(id): preserved = false
 check(preserved, "all 50 existing entries retain their counts and context; 16 new birds start undiscovered")
 check(state.favorites == ["owl", "kingfisher", "scene_rain"] and state.get_profile("owl").keepsake_unlocked and state.rare_misses == 6 and state.simulation_count == 8 and state._tokens.has("old-token"), "existing favorites affinity wonder pity simulation and deduplication survive")
 check(state.seed_stocks == payload.seed_stocks and state.food_percent == 42.0 and state.active_seed == "berries" and state.seconds_focused == 987.0, "feeding inventory and focus progress survive the expansion")
 for id: String in NEW_BIRDS:
  for visit: int in range(5): state.discover(id, "expanded bird observation", "new:%s:%d" % [id, visit])
  state.discover(id, "duplicate must not count", "new:%s:4" % id)
  state.toggle_favorite(id)
  state.record_context(id, "晨曦")
 state.save_state()
 state.free()
 state = new_state()
 var new_saved: bool = state.collection.size() == 66
 for id: String in NEW_BIRDS:
  if int(state.collection.get(id, {}).get("count", 0)) != 5 or not state.is_favorite(id) or not state.get_profile(id).keepsake_unlocked: new_saved = false
 check(new_saved, "all new birds persist, unlock keepsakes on five genuine visits and reject duplicate tokens")
 check(int(state.collection.owl.count) == 7 and int(state.collection.kingfisher.count) == 7, "tier relabeling never resets existing bird counts")
 state.free()
 cleanup()

func _initialize() -> void:
 if not OS.get_cmdline_user_args().has("--test-mode"):
  push_error("Run with --test-mode to isolate the autoload save")
  quit(1)
  return
 var existed: bool = FileAccess.file_exists(REAL_PATH)
 var old_bytes: PackedByteArray = FileAccess.get_file_as_bytes(REAL_PATH) if existed else PackedByteArray()
 cleanup()
 var state: Node = new_state()
 exact_tiers(state)
 pools_and_selection(state)
 offline_parity(state)
 state.free()
 old_save_migration()
 check(FileAccess.get_file_as_bytes(REAL_PATH) == old_bytes if existed else not FileAccess.file_exists(REAL_PATH), "real player save remains byte-identical")
 print("BIRD EXPANSION STATE TESTS: ", checks - failed, "/", checks, " passed")
 quit(0 if failed == 0 else 1)
