extends Node2D
## Re-draw only the original foreground pixels in front of a visitor at the tree base and behind the small flowerpot.
## The source material is shared with WeatherStage, so weather lighting stays identical.
var world: Node2D
var foreground: Sprite2D

func _draw() -> void:
 if not is_instance_valid(world) or not is_instance_valid(foreground) or foreground.texture==null:return
 var texture_size: Vector2=foreground.texture.get_size()
 var ratio: Vector2=texture_size/Vector2(1440,810)
 for actor: Dictionary in world.actors:
  var id: String=str(actor.get("id",""))
  if id not in ["squirrel","jewel_beetle","stag_beetle","ladybug"]:continue
  if (actor["pos"] as Vector2).y<490.0:continue
  var area: Rect2=world._actor_hit_rect(actor).grow(4.0).intersection(Rect2(0,0,1440,810))
  # The ladybug climbs in front of its plant, but emerges from behind the pot rim.
  if id=="ladybug":area=area.intersection(Rect2(0,678,1440,132))
  if area.has_area():draw_texture_rect_region(foreground.texture,area,Rect2(area.position*ratio,area.size*ratio))
