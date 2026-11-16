extends SceneTree
## Native review board: render real articulated birds and real Motion samples.
## Run without --headless (a render device is required), with --capture.
## Each numbered PNG represents exactly 80 ms of the game animation clock.
const Art: Script = preload("res://scripts/visitor_art.gd")
const Expansion: Script = preload("res://scripts/expansion_bird_art.gd")
const Motion: Script = preload("res://scripts/visitor_motion.gd")
const Habitat: Script = preload("res://scripts/habitat_paths.gd")
const State: Script = preload("res://scripts/diary_state.gd")
const CANVAS: Vector2i = Vector2i(1080, 1120)
const FRAME_COUNT: int = 100
const FRAME_STEP: float = 0.08
const ART_FOLDER: String = "res://../docs/bird-expansion-demo"
const FRAME_FOLDER: String = "res://../.work/expansion_showcase_frames"
const TIER_COLORS: Dictionary = {"普通":"829184", "罕见":"698c86", "稀有":"998664", "神秘":"8d819c", "传说":"a18c54"}
var view: SubViewport
var labels_font: SystemFont
var drawings: Array[Node2D] = []
var samples: Array[Array] = []
var failures: int = 0

class PaperBoard extends Node2D:
 func _draw() -> void:
  draw_rect(Rect2(0, 0, 1080, 1120), Color("f3f2e9"))
  draw_line(Vector2(38, 99), Vector2(1042, 99), Color("d8ddd1"), 1.0)
  draw_line(Vector2(38, 1076), Vector2(1042, 1076), Color("d8ddd1"), 1.0)
  # Quiet patches of color provide contrast for the pale and translucent birds.
  for index: int in range(16):
   var center: Vector2 = Vector2(157 + (index % 4) * 255, 213 + int(index / 4) * 238)
   draw_set_transform(center, 0.0, Vector2(1.0, 0.69))
   draw_circle(Vector2.ZERO, 88.0, Color("e5e9df"), true)
  draw_set_transform(Vector2.ZERO)

func _initialize() -> void:
 run.call_deferred()

func text_at(value: String, at: Vector2, extent: Vector2, size: int, color: String, centered: bool = false) -> void:
 var label: Label = Label.new()
 label.text = value
 label.position = at
 label.size = extent
 label.add_theme_font_override("font", labels_font)
 label.add_theme_font_size_override("font_size", size)
 label.add_theme_color_override("font_color", Color(color))
 if centered: label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 view.add_child(label)

func capture_samples(id: String) -> Array:
 var poses: Array = []
 var source: Dictionary = Motion.spawn(id, Habitat.anchor(id, 0), 0)
 var idle_start: float = 0.5
 # These birds naturally travel from branch to tray. Start three seconds before
 # that real transition, then leave every wing/feet/tilt value to Motion.sample.
 if id in ["crow", "clockwork_bird", "twin_bird"]:
  idle_start = 9.0 + float(Expansion.IDS.find(id) % 3) * 1.2 - 3.0
 var first_age: float = float(source.entry_duration) + idle_start
 for frame: int in range(FRAME_COUNT):
  source = Motion.spawn(id, Habitat.anchor(id, 0), 0)
  source.age = first_age + float(frame) * FRAME_STEP
  source.motion_age = source.age
  Motion.sample(source, 0, 1.0)
  # Only remove world travel. The rendering stays at its fixed gallery anchor;
  # breath, squash, joints, flight preparation and wing articulation stay native.
  source.pos = Vector2.ZERO
  source.alpha = 1.0
  source.facing = 1.0
  poses.append(source)
 return poses

func add_character(index: int) -> void:
 var id: String = Expansion.IDS[index]
 var definition: Dictionary = State.ENTRY_DEFS[id]
 var origin: Vector2 = Vector2(40 + index % 4 * 255, 115 + int(index / 4) * 238)
 var art_box: Rect2 = Rect2(origin + Vector2(1, 0), Vector2(232, 178))
 var poses: Array = capture_samples(id)
 var stable_bounds: Rect2 = Art.bounds_for_actor(poses[0])
 for actor: Dictionary in poses:
  stable_bounds = stable_bounds.merge(Art.bounds_for_actor(actor))
 var zoom: float = minf(1.90, minf(art_box.size.x / stable_bounds.size.x, art_box.size.y / stable_bounds.size.y))
 # The broad flight hitbox includes travel clearance, not just painted wings.
 # At a fixed gallery origin these four fit at the same readable body scale.
 if id in ["crow", "clockwork_bird", "twin_bird", "cloud_bird"]: zoom = 1.82
 var painter: Node2D = Art.new()
 painter.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
 painter.position = art_box.get_center() - stable_bounds.get_center() * zoom
 painter.scale = Vector2.ONE * zoom
 painter.actor = poses[0]
 painter.context = {"light":Color.WHITE, "activity":1.0, "alpha":1.0}
 view.add_child(painter)
 drawings.append(painter)
 samples.append(poses)
 text_at(str(definition.name), origin + Vector2(-2, 180), Vector2(238, 32), 22, "46574e", true)
 var tier: String = str(definition.rarity)
 text_at(tier, origin + Vector2(-2, 212), Vector2(238, 23), 14, str(TIER_COLORS[tier]), true)

func run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):
  push_error("Showcase capture requires --capture; no player save is used.")
  quit(2)
  return
 var real_path: String = "user://window_diary_demo_save.json"
 var existed: bool = FileAccess.file_exists(real_path)
 var old_hash: String = FileAccess.get_sha256(real_path) if existed else ""
 var folder: String = ProjectSettings.globalize_path(ART_FOLDER)
 var frames: String = ProjectSettings.globalize_path(FRAME_FOLDER)
 DirAccess.make_dir_recursive_absolute(folder)
 DirAccess.make_dir_recursive_absolute(frames)
 root.title = "Little Elsewhere — New Neighbours Capture"
 view = SubViewport.new()
 view.size = CANVAS
 view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 view.transparent_bg = false
 root.add_child(view)
 labels_font = SystemFont.new()
 labels_font.font_names = PackedStringArray(["Noto Sans SC", "Microsoft YaHei UI", "Microsoft YaHei", "Arial"])
 view.add_child(PaperBoard.new())
 text_at("16位新邻居", Vector2(40, 22), Vector2(650, 49), 36, "3f5347")
 text_at("枝头偶遇 · 轻轻扑棱 · 一点点不合常理", Vector2(42, 70), Vector2(700, 26), 16, "83917f")
 text_at("LITTLE ELSEWHERE", Vector2(770, 43), Vector2(270, 28), 16, "81917d", true)
 for index: int in range(Expansion.IDS.size()): add_character(index)
 text_at("口袋观察站   /   把每一次相遇，轻轻收好", Vector2(40, 1087), Vector2(1000, 24), 14, "87917f", true)
 var fly_between_three_and_five: Dictionary = {}
 for frame: int in range(FRAME_COUNT):
  for index: int in range(drawings.size()):
   drawings[index].actor = samples[index][frame]
   drawings[index].queue_redraw()
   if frame == 0 and str(samples[index][frame].phase) != "idle": failures += 1
   if float(frame) * FRAME_STEP >= 3.0 and float(frame) * FRAME_STEP <= 5.0 and bool(samples[index][frame].fly):
    fly_between_three_and_five[Expansion.IDS[index]] = true
  # Do not wait on frame_post_draw: a minimized native window can withhold it.
  await process_frame
  RenderingServer.force_draw(false)
  var capture: Image = view.get_texture().get_image()
  if capture == null or capture.is_empty() or capture.get_size() != CANVAS:
   failures += 1
   continue
  if capture.save_png(frames.path_join("frame_%03d.png" % frame)) != OK: failures += 1
  if frame == 0 and capture.save_png(folder.path_join("characters.png")) != OK: failures += 1
  if frame % 25 == 0: print("EXPANSION_SHOWCASE frame=", frame, "/", FRAME_COUNT)
 for id: String in ["crow", "clockwork_bird", "twin_bird"]:
  if not fly_between_three_and_five.has(id): failures += 1
 if (not FileAccess.file_exists(real_path) or FileAccess.get_sha256(real_path) != old_hash) if existed else FileAccess.file_exists(real_path): failures += 1
 print("EXPANSION_SHOWCASE size=1080x1120 frames=100 frame_ms=80 species=16 fly_3s_5s=", fly_between_three_and_five.keys(), " failures=", failures)
 print("EXPANSION_SHOWCASE png=", folder.path_join("characters.png"), " frames=", frames)
 quit(1 if failures else 0)
