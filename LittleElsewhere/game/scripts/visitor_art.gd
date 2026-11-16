extends Node2D
## One detailed visitor renderer shared by the live window, field guide and previews.
const Birds=preload("res://scripts/bird_art.gd")
const Creatures=preload("res://scripts/creature_art.gd")
const BIRD_IDS: Array[String]=["sparrow","tit","robin","woodpecker","owl","kingfisher","swallow","magpie","white_eye","egret"]
const OTHER_IDS: Array[String]=["squirrel","hedgehog","cat","bat","butterfly","luna_moth","jewel_beetle","fireflies","dragonfly","ladybug","stag_beetle"]
var actor: Dictionary={}
var context: Dictionary={}

static func is_creature(id: String) -> bool:
 return id in BIRD_IDS or id in OTHER_IDS

static func bounds(id: String, flying: bool=false) -> Rect2:
 return Birds.bounds(id,flying) if id in BIRD_IDS else Creatures.bounds(id,flying)

static func bounds_for_actor(data: Dictionary) -> Rect2:
 var id: String=str(data.get("id",""))
 return Birds.bounds(id,bool(data.get("fly",false))) if id in BIRD_IDS else Creatures.bounds_for_actor(data)

static func draw_actor(canvas: Node2D, data: Dictionary, environment: Dictionary={}) -> void:
 if data.is_empty():return
 if str(data.get("id","")) in BIRD_IDS:Birds.draw_bird(canvas,data,environment)
 else:Creatures.draw_creature(canvas,data,environment)

static func portrait_actor(id: String, clock: float=0.0) -> Dictionary:
 var fly: bool=id in ["swallow","bat","butterfly","luna_moth","fireflies","dragonfly"]
 var poses: Dictionary={"squirrel":"nibble","cat":"sit","hedgehog":"sniff","owl":"watch","woodpecker":"listen","jewel_beetle":"crawl","ladybug":"crawl","stag_beetle":"crawl","egret":"wade"}
 return {"id":id,"pos":Vector2.ZERO,"age":clock+12.0,"motion_age":clock,"idle_age":clock,
  "phase":"idle","phase_progress":0.4,"fly":fly,"facing":1.0,"alpha":1.0,
  "pose":"cruise" if fly else poses.get(id,"perch"),"flight_mode":"cruise" if fly else "perched",
  "land_blend":0.0 if fly else 1.0,"wing_phase":fposmod(clock*7.5,1.0),"wing_strength":0.8 if fly else 0.0,"wing_power":0.8 if fly else 0.0,"perch_blend":0.0 if fly else 1.0,
  "tail_spread":0.1,"feet_reach":0.0 if fly else 1.0,"body_tilt":0.0,"route_angle":-PI*0.5,"support":"branch"}

func _draw() -> void:
 draw_actor(self,actor,context)
