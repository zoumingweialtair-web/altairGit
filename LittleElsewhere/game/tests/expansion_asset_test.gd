extends SceneTree
## Run with a real renderer: --script res://tests/expansion_asset_test.gd -- --test-mode --capture
## Reads the committed SpriteFrames and renders the reusable scene; never writes save files.
const Expansion = preload("res://scripts/expansion_bird_art.gd")
const Art = preload("res://scripts/visitor_art.gd")
const BirdScene: PackedScene = preload("res://scenes/expansion_bird.tscn")
const MODES: Array[String] = ["idle", "fly", "feed", "special", "land", "takeoff"]
const SCENE_MODES: Array[String] = ["idle", "fly", "feed", "lifecycle"]
const FRAME_SIZE: Vector2i = Vector2i(192, 192)
const FRAME_COUNT: int = 8
const REAL_SAVE: String = "user://window_diary_demo_save.json"
var checks: int = 0
var failures: int = 0
var frames_checked: int = 0
var transparent_frames: int = 0
var clipped_frames: int = 0
var scene_samples: int = 0
var min_visible_pixels: int = 1 << 30
var min_edge_clearance: int = 1 << 30
var max_edge_alpha: int = 0

func _initialize() -> void:
 run.call_deferred()

func check(condition: bool, label: String) -> void:
 checks += 1
 if not condition:
  failures += 1
  push_error("EXPANSION_ASSET_FAIL " + label)

func save_fingerprint() -> Dictionary:
 var result: Dictionary = {}
 for suffix: String in ["", ".bak", ".tmp", ".unreadable"]:
  var path: String = REAL_SAVE + suffix
  result[suffix] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
 return result

func measure(source: Image) -> Dictionary:
 if source == null or source.is_empty():
  return {"valid": false}
 var image: Image = source.duplicate()
 if image.is_compressed():
  image.decompress()
 image.convert(Image.FORMAT_RGBA8)
 var data: PackedByteArray = image.get_data()
 var width: int = image.get_width()
 var height: int = image.get_height()
 var visible: int = 0
 var transparent: int = 0
 for offset: int in range(3, data.size(), 4):
  var alpha: int = data[offset]
  if alpha >= 16:
   visible += 1
  elif alpha == 0:
   transparent += 1
 var edge_alpha: int = 0
 for y: int in height:
  for x: int in [0, 1, width - 2, width - 1]:
   edge_alpha = maxi(edge_alpha, data[(y * width + x) * 4 + 3])
 for x: int in width:
  for y: int in [0, 1, height - 2, height - 1]:
   edge_alpha = maxi(edge_alpha, data[(y * width + x) * 4 + 3])
 var used: Rect2i = image.get_used_rect()
 var clearance: int = mini(mini(used.position.x, used.position.y), mini(width - used.end.x, height - used.end.y))
 return {"valid": true, "size": image.get_size(), "visible": visible, "transparent": transparent, "edge_alpha": edge_alpha, "clearance": clearance, "signature": hash(data)}

func verify_frames() -> void:
 for id: String in Expansion.IDS:
  var path: String = "res://assets/creatures/expansion/animations/" + id + ".tres"
  var frames: SpriteFrames = load(path) as SpriteFrames
  check(frames != null, id + " SpriteFrames loads")
  if frames == null:
   continue
  var names: PackedStringArray = frames.get_animation_names()
  var exact_modes: bool = names.size() == MODES.size()
  for mode: String in MODES:
   exact_modes = exact_modes and names.has(mode)
  check(exact_modes, id + " has exactly six named animations")
  for mode: String in MODES:
   check(frames.has_animation(mode), id + "/" + mode + " exists")
   if not frames.has_animation(mode):
    continue
   check(frames.get_frame_count(mode) == FRAME_COUNT, id + "/" + mode + " has eight frames")
   check(frames.get_animation_speed(mode) > 0.0, id + "/" + mode + " has a positive playback speed")
   var signatures: Dictionary = {}
   for frame: int in frames.get_frame_count(mode):
    var label: String = "%s/%s/%d" % [id, mode, frame]
    var texture: Texture2D = frames.get_frame_texture(mode, frame)
    check(texture is AtlasTexture, label + " uses a real atlas texture")
    if texture == null:
     continue
    var atlas: AtlasTexture = texture as AtlasTexture
    if atlas != null:
     check(atlas.atlas != null and atlas.atlas.get_width() == 1536 and atlas.atlas.get_height() == 1152, label + " references the full 8 by 6 sheet")
    var stats: Dictionary = measure(texture.get_image())
    check(bool(stats["valid"]), label + " image can be read")
    if not bool(stats["valid"]):
     continue
    frames_checked += 1
    check(stats["size"] == FRAME_SIZE, label + " is 192 square")
    check(int(stats["visible"]) > 20, label + " contains actual painted pixels")
    check(int(stats["transparent"]) > FRAME_SIZE.x * FRAME_SIZE.y / 2, label + " has a transparent background")
    check(int(stats["edge_alpha"]) == 0 and int(stats["clearance"]) >= 2, label + " has no clipped alpha at any edge")
    min_visible_pixels = mini(min_visible_pixels, int(stats["visible"]))
    min_edge_clearance = mini(min_edge_clearance, int(stats["clearance"]))
    max_edge_alpha = maxi(max_edge_alpha, int(stats["edge_alpha"]))
    if int(stats["transparent"]) > 0:
     transparent_frames += 1
    if int(stats["edge_alpha"]) > 0:
     clipped_frames += 1
    signatures[stats["signature"]] = true
   # Shadow keeps sliding and breathing on the ground even in the generic fly row.
   # Check rendered change, never require wings or an airborne pose for this species.
   check(signatures.size() >= 2, id + "/" + mode + " contains visibly different animation frames")
  print("EXPANSION_ASSET_BIRD ", id, " animations=6 frames=48")

func verify_scene() -> void:
 var viewport: SubViewport = SubViewport.new()
 viewport.size = Vector2i(256, 256)
 viewport.transparent_bg = true
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var bird: Node2D = BirdScene.instantiate() as Node2D
 check(bird != null, "reusable expansion_bird.tscn instantiates")
 if bird == null:
  viewport.queue_free()
  return
 viewport.add_child(bird)
 bird.position = Vector2(128, 128)
 check(bird.get_script() != null and bird.has_method("_process") and bird.has_method("_draw"), "scene contains the live articulated renderer")
 for id: String in Expansion.IDS:
  bird.set("bird_id", id)
  check(Expansion.is_available(id) and Art.is_creature(id), id + " resolves to available shared artwork")
  for mode: String in SCENE_MODES:
   bird.set("animation", mode)
   bird.set("clock_time", 5.7)
   for tick: int in 3:
    await process_frame
   RenderingServer.force_draw(false)
   var actor: Dictionary = bird.get("actor")
   var label: String = id + "/scene/" + mode
   check(str(actor.get("id", "")) == id, label + " processes the selected ID")
   check(actor.get("pos", Vector2.INF) == Vector2.ZERO, label + " keeps the contact origin local")
   var bounds: Rect2 = Art.bounds_for_actor(actor)
   check(bounds.position.is_finite() and bounds.size.is_finite() and bounds.size.x > 10.0 and bounds.size.y > 10.0, label + " has usable local render bounds")
   var stats: Dictionary = measure(viewport.get_texture().get_image())
   check(bool(stats.get("valid", false)) and int(stats.get("visible", 0)) > 20, label + " actually draws painted pixels")
   check(int(stats.get("edge_alpha", 255)) == 0, label + " renders completely inside the viewport")
   if id == "shadow_bird":
    check(not bool(actor.get("fly", true)), label + " remains on its ground path")
   scene_samples += 1
 viewport.queue_free()
 await process_frame

func run() -> void:
 var args: PackedStringArray = OS.get_cmdline_user_args()
 if not args.has("--test-mode") or not args.has("--capture"):
  push_error("Run this test with -- --test-mode --capture to isolate normal saves.")
  quit(2)
  return
 if DisplayServer.get_name() == "headless":
  push_error("Expansion asset scene verification requires a real renderer; omit --headless.")
  quit(2)
  return
 var before: Dictionary = save_fingerprint()
 verify_frames()
 await verify_scene()
 check(frames_checked == 768, "all 768 exported frames were inspected")
 check(scene_samples == 64, "all sixteen IDs were processed in four reusable-scene modes")
 check(save_fingerprint() == before, "normal save and its companion files remain unchanged")
 print("EXPANSION_ASSET_TEST checks=", checks, " birds=16 animations=96 frames=", frames_checked, " transparent_frames=", transparent_frames, " clipped_frames=", clipped_frames, " min_visible_pixels=", min_visible_pixels, " min_edge_clearance=", min_edge_clearance, " max_edge_alpha=", max_edge_alpha, " scene_samples=", scene_samples, " failures=", failures)
 quit(1 if failures > 0 else 0)
