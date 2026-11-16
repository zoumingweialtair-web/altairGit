extends Node2D
const Art=preload("res://scripts/bird_art.gd")
var actor: Dictionary={"id":"sparrow","pos":Vector2.ZERO,"facing":1.0,"phase":"idle","fly":false,"motion_age":0.0,"pose":"perch"}
var context: Dictionary={}
func _draw() -> void:
 Art.draw_bird(self,actor,context)
