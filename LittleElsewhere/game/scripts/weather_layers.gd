@tool
extends Node2D
## Small independent atmospheric layers. All positions remain in the 1440x810 view.
@export_enum("stars","clouds","precipitation") var role: String = "stars"
var clock: float = 0.0
var environment: Dictionary = {}
var cloud_texture: Texture2D
var quiet: bool = false

func _ready() -> void:
    set_process(false)

func set_environment(value: Dictionary,soft: bool=false) -> void:
    environment=value
    quiet=soft
    queue_redraw()

func advance(delta: float) -> void:
    clock+=delta*(0.55 if quiet else 1.0)
    queue_redraw()

func get_cloud_positions() -> Array[Vector2]:
    var result: Array[Vector2]=[]
    for i in range(5):
        var x: float=fposmod(-180+i*361+clock*(3.0+i*0.7),1900.0)-320.0
        result.append(Vector2(x,62+(i*47)%170))
    return result

func get_particle_positions() -> Array[Vector2]:
    var result: Array[Vector2]=[]
    var rain: float=float(environment.get("rain",0.0))
    var snow: float=float(environment.get("snow",0.0))
    var wind: float=float(environment.get("wind",0.3))
    for i in range(mini(12,int(230*rain))):result.append(_rain_position(i,wind))
    for i in range(mini(12-result.size(),int(135*snow))):result.append(_snow_position(i))
    return result

func _rain_position(index: int,wind: float) -> Vector2:
    return Vector2(18+fposmod(index*157.0+clock*wind*29,1390.0),8+fposmod(index*131.0+clock*(360+index%7*18),774.0))

func _snow_position(index: int) -> Vector2:
    return Vector2(14+fposmod(index*149.0+sin(clock*0.5+index)*14+clock*3,1404.0),8+fposmod(index*113.0+clock*(19+index%7*4),790.0))

func _draw() -> void:
    if environment.is_empty():return
    if role=="stars":_draw_stars()
    elif role=="clouds":_draw_clouds()
    else:_draw_precipitation()

func _draw_stars() -> void:
    var strength: float=float(environment.get("stars",0.0))
    for i in range(91):
        var pos: Vector2=Vector2(50+(i*137)%1330,28+(i*79)%307)
        var shimmer: float=0.60+0.30*sin(clock*0.7+i*1.31)
        draw_rect(Rect2(pos,Vector2(1.5+(i%3)*0.5,1.5+(i%3)*0.5)),Color(0.85,0.90,0.80,strength*shimmer))
    var moon: float=float(environment.get("moon",0.0))
    if moon>0.001:
        var center: Vector2=Vector2(1072,126)
        draw_circle(center,27.0,Color(0.86,0.89,0.77,moon))
        var sky: Color=environment.get("sky_top",Color("273e58"))
        sky.a=moon
        draw_circle(center+Vector2(11,-7),25.0,sky)
    var sun: float=float(environment.get("sun",0.0))
    if sun>0.001:
        var y: float=126+float(environment.get("sun_low",0.0))*115
        draw_circle(Vector2(1083,y),29.0,Color(0.98,0.91,0.71,sun*0.85))

func _draw_clouds() -> void:
    var opacity: float=float(environment.get("cloud",0.6))
    var color: Color=environment.get("cloud_color",Color("dfe6df"))
    color.a=opacity
    var positions: Array[Vector2]=get_cloud_positions()
    for i in range(positions.size()):
        var width: float=245+i%3*64
        if cloud_texture!=null:
            var ratio: float=float(cloud_texture.get_height())/maxf(1.0,float(cloud_texture.get_width()))
            draw_texture_rect(cloud_texture,Rect2(positions[i],Vector2(width,width*ratio)),false,color)
        else:
            draw_rect(Rect2(positions[i]+Vector2(20,13),Vector2(width-40,16)),color)
            draw_rect(Rect2(positions[i]+Vector2(58,0),Vector2(width-130,21)),color)

func _draw_precipitation() -> void:
    var rain: float=float(environment.get("rain",0.0))
    var snow: float=float(environment.get("snow",0.0))
    var wind: float=float(environment.get("wind",0.3))
    if rain>0.001:
        for i in range(int(230*rain)):
            var point: Vector2=_rain_position(i,wind)
            var length: float=10+i%4*3
            draw_line(point,point+Vector2(wind*3.0,length),Color(0.79,0.87,0.88,0.30+rain*0.18),1.0)
    if snow>0.001:
        for i in range(int(135*snow)):
            var point: Vector2=_snow_position(i)
            var radius: float=1.0+i%3
            draw_rect(Rect2(point,Vector2(radius,radius)),Color(0.94,0.96,0.90,0.62+0.12*(i%3)))
    var lightning: float=float(environment.get("lightning",0.0))
    var flash: float=fmod(clock,13.0)
    if lightning>0.1 and not quiet and flash>8.0 and flash<8.14:
        draw_rect(Rect2(0,0,1440,810),Color(0.84,0.89,0.92,lightning*0.13))
