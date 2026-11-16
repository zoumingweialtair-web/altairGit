extends SceneTree
const Art=preload("res://scripts/bird_art.gd")
const Preview=preload("res://scripts/bird_art_preview.gd")
var previews: Array[Node2D]=[]
var output: String="res://../.work/refined-birds/contact-sheet.png"
var frame_dir: String=""
func _initialize() -> void: run.call_deferred()
func run() -> void:
 root.size=Vector2i(1600,1120)
 root.content_scale_size=Vector2i(1600,1120)
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--bird-sheet="):output=arg.trim_prefix("--bird-sheet=")
  if arg.begins_with("--bird-frames="):frame_dir=arg.trim_prefix("--bird-frames=")
 var bg: ColorRect=ColorRect.new()
 bg.size=Vector2(1600,1120)
 bg.color=Color("e9e7d8")
 root.add_child(bg)
 for row: int in range(4):
  for column: int in range(5):
   var index: int=row%2*5+column
   var id: String=Art.IDS[index]
   var preview: Node2D=Preview.new()
   preview.position=Vector2(170+column*320,211+row*272)
   preview.scale=Vector2.ONE*(1.85 if row<2 else 1.55)
   preview.actor={"id":id,"pos":Vector2.ZERO,"facing":1.0,"motion_age":1.7+index*.23,"fly":row>1,"phase":"idle" if row<2 else "entry","pose":"perch","flight_mode":"perch" if row<2 else "flap","perch_blend":1.0 if row<2 else 0.0,"wing_phase":.1+index*.02,"feet_reach":1.0 if row<2 else 0.0}
   root.add_child(preview)
   previews.append(preview)
   var label: Label=Label.new()
   label.text=id+"  /  "+("perched" if row<2 else "flight")
   label.position=Vector2(24+column*320,16+row*272)
   label.add_theme_font_size_override("font_size",20)
   label.add_theme_color_override("font_color",Color("34463f"))
   root.add_child(label)
 await RenderingServer.frame_post_draw
 var result: Error=root.get_texture().get_image().save_png(output)
 if result!=OK:push_error("Bird contact sheet not saved")
 var frames: int=64
 if not frame_dir.is_empty():DirAccess.make_dir_recursive_absolute(frame_dir)
 for frame: int in range(frames):
  for n: int in range(previews.size()):
   var preview: Node2D=previews[n]
   preview.actor.motion_age=float(frame)*.071
   if n>=10:preview.actor.wing_phase=float(frame%32)/32.0
   preview.queue_redraw()
  await RenderingServer.frame_post_draw
  if not frame_dir.is_empty() and frame<32:
   root.get_texture().get_image().save_png(frame_dir.path_join("frame-%02d.png" % frame))
 print("BIRD_ART_RENDER_OK species=10 poses=20 frames=64")
 quit(0 if result==OK else 1)
