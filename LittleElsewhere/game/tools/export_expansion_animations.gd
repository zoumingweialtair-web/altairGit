extends SceneTree
## Bake the live articulated renderer into portable AnimatedSprite2D resources.
const Art=preload("res://scripts/visitor_art.gd")
const Expansion=preload("res://scripts/expansion_bird_art.gd")
const Motion=preload("res://scripts/visitor_motion.gd")
const MODES: Array[String]=["idle","fly","feed","special","land","takeoff"]
const SIZE: int=192
const ZOOM: float=0.72
const COUNT: int=8
var failures: int=0
func _initialize() -> void:run.call_deferred()
func run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):
  quit(2)
  return
 var folder: String="res://assets/creatures/expansion/animations"
 DirAccess.make_dir_recursive_absolute(folder)
 var view: SubViewport=SubViewport.new()
 view.size=Vector2i(SIZE,SIZE)
 view.transparent_bg=true
 view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(view)
 var painter: Node2D=Art.new()
 painter.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
 painter.position=Vector2.ONE*SIZE*0.5
 painter.scale=Vector2.ONE*ZOOM
 painter.context={"light":Color.WHITE,"activity":1.0,"alpha":1.0}
 view.add_child(painter)
 for id: String in Expansion.IDS:
  var sheet: Image=Image.create(SIZE*COUNT,SIZE*MODES.size(),false,Image.FORMAT_RGBA8)
  var frames: SpriteFrames=SpriteFrames.new()
  frames.remove_animation("default")
  var source: Dictionary=Motion.spawn(id,Vector2.ZERO,0)
  var enter: float=float(source["entry_duration"])
  var leave: float=float(source["exit_duration"])
  var duration: float=float(source["duration"])
  var best_feed: float=enter+2.0
  var best_amount: float=-1.0
  for n: int in 180:
   source["age"]=enter+(duration-enter-leave)*float(n)/180.0
   source["motion_age"]=source["age"]
   Motion.sample(source,0,1.0)
   if float(source.get("feed_blend",0.0))>best_amount:
    best_amount=float(source.get("feed_blend",0.0))
    best_feed=float(source["age"])
  for row: int in MODES.size():
   var mode: String=MODES[row]
   frames.add_animation(mode)
   frames.set_animation_speed(mode,8.0 if mode in ["fly","land","takeoff"] else 4.0)
   frames.set_animation_loop(mode,mode not in ["land","takeoff"])
   for frame: int in COUNT:
    var phase: float=float(frame)/COUNT
    var age: float=enter+0.5+phase*2.0
    match mode:
     "fly":age=enter*0.35+phase*0.65
     "feed":age=best_feed-0.6+phase*1.2
     "special":age=enter+(duration-enter-leave)*phase
     "land":age=enter*lerpf(0.73,0.999,float(frame)/(COUNT-1))
     "takeoff":age=duration-leave+leave*phase*0.30
    source=Motion.spawn(id,Vector2.ZERO,0)
    source["age"]=age
    source["motion_age"]=age
    Motion.sample(source,0,1.0)
    source["pos"]=Vector2.ZERO
    source["alpha"]=1.0
    source["facing"]=1.0
    painter.actor=source
    painter.queue_redraw()
    await process_frame
    RenderingServer.force_draw(false)
    var capture: Image=view.get_texture().get_image()
    if capture==null or capture.is_empty():
     failures+=1
     continue
    sheet.blit_rect(capture,Rect2i(0,0,SIZE,SIZE),Vector2i(frame*SIZE,row*SIZE))
  var image_path: String=folder.path_join(id+".png")
  if sheet.save_png(image_path)!=OK:failures+=1
  # Use an external image path so SpriteFrames stays small and reimportable.
  var sheet_texture: ImageTexture=ImageTexture.create_from_image(sheet)
  sheet_texture.take_over_path(image_path)
  for row: int in MODES.size():
   for frame: int in COUNT:
    var atlas: AtlasTexture=AtlasTexture.new()
    atlas.atlas=sheet_texture
    atlas.region=Rect2(frame*SIZE,row*SIZE,SIZE,SIZE)
    frames.add_frame(MODES[row],atlas)
  if ResourceSaver.save(frames,folder.path_join(id+".tres"))!=OK:failures+=1
  print("EXPANSION_ANIMATION ",id," frames=48")
 print("EXPANSION_ANIMATION_EXPORT birds=16 frames=768 failures=",failures)
 quit(1 if failures else 0)
