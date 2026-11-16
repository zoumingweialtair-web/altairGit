extends SceneTree
## Compare actual native scene pixels, so a hidden flag alone cannot pass this check.
var failures: int=0
var checks: int=0
func _initialize() -> void:run.call_deferred()
func run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):quit(1);return
 root.size=Vector2i(1440,900)
 root.content_scale_size=Vector2i(1440,900)
 var lab=load("res://scenes/creature_lab.tscn").instantiate()
 root.add_child(lab)
 current_scene=lab
 lab.set_process(false)
 lab.stage.set_process(false)
 lab.stage.set_weather(0,true)
 lab.world.set_weather(0)
 lab.preview_panel.hide()
 lab.world.actors.clear()
 lab.world.queue_redraw()
 lab.world._refresh_visitor_occlusion()
 await RenderingServer.frame_post_draw
 var baseline: Image=root.get_texture().get_image()
 for id: String in ["squirrel","jewel_beetle","stag_beetle","ladybug"]:
  for phase: String in ["entry","idle","exit"]:
   lab.world.actors.clear()
   lab.world.trigger(id,false)
   lab.world.seek_actor_phase(id,phase,0.0 if phase=="entry" else (0.25 if phase=="idle" else 0.9999))
   lab.world.actors[0]["alpha"]=0.0
   lab.world.queue_redraw()
   lab.world._refresh_visitor_occlusion()
   await RenderingServer.frame_post_draw
   baseline=root.get_texture().get_image()
   lab.world.actors[0]["alpha"]=1.0
   lab.world.queue_redraw()
   await RenderingServer.frame_post_draw
   var shot: Image=root.get_texture().get_image()
   var changed: int=0
   for y: int in range(140,810):
    for x: int in range(25,500):
     var a: Color=baseline.get_pixel(x,y)
     var b: Color=shot.get_pixel(x,y)
     if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.04:changed+=1
   var ok: bool=changed>60 if phase=="idle" else changed<12
   checks+=1
   if not ok:failures+=1;push_error("OCCLUSION_FAIL "+id+" "+phase+" visible_pixels="+str(changed))
   print("OCCLUSION ",id," ",phase," pixels=",changed)
   if id in ["ladybug","squirrel"]:shot.save_png(ProjectSettings.globalize_path("res://../.work/"+id+"-"+phase+".png"))
 print("HABITAT_OCCLUSION_TEST checks=",checks," failures=",failures)
 quit(1 if failures else 0)
