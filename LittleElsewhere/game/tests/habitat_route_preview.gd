extends SceneTree
const Habitat=preload("res://scripts/habitat_paths.gd")
class RouteOverlay extends Node2D:
 func _draw() -> void:
  var colors: Dictionary={"squirrel":Color("fff3aa"),"jewel_beetle":Color("79e8e1"),"stag_beetle":Color("ffb88a"),"ladybug":Color("ff8b9c")}
  for id: String in colors:
   var path: PackedVector2Array=Habitat.crawl_path(id)
   var trace: PackedVector2Array=[]
   for frame: int in range(121):trace.append(Habitat.sample_path(path,float(frame)/120.0).position)
   draw_polyline(trace,Color(0.1,0.15,0.1,0.8),5.0,true)
   draw_polyline(trace,colors[id],2.0,true)
   for point in path:draw_circle(point,3.0,colors[id])
   draw_circle(Habitat.anchor(id),7.0,colors[id],false,2.0)
  for id: String in ["sparrow","tit","robin","woodpecker","owl","kingfisher","magpie","white_eye"]:
   var pos: Vector2=Habitat.anchor(id)
   draw_line(pos+Vector2(-8,0),pos+Vector2(8,0),Color("faf6e8"),2.0)
   draw_line(pos+Vector2(0,-8),pos+Vector2(0,8),Color("faf6e8"),2.0)
func _initialize() -> void:run.call_deferred()
func run() -> void:
 root.size=Vector2i(1440,810)
 root.content_scale_size=Vector2i(1440,810)
 var scene: Node=load("res://scenes/weather_stage.tscn").instantiate()
 root.add_child(scene)
 root.add_child(RouteOverlay.new())
 await create_timer(0.8).timeout
 await RenderingServer.frame_post_draw
 var path: String=ProjectSettings.globalize_path("res://../.work/creatures-v2/habitat-routes.png")
 DirAccess.make_dir_recursive_absolute(path.get_base_dir())
 root.get_texture().get_image().save_png(path)
 print("HABITAT_PREVIEW ",path)
 quit()
