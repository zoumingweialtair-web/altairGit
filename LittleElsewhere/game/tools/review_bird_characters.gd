extends SceneTree
## Native character review. --capture is mandatory; no player progress is loaded.
const Art=preload("res://scripts/bird_art.gd")
const Bird=preload("res://scripts/bird_art_preview.gd")
const NAMES: Array[String]=["麻雀","山雀","知更鸟","啄木鸟","林鸮","翠鸟","燕子","喜鹊","绣眼鸟","白鹭"]
const NOTES: Array[String]=["认真等饭中","小小黑领结","红肚皮发呆王","敲门不打招呼","我醒着，我没动","蓝色小饭团","两片海苔尾巴","长尾巴巡逻员","戴眼镜的团子","脖子比脑子忙"]
var previews: Array[Node2D]=[]
var labels_font: SystemFont
var folder: String="res://../.work/goofy-birds"
var animate: bool=false
var frame_count: int=48
var failures: int=0

func _initialize() -> void:run.call_deferred()

func text_at(value: String,at: Vector2,extent: Vector2,font_size: int,color: String="47584f",centered: bool=false) -> void:
 var label: Label=Label.new()
 label.text=value
 label.position=at
 label.size=extent
 label.add_theme_font_override("font",labels_font)
 label.add_theme_font_size_override("font_size",font_size)
 label.add_theme_color_override("font_color",Color(color))
 if centered:label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 root.add_child(label)

func plate(rect: Rect2,color: String,border: String="") -> void:
 var panel: Panel=Panel.new()
 panel.position=rect.position
 panel.size=rect.size
 var style: StyleBoxFlat=StyleBoxFlat.new()
 style.bg_color=Color(color)
 style.set_corner_radius_all(14)
 if not border.is_empty():
  style.border_color=Color(border)
  style.set_border_width_all(1)
 panel.add_theme_stylebox_override("panel",style)
 root.add_child(panel)

func add_bird(id: String,box: Rect2,flight: bool=false,native: bool=false,index: int=0) -> void:
 var node: Node2D=Bird.new()
 var bounds: Rect2=Art.bounds(id,flight)
 var fit: float=minf(box.size.x/bounds.size.x,box.size.y/bounds.size.y)
 var zoom: float=minf(1.0,fit) if native else fit
 node.set_meta("review_box",box)
 node.scale=Vector2.ONE*zoom
 node.position=box.get_center()-bounds.get_center()*zoom
 node.actor={"id":id,"pos":Vector2.ZERO,"facing":1.0,"motion_age":1.3+index*0.17,"age":12.0,"idle_age":1.3,"phase":"idle","pose":"watch" if id=="owl" else ("listen" if id=="woodpecker" else "perch"),"fly":flight,"flight_mode":"flap" if flight else "perch","wing_phase":0.11+0.06*(index%3),"wing_power":0.8 if flight else 0.0,"perch_blend":0.0 if flight else 1.0,"land_blend":0.0 if flight else 1.0,"feet_reach":0.0 if flight else 1.0,"tail_spread":0.1,"turn_scale":1.0,"body_tilt":0.0}
 node.context={"light":Color.WHITE,"alpha":1.0,"activity":1.0}
 root.add_child(node)
 previews.append(node)

func run() -> void:
 if not OS.get_cmdline_user_args().has("--capture"):
  push_error("Character review requires --capture")
  quit(1)
  return
 for arg: String in OS.get_cmdline_user_args():
  if arg.begins_with("--bird-review-dir="):folder=arg.trim_prefix("--bird-review-dir=")
  if arg=="--bird-review-frames":animate=true
 folder=ProjectSettings.globalize_path(folder)
 DirAccess.make_dir_recursive_absolute(folder)
 root.size=Vector2i(1440,900)
 root.content_scale_size=Vector2i(1440,900)
 labels_font=SystemFont.new()
 labels_font.font_names=PackedStringArray(["Microsoft YaHei UI","Microsoft YaHei","Arial"])
 var bg: ColorRect=ColorRect.new()
 bg.size=Vector2(1440,900)
 bg.color=Color("f4efe2")
 root.add_child(bg)
 text_at("十位有点呆的邻居",Vector2(38,18),Vector2(850,48),32,"3e5147")
 text_at("LITTLE ELSEWHERE  /  BIRD CLUB",Vector2(1030,34),Vector2(370,24),14,"87917b",true)
 text_at("豆豆眼 · 软乎乎的身体 · 一本正经的小动作",Vector2(41,67),Vector2(1000,26),17,"7a8570")
 for index: int in range(Art.IDS.size()):
  var id: String=Art.IDS[index]
  var origin: Vector2=Vector2(30+(index%5)*280,115+int(index/5)*365)
  plate(Rect2(origin,Vector2(264,348)),"fbf8ee","dddcc9")
  text_at(NAMES[index],origin+Vector2(17,12),Vector2(230,34),22)
  text_at(NOTES[index],origin+Vector2(17,45),Vector2(230,24),13,"8b917e")
  plate(Rect2(origin+Vector2(16,78),Vector2(232,170)),"e8ecdc")
  add_bird(id,Rect2(origin+Vector2(37,90),Vector2(190,146)),false,false,index)
  text_at("小尺寸预览",origin+Vector2(18,256),Vector2(108,20),12,"8b917e",true)
  text_at("扑棱一下",origin+Vector2(140,256),Vector2(106,20),12,"8b917e",true)
  add_bird(id,Rect2(origin+Vector2(22,282),Vector2(102,56)),false,true,index)
  add_bird(id,Rect2(origin+Vector2(136,278),Vector2(112,62)),true,false,index)
 text_at("原生 Godot 角色预览 · 场景、飞行动作与图鉴共用形象",Vector2(35,860),Vector2(1350,26),14,"8c957f",true)
 await RenderingServer.frame_post_draw
 var image: Image=root.get_texture().get_image()
 if image.save_png(folder.path_join("characters.png"))!=OK:failures+=1
 # Enlarged flight pose makes wing intersections visible; tiny HUD examples cannot do that.
 var restore: Array[Dictionary]=[]
 for index: int in range(0,previews.size(),3):
  var node: Node2D=previews[index]
  restore.append({"actor":node.actor.duplicate(true),"position":node.position,"scale":node.scale})
  var box: Rect2=node.get_meta("review_box")
  var bounds: Rect2=Art.bounds(str(node.actor.id),true)
  var zoom: float=minf(box.size.x/bounds.size.x,box.size.y/bounds.size.y)
  node.scale=Vector2.ONE*zoom
  node.position=box.get_center()-bounds.get_center()*zoom
  node.actor.fly=true
  node.actor.flight_mode="flap"
  node.actor.wing_phase=0.22
  node.actor.wing_power=0.85
  node.actor.perch_blend=0.0
  node.actor.land_blend=0.0
  node.actor.feet_reach=0.0
  node.queue_redraw()
 await RenderingServer.frame_post_draw
 if root.get_texture().get_image().save_png(folder.path_join("flight.png"))!=OK:failures+=1
 for index: int in range(0,previews.size(),3):
  var node: Node2D=previews[index]
  var original: Dictionary=restore[index/3]
  node.actor=original.actor
  node.position=original.position
  node.scale=original.scale
  node.queue_redraw()
 if animate:
  var frames_folder: String=folder.path_join("frames")
  DirAccess.make_dir_recursive_absolute(frames_folder)
  for frame: int in range(frame_count):
   for index: int in range(previews.size()):
    var node: Node2D=previews[index]
    node.actor.motion_age=float(frame)/8.0+float(index/3)*0.17
    node.actor.idle_age=node.actor.motion_age
    node.actor.wing_phase=fposmod(float(frame)/8.0*2.0+float(index)*0.03,1.0)
    node.queue_redraw()
   await RenderingServer.frame_post_draw
   var frame_image: Image=root.get_texture().get_image()
   frame_image.resize(960,600,Image.INTERPOLATE_LANCZOS)
   if frame_image.save_png(frames_folder.path_join("frame_%03d.png" % frame))!=OK:failures+=1
 print("BIRD_CHARACTER_REVIEW species=10 poses=30 frames=",frame_count if animate else 1," failures=",failures," path=",folder)
 quit(1 if failures else 0)
