extends SceneTree
const Art=preload("res://scripts/creature_art.gd")
class ArtView extends Node2D:
 var actor: Dictionary={}
 func _draw() -> void:
  Art.draw_creature(self,actor,{})
var views: Array=[]
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1600,1000)
 root.content_scale_size=Vector2i(1600,1000)
 var bg: ColorRect=ColorRect.new()
 bg.color=Color("eeeadb")
 bg.size=Vector2(1600,1000)
 root.add_child(bg)
 var ids: Array=Art.IDS.duplicate()
 ids.append("squirrel")
 for i: int in range(ids.size()):
  var card: ColorRect=ColorRect.new()
  card.position=Vector2(12+i%4*397,18+i/4*328)
  card.size=Vector2(382,308)
  card.color=Color("f8f3e6")
  root.add_child(card)
  var view: ArtView=ArtView.new()
  view.position=card.position+Vector2(210,244)
  view.scale=Vector2(2.2,2.2)
  view.actor={"id":ids[i],"pos":Vector2.ZERO,"phase":"idle","pose":"nibble" if ids[i]=="squirrel" else "sit","motion_age":1.3,"facing":1.0,"alpha":1.0}
  if i==11:
   view.actor.pose="climb"
   view.actor.route_angle=-PI/2
   view.position.y=card.position.y+90
   view.scale=Vector2(1.8,1.8)
  if ids[i] in ["butterfly","luna_moth","bat","dragonfly","fireflies"]:view.actor.fly=true
  var art_bounds: Rect2=Art.bounds_for_actor(view.actor)
  var fit: float=minf(2.4,minf(340.0/art_bounds.size.x,228.0/art_bounds.size.y))
  view.scale=Vector2(fit,fit)
  view.position=card.position+Vector2(191,184)-art_bounds.get_center()*fit
  root.add_child(view)
  views.append(view)
  var label: Label=Label.new()
  label.position=card.position+Vector2(18,16)
  label.text=str(ids[i])+(" / climb" if i==11 else " / refined art")
  label.add_theme_color_override("font_color",Color("435348"))
  label.add_theme_font_size_override("font_size",22)
  root.add_child(label)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://../.work/creatures-v2/creatures-refined.png")
 var checks: int=0
 for phase: String in ["entry","idle","exit"]:
  for frame: int in range(64):
   for view: ArtView in views:
    view.actor.phase=phase
    view.actor.motion_age=frame*0.13
    view.actor.pose="climb" if view.actor.id=="squirrel" and phase!="idle" else ("nibble" if view.actor.id=="squirrel" else ("walk" if view.actor.id=="cat" and phase!="idle" else "sit"))
    view.actor.perch_blend=frame/63.0 if view.actor.id=="squirrel" else 0.0
    if view.actor.id in ["jewel_beetle","ladybug","stag_beetle"]:
     view.actor.pose="crawl"
     view.actor.phase_progress=frame/63.0
     view.actor.route_angle=(PI/2.0 if phase=="exit" else -PI/2.0)+sin(frame*0.07)*0.24
     view.actor.gait_phase=fposmod(frame*0.1,1.0)
    view.queue_redraw()
    checks+=1
   await RenderingServer.frame_post_draw
 print("CREATURE_ART native draws=",checks)
 quit()
