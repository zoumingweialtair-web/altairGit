extends RefCounted
## Contact coordinates traced against the actual 1440 x 810 tree and foreground art.
## Points describe bark/stem/branch surfaces, not arbitrary screen-space spawn lines.
const ANCHORS: Dictionary = {
 "sparrow":Vector2(454,296),"tit":Vector2(547,117),"robin":Vector2(377,319),
 "squirrel":Vector2(332,289),"woodpecker":Vector2(185,310),"owl":Vector2(405,182),
 "butterfly":Vector2(257,565),"luna_moth":Vector2(392,248),"jewel_beetle":Vector2(145,467),"fireflies":Vector2(445,481),
 "kingfisher":Vector2(489,298),"swallow":Vector2(710,230),"magpie":Vector2(594,107),
 "white_eye":Vector2(421,310),"egret":Vector2(855,494),"hedgehog":Vector2(305,755),
 "cat":Vector2(1237,757),"bat":Vector2(718,259),"dragonfly":Vector2(810,530),
 "ladybug":Vector2(237,653),"stag_beetle":Vector2(163,433)
}
const SHELTER: Dictionary = {"sparrow":Vector2(385,189),"tit":Vector2(440,172),"robin":Vector2(377,319)}
static var _cache: Dictionary = {}

static func anchor(id: String, weather: int = 0) -> Vector2:
 if weather in [1,2,4,5,6] and SHELTER.has(id): return SHELTER[id]
 return ANCHORS.get(id,Vector2(300,300))

static func support(id: String) -> String:
 if id == "ladybug": return "plant"
 if id in ["squirrel","woodpecker","jewel_beetle","stag_beetle"]: return "bark"
 if id in ["cat","hedgehog"]: return "sill"
 if id == "egret": return "shore"
 return "branch"

static func crawl_path(id: String, target: Vector2 = Vector2.INF) -> PackedVector2Array:
 if target == Vector2.INF: target=anchor(id)
 match id:
  "squirrel":
   return PackedVector2Array([Vector2(86,800),Vector2(86,750),Vector2(106,703),Vector2(94,656),Vector2(94,626),Vector2(99,580),Vector2(116,532),Vector2(138,475),Vector2(149,418),Vector2(165,365),Vector2(190,326),Vector2(232,294),Vector2(273,284),Vector2(312,294),target])
  "ladybug":
   return PackedVector2Array([Vector2(241,715),Vector2(241,697),Vector2(242,682),Vector2(244,670),Vector2(241,660),target])
  "jewel_beetle":
   return PackedVector2Array([Vector2(105,591),Vector2(114,555),Vector2(127,518),Vector2(139,486),target])
  "stag_beetle":
   return PackedVector2Array([Vector2(109,598),Vector2(121,549),Vector2(140,501),Vector2(150,462),target])
 return PackedVector2Array([target,target])

static func is_hidden(id: String, point: Vector2) -> bool:
 # Endpoints are underneath existing foliage or the flowerpot, never an alpha fade.
 if id == "ladybug": return point.y > 690.0
 if id in ["squirrel","jewel_beetle","stag_beetle"]: return point.y > 588.0
 return false

static func sample_path(points: PackedVector2Array, progress: float) -> Dictionary:
 var key: String=str(points)
 if not _cache.has(key): _cache[key]=_bake(points)
 var baked: Dictionary=_cache[key]
 var samples: PackedVector2Array=baked.points
 var distances: PackedFloat32Array=baked.distances
 var target: float=clampf(progress,0.0,1.0)*float(baked.length)
 var low: int=0
 var high: int=distances.size()-1
 while high-low>1:
  var mid: int=(low+high)/2
  if distances[mid]<target:low=mid
  else:high=mid
 var blend: float=(target-distances[low])/maxf(0.0001,distances[high]-distances[low])
 var point: Vector2=samples[low].lerp(samples[high],clampf(blend,0.0,1.0))
 var tangent: Vector2=(samples[mini(high+1,samples.size()-1)]-samples[maxi(0,low-1)]).normalized()
 if tangent.length_squared()<0.001:tangent=Vector2.UP
 return {"position":point,"tangent":tangent,"distance":target,"length":baked.length}

static func _bake(points: PackedVector2Array) -> Dictionary:
 var samples: PackedVector2Array=[]
 var distances: PackedFloat32Array=[]
 var length: float=0.0
 for segment: int in range(points.size()-1):
  var a: Vector2=points[maxi(0,segment-1)]
  var b: Vector2=points[segment]
  var c: Vector2=points[segment+1]
  var d: Vector2=points[mini(points.size()-1,segment+2)]
  for step: int in range(25):
   if segment>0 and step==0:continue
   var t: float=float(step)/24.0
   var point: Vector2=0.5*((2.0*b)+(-a+c)*t+(2.0*a-5.0*b+4.0*c-d)*t*t+(-a+3.0*b-3.0*c+d)*t*t*t)
   if not samples.is_empty():length+=samples[-1].distance_to(point)
   samples.append(point)
   distances.append(length)
 if samples.size()<2:
  samples=PackedVector2Array([Vector2.ZERO,Vector2.ZERO])
  distances=PackedFloat32Array([0.0,0.0])
 return {"points":samples,"distances":distances,"length":length}

static func closest_progress(points: PackedVector2Array, point: Vector2) -> float:
 var best: float=INF
 var progress: float=0.0
 for index: int in range(161):
  var p: float=float(index)/160.0
  var distance: float=(sample_path(points,p).position as Vector2).distance_squared_to(point)
  if distance<best:
   best=distance
   progress=p
 return progress
