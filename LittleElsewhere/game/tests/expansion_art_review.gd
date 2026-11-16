extends SceneTree
const Art = preload("res://scripts/expansion_bird_art.gd")
class Bird:
 extends Node2D
 var actor: Dictionary
 func _draw() -> void:
  Art.draw_bird(self, actor)
class Board:
 extends Node2D
 var font: Font = ThemeDB.fallback_font
 func _draw() -> void:
  draw_rect(Rect2(0,0,1600,1120), Color("edf0e5"))
  for index: int in Art.IDS.size():
   var x: float = (index % 4) * 400.0
   var y: float = (index / 4) * 280.0
   draw_style_box(_panel(), Rect2(x+12,y+12,376,256))
   draw_string(font, Vector2(x+28,y+42), Art.IDS[index].replace("_", " "), HORIZONTAL_ALIGNMENT_LEFT, 340, 22, Color("40534d"))
 func _panel() -> StyleBoxFlat:
  var style: StyleBoxFlat = StyleBoxFlat.new()
  style.bg_color = Color("fafbf4")
  style.set_corner_radius_all(14)
  return style
func _initialize() -> void:
 call_deferred("_run")
func _run() -> void:
 var flight_review: bool = "--art-flight" in OS.get_cmdline_user_args()
 root.size = Vector2i(1600,1120)
 var viewport: SubViewport = SubViewport.new()
 viewport.size = Vector2i(1600,1120)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var board: Board = Board.new()
 viewport.add_child(board)
 for index: int in Art.IDS.size():
  var id: String = Art.IDS[index]
  var bird: Bird = Bird.new()
  bird.actor = {"id":id,"motion_age":2.6,"fly":false,"facing":1.0,"perch_blend":1.0,"feet_reach":1.0,"wing_phase":0.3,"special_phase":0.45,"seed_visible":true,"head_disagreement":0.35,"orbit_phase":0.3,"antenna_scan":0.7,"invert_blend":1.0 if id == "inverted_bird" else 0.0}
  if flight_review and id != "shadow_bird":
   bird.actor.merge({"fly":true,"perch_blend":0.0,"feet_reach":0.15,"wing_phase":0.12,"invert_blend":0.0,"body_tilt":-0.08,"flight_mode":"flap"},true)
  bird.actor["pos"] = Vector2(17,-11)
  bird.scale = Vector2.ONE * 2.55
  var center: Vector2 = Vector2((index % 4)*400 + 200, (index / 4)*280 + 166)
  bird.position = center - (Art.bounds_for_actor(bird.actor).get_center() + bird.actor["pos"]) * bird.scale
  board.add_child(bird)
 await process_frame
 await process_frame
 RenderingServer.force_draw(false)
 var output: String = ProjectSettings.globalize_path("res://../.work/expansion_art_flight_review.png" if flight_review else "res://../.work/expansion_art_review.png")
 var frame: Image = viewport.get_texture().get_image()
 frame.save_png(output)
 print("ART_REVIEW_SAVED ", output)
 print(Art.asset_snapshot())
 quit()
