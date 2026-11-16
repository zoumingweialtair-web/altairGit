@tool
extends Node2D
## Reusable painted bird. Position is its foot contact. Routes belong to WindowScene.
const Art=preload("res://scripts/visitor_art.gd")
const Expansion=preload("res://scripts/expansion_bird_art.gd")
const Motion=preload("res://scripts/visitor_motion.gd")
@export_enum("pigeon","crow","cockatiel","dough_bird","dandelion_bird","paper_bird","cloud_bird","yarn_bird","clockwork_bird","alien_bird","twin_bird","invisible_bird","shadow_bird","inverted_bird","galaxy_bird","crescent_bird") var bird_id: String="pigeon"
@export_enum("idle","fly","feed","lifecycle") var animation: String="idle"
@export_range(0.0,3.0,0.1) var playback_speed: float=1.0
var clock_time: float=0.0
var actor: Dictionary={}
func _process(delta: float) -> void:
 clock_time+=delta*playback_speed
 if bird_id not in Expansion.IDS:return
 actor=Motion.spawn(bird_id,Vector2.ZERO,0)
 var enter: float=float(actor["entry_duration"])
 var leave: float=float(actor["exit_duration"])
 var total: float=float(actor["duration"])
 actor["age"]=fposmod(clock_time,total) if animation=="lifecycle" else enter+fposmod(clock_time,total-enter-leave)
 actor["motion_age"]=clock_time
 Motion.sample(actor,0,1.0)
 actor["pos"]=Vector2.ZERO
 actor["alpha"]=1.0
 if animation=="fly" and bird_id!="shadow_bird":
  actor["fly"]=true
  actor["perch_blend"]=0.0
  actor["feet_reach"]=0.0
  actor["wing_phase"]=fposmod(clock_time*5.0,1.0)
  actor["flight_mode"]="flap"
  actor["invert_blend"]=0.0
 elif animation=="feed":
  actor["feed_blend"]=0.5+sin(clock_time*3.0)*0.5
  actor["fly"]=false
  actor["perch_blend"]=1.0
  actor["seed_visible"]=true
 queue_redraw()
func _draw() -> void:
 if actor.is_empty():actor=Art.portrait_actor(bird_id)
 Art.draw_actor(self,actor,{"light":Color.WHITE,"alpha":1.0,"activity":1.0})
