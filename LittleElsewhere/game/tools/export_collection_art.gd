extends SceneTree
## Deterministic native asset export. Use --capture to keep the player save untouched.
const Art=preload("res://scripts/visitor_art.gd")
const StateData=preload("res://scripts/diary_state.gd")
const StageScene=preload("res://scenes/weather_stage.tscn")
const WorldScript=preload("res://scripts/window_scene.gd")
var failures: int=0

func _initialize() -> void:run.call_deferred()

func run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):
  push_error("Asset export requires --capture")
  quit(1)
  return
 root.size=Vector2i(1440,810)
 root.content_scale_size=Vector2i(1440,810)
 var portrait_dir: String="res://assets/creatures/v2/portraits"
 var scene_dir: String="res://assets/collection/v2"
 DirAccess.make_dir_recursive_absolute(portrait_dir)
 DirAccess.make_dir_recursive_absolute(scene_dir)
 var view: SubViewport=SubViewport.new()
 view.size=Vector2i(192,160)
 view.transparent_bg=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var portrait: Node2D=Art.new()
 view.add_child(portrait)
 var visitor_ids: Array[String]=Art.Expansion.IDS if OS.get_cmdline_user_args().has("--expansion-only") else Art.BIRD_IDS+Art.OTHER_IDS
 for id: String in visitor_ids:
  portrait.actor=Art.portrait_actor(id,1.2)
  portrait.context={"light":Color.WHITE,"alpha":1.0,"activity":1.0}
  var area: Rect2=Art.bounds_for_actor(portrait.actor)
  var zoom: float=minf(176.0/area.size.x,144.0/area.size.y)
  portrait.scale=Vector2.ONE*zoom
  portrait.position=Vector2(96,80)-area.get_center()*zoom
  portrait.queue_redraw()
  await process_frame
  RenderingServer.force_draw(false)
  if view.get_texture().get_image().save_png(portrait_dir.path_join(id+".png"))!=OK:failures+=1
 root.remove_child(view)
 view.queue_free()
 if OS.get_cmdline_user_args().has("--expansion-only"):
  print("COLLECTION_ART exported ",visitor_ids.size()," new portraits; failures=",failures)
  quit(1 if failures else 0)
  return
 var scene: Node2D=Node2D.new()
 root.add_child(scene)
 var stage: Node2D=StageScene.instantiate()
 stage.name="WeatherStage"
 scene.add_child(stage)
 var world: Node2D=WorldScript.new()
 world.name="World"
 scene.add_child(world)
 stage.set_process(false)
 world.set_process(false)
 world.set_layered_weather_enabled(true)
 world.set_painted_atmospheres(stage.get_painted_atmosphere_ids())
 var shot_count: int=0
 for id: String in StateData.ENTRY_DEFS:
  var definition: Dictionary=StateData.ENTRY_DEFS[id]
  if str(definition.get("category","")) not in ["scenery","wonders"]:continue
  world.actors.clear()
  world.spectacles.clear()
  world.quiet=false
  var weather_id: int=int(definition.get("weather_ids",[0])[0])
  stage.set_atmosphere_state({})
  stage.set_weather(weather_id,true)
  world.set_weather(weather_id)
  for i: int in range(8):world.weather_weights[i]=1.0 if i==weather_id else 0.0
  var age: float=12.0
  if id in ["ufo","meteor","supernova"]:age={"ufo":5.5,"meteor":2.2,"supernova":8.0}[id]
  if not id.begins_with("scene_"):
   world.trigger(id,false)
   for event: Dictionary in world.spectacles:
    event["age"]=age
    event["motion_age"]=age
  world.clock_time=8.0
  world._update_atmosphere_tint(3.0)
  stage.set_atmosphere_state(world.get_atmosphere_state())
  stage._process(3.0)
  world.queue_redraw()
  await process_frame
  RenderingServer.force_draw(false)
  var shot: Image=root.get_texture().get_image()
  if id in ["ufo","meteor","supernova"]:
   shot=shot.get_region(Rect2i(660,25,680,382))
  shot.resize(480,270,Image.INTERPOLATE_LANCZOS)
  if shot.save_png(scene_dir.path_join(id+".png"))!=OK:failures+=1
  shot_count+=1
 print("COLLECTION_ART exported %d transparent creature portraits + " % (Art.BIRD_IDS.size()+Art.OTHER_IDS.size()),shot_count," scene postcards; failures=",failures)
 quit(1 if failures else 0)
