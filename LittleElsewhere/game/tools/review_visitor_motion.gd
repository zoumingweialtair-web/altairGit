extends SceneTree
## Native visual review of the actual artwork, physical supports and animation states.

var lab: Control

func _initialize() -> void:run.call_deferred()

func run() -> void:
 var id: String="squirrel"
 var folder: String="res://../.work/visitor-motion-review"
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--visitor="):id=arg.trim_prefix("--visitor=")
  if arg.begins_with("--review-dir="):folder=arg.trim_prefix("--review-dir=")
 if not OS.get_cmdline_user_args().has("--capture"):quit(1);return
 folder=ProjectSettings.globalize_path(folder)
 DirAccess.make_dir_recursive_absolute(folder)
 root.size=Vector2i(1440,900)
 root.content_scale_size=Vector2i(1440,900)
 lab=load("res://scenes/creature_lab.tscn").instantiate()
 root.add_child(lab)
 current_scene=lab
 lab.set_process(false)
 lab._select(lab.ids.find(id))
 lab.world.set_weather(0)
 lab.stage.set_weather(0,true)
 lab.weather_picker.select(0)
 lab.world.actors.clear()
 lab.world.trigger(id,false)
 lab.preview_panel.hide()
 var enter: float=lab.world.get_actor_lifecycle_snapshot(id).entry_duration
 var leave: float=lab.world.get_actor_lifecycle_snapshot(id).exit_duration
 var duration: float=lab.world.get_creature_duration(id)
 var entry_frames: int=ceili(enter*10.0)
 var idle_frames: int=40
 var exit_frames: int=ceili(leave*10.0)
 for frame: int in range(entry_frames+idle_frames+exit_frames):
  if frame<entry_frames:lab.world.seek_actor_phase(id,"entry",float(frame)/entry_frames)
  elif frame<entry_frames+idle_frames:lab.world.seek_actor_phase(id,"idle",float(frame-entry_frames)/10.0/(duration-enter-leave))
  else:lab.world.seek_actor_phase(id,"exit",float(frame-entry_frames-idle_frames)/exit_frames)
  lab.world._refresh_visitor_occlusion()
  lab._refresh()
  lab.stage._process(0.1)
  await RenderingServer.frame_post_draw
  var full: Image=root.get_texture().get_image()
  var crop: Image=full.get_region(Rect2i(25,140,670,630)) if id=="squirrel" else full.get_region(Rect2i(0,0,1440,810))
  if id!="squirrel":crop.resize(900,506,Image.INTERPOLATE_LANCZOS)
  crop.save_png(folder.path_join("frame_%04d.png" % frame))
  if frame in [int(entry_frames*0.25),int(entry_frames*0.55),entry_frames+10,entry_frames+idle_frames+int(exit_frames*0.45)]:
   full.save_png(folder.path_join("scene_%04d.png" % frame))
 print("VISITOR_REVIEW ",id," frames=",entry_frames+idle_frames+exit_frames," path=",folder)
 quit()
