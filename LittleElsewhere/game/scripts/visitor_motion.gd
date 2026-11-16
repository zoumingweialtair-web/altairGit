extends RefCounted
## Creature locomotion follows physical supports and explicit flight sub-states.
const Habitat = preload("res://scripts/habitat_paths.gd")
const IDS: Array[String] = ["sparrow","tit","robin","woodpecker","owl","kingfisher","swallow","magpie","white_eye","egret","squirrel","hedgehog","cat","bat","butterfly","luna_moth","jewel_beetle","fireflies","dragonfly","ladybug","stag_beetle","pigeon","crow","cockatiel","dough_bird","dandelion_bird","paper_bird","cloud_bird","yarn_bird","clockwork_bird","alien_bird","twin_bird","invisible_bird","shadow_bird","inverted_bird","galaxy_bird","crescent_bird"]
const EXPANSION_BIRDS: Array[String] = ["pigeon","crow","cockatiel","dough_bird","dandelion_bird","paper_bird","cloud_bird","yarn_bird","clockwork_bird","alien_bird","twin_bird","invisible_bird","shadow_bird","inverted_bird","galaxy_bird","crescent_bird"]
const BIRDS: Array[String] = ["sparrow","tit","robin","woodpecker","owl","kingfisher","swallow","magpie","white_eye","egret","pigeon","crow","cockatiel","dough_bird","dandelion_bird","paper_bird","cloud_bird","yarn_bird","clockwork_bird","alien_bird","twin_bird","invisible_bird","shadow_bird","inverted_bird","galaxy_bird","crescent_bird"]
const AIRBORNE: Array[String] = ["swallow","bat","butterfly","luna_moth","fireflies","dragonfly","cloud_bird"]
const CRAWLERS: Array[String] = ["squirrel","jewel_beetle","ladybug","stag_beetle"]
const SHELTER_WEATHER: Array[int] = [1,2,4,5,6]

static func duration(id: String, weather: int) -> float:
 if id in ["sparrow","tit","robin","butterfly"]:
  return 40.0 if weather in SHELTER_WEATHER else (34.0 if weather==3 else 30.0)
 return 42.0 if id=="squirrel" else 36.0

static func entry_duration(id: String) -> float:
 if id=="squirrel":return 8.4
 if id=="inverted_bird":return 6.4
 if id=="shadow_bird":return 5.6
 if id in ["cloud_bird","paper_bird"]:return 6.0
 if id in CRAWLERS:return 6.8
 if id in ["cat","hedgehog"]:return 5.0
 if id in ["owl","egret"]:return 5.2
 return 4.8

static func exit_duration(id: String) -> float:
 if id=="squirrel":return 7.2
 if id=="inverted_bird":return 5.6
 if id in ["shadow_bird","cloud_bird"]:return 5.2
 if id in CRAWLERS:return 6.0
 return 4.5

static func spawn(id: String, anchor: Vector2, weather: int) -> Dictionary:
 var actor: Dictionary={"id":id,"age":0.0,"pos":anchor,"start":anchor,"anchor":anchor,
  "fly":false,"alpha":1.0,"facing":1.0,"motion_age":0.0,"phase":"entry","phase_progress":0.0,
  "duration":duration(id,weather),"entry_duration":entry_duration(id),"exit_duration":exit_duration(id),
  "pose":"arrive","weather":weather,"travel":1.0,"land_blend":0.0,"body_tilt":0.0,
  "idle_age":0.0,"route_angle":-PI/2.0,"support_side":1.0,"gait_distance":0.0}
 sample(actor,weather,1.0)
 return actor

static func request_departure(actor: Dictionary) -> void:
 if str(actor.get("phase",""))=="exit":return
 actor["forced_exit_age"]=float(actor["age"])
 actor["exit_from"]=actor["pos"]
 actor["exit_was_flying"]=bool(actor.get("fly",false))
 actor["exit_heading"]=Vector2.from_angle(float(actor.get("route_angle",0.0)))
 actor["exit_perch_blend"]=float(actor.get("perch_blend",1.0))
 actor["exit_invert_blend"]=float(actor.get("invert_blend",0.0))
 actor["duration"]=float(actor["age"])+float(actor["exit_duration"])
 actor["phase"]="exit"
 actor["phase_progress"]=0.0
 if str(actor["id"]) in CRAWLERS:
  var path: PackedVector2Array=Habitat.crawl_path(str(actor["id"]),actor["anchor"])
  actor["exit_path_progress"]=Habitat.closest_progress(path,actor["pos"])

static func advance(actor: Dictionary, delta: float, weather: int, activity: float) -> bool:
 if str(actor["id"])=="butterfly" and weather in SHELTER_WEATHER:request_departure(actor)
 actor["age"]=float(actor["age"])+maxf(0.0,delta)
 actor["motion_age"]=float(actor["motion_age"])+maxf(0.0,delta)*(0.35+0.65*activity)
 sample(actor,weather,activity)
 return float(actor["age"])>float(actor["duration"])

static func sample(actor: Dictionary, weather: int, activity: float) -> void:
 var id: String=str(actor["id"])
 var age: float=float(actor["age"])
 var enter: float=float(actor["entry_duration"])
 var leave: float=float(actor["exit_duration"])
 var end: float=float(actor["duration"])
 var exit_at: float=float(actor.get("forced_exit_age",end-leave))
 actor["alpha"]=1.0
 actor["travel"]=0.0
 actor["perch_blend"]=1.0
 actor["land_blend"]=1.0
 actor["fly"]=false
 actor["body_tilt"]=0.0
 actor["crouch"]=0.0
 actor["invert_blend"]=0.0
 actor["wing_power"]=0.0
 actor["wing_strength"]=0.0
 actor["wing_phase"]=fposmod(float(actor["motion_age"])*_wing_rate(id),1.0)
 actor["flight_mode"]="perch"
 actor["tail_spread"]=0.0
 actor["feet_reach"]=1.0
 actor["support"]=Habitat.support(id)
 actor["occlusion"]="foreground" if id in CRAWLERS else ""
 actor["idle_age"]=maxf(0.0,age-enter)
 if age>=exit_at:
  actor["phase"]="exit"
  actor["phase_progress"]=clampf((age-exit_at)/leave,0.0,1.0)
  if not actor.has("exit_from"):
   actor["exit_from"]=idle_position(actor,exit_at,weather,activity)
   actor["exit_was_flying"]=bool(actor["fly"])
   actor["exit_heading"]=Vector2.from_angle(float(actor.get("route_angle",0.0)))
   actor["exit_perch_blend"]=float(actor["perch_blend"])
   actor["exit_invert_blend"]=float(actor.get("invert_blend",0.0))
  _exit(actor,float(actor["phase_progress"]))
 elif age<enter:
  actor["phase"]="entry"
  actor["phase_progress"]=clampf(age/enter,0.0,1.0)
  _entry(actor,float(actor["phase_progress"]))
 else:
  actor["phase"]="idle"
  actor["phase_progress"]=clampf((age-enter)/maxf(0.1,exit_at-enter),0.0,1.0)
  actor["pos"]=idle_position(actor,age,weather,activity)
 # Weather shelter relocation uses the same complete launch/approach/landing cycle.
 if actor.has("relocate_from") and id not in ["sparrow","tit","robin"]:actor.erase("relocate_from")
 if actor.has("relocate_from") and (actor["relocate_from"] as Vector2).distance_to(actor["anchor"])<0.1:actor.erase("relocate_from")
 if actor.has("relocate_from") and str(actor["phase"])=="idle":
  var relocation: float=clampf((age-float(actor["relocate_at"]))/2.6,0.0,1.0)
  _transfer(actor,actor["relocate_from"],actor["anchor"],relocation,38.0,bool(actor.get("relocate_was_flying",false)))
  if relocation>=1.0:actor.erase("relocate_from")
 actor["wing_strength"]=actor["wing_power"]
 actor["land_blend"]=actor["perch_blend"]
 actor["hidden_in_habitat"]=Habitat.is_hidden(id,actor["pos"])
 if id in EXPANSION_BIRDS:_expansion_gestures(actor)

static func _entry(actor: Dictionary, p: float) -> void:
 var id: String=str(actor["id"])
 var anchor: Vector2=actor["anchor"]
 if id=="shadow_bird":
  _shadow_slide(actor,entry_endpoint(id,anchor),anchor,p)
  return
 if id=="inverted_bird":
  _inverted_entry(actor,p)
  return
 if id in CRAWLERS:
  var moving: float=clampf(p/(0.86 if id=="squirrel" else 1.0),0.0,1.0)
  var path: PackedVector2Array=Habitat.crawl_path(id,anchor)
  var sample_data: Dictionary=Habitat.sample_path(path,smoothstep(0.0,1.0,moving))
  _crawl_pose(actor,sample_data,false)
  actor["perch_blend"]=smoothstep(0.86,1.0,p) if id=="squirrel" else 0.0
  return
 if id in ["cat","hedgehog"]:
  var from: Vector2=entry_endpoint(id,anchor)
  var progress: float=smoothstep(0.0,1.0,minf(p/0.9,1.0))
  actor["pos"]=from.lerp(anchor,progress)
  actor["facing"]=1.0 if anchor.x>from.x else -1.0
  actor["gait_distance"]=from.distance_to(actor["pos"])
  actor["gait_phase"]=fposmod(float(actor["gait_distance"])/20.0,1.0)
  actor["pose"]="walk"
  actor["perch_blend"]=smoothstep(0.82,1.0,p)
  actor["travel"]=1.0-actor["perch_blend"]
  return
 var airborne: bool=id in AIRBORNE
 var flight_p: float=clampf(p/(1.0 if airborne else 0.94),0.0,1.0)
 var progress: float=1.0-pow(1.0-flight_p,1.25 if airborne else 1.5)
 var data: Dictionary=_flight_curve(entry_endpoint(id,anchor),anchor,progress,70.0 if id in BIRDS else 36.0)
 actor["pos"]=data.position
 _heading(actor,data.tangent)
 _flight_pose(actor,"flap",0.85,0.0)
 actor["pose"]="arrive"
 if not airborne:
  if p>=0.64:
   actor["flight_mode"]="brake"
   actor["pose"]="brake"
   actor["tail_spread"]=smoothstep(0.64,0.86,p)
   actor["feet_reach"]=smoothstep(0.71,0.91,p)
   actor["body_tilt"]=-0.18*float(actor["facing"])
   actor["wing_power"]=lerpf(0.9,0.18,smoothstep(0.72,0.97,p))
  if p>=0.9:
   actor["flight_mode"]="land"
   actor["pose"]="land"
   actor["perch_blend"]=smoothstep(0.9,1.0,p)
   actor["fly"]=p<0.98
   actor["body_tilt"]*=1.0-float(actor["perch_blend"])
 else:
  actor["flight_mode"]="glide" if id in ["swallow","bat"] and p>0.7 else "flap"

static func _exit(actor: Dictionary, p: float) -> void:
 var id: String=str(actor["id"])
 var anchor: Vector2=actor["anchor"]
 var from: Vector2=actor["exit_from"]
 if id=="shadow_bird":
  _shadow_slide(actor,from,exit_endpoint(id,anchor),p)
  return
 if id=="inverted_bird" and float(actor.get("exit_invert_blend",0.0))>0.001:
  _inverted_exit(actor,p)
  return
 if id in CRAWLERS:
  var path: PackedVector2Array=Habitat.crawl_path(id,anchor)
  var start_p: float=float(actor.get("exit_path_progress",1.0))
  var settle: float=0.13 if id=="squirrel" and float(actor.get("exit_perch_blend",1.0))>0.5 else 0.0
  var progress: float=start_p*(1.0-smoothstep(0.0,1.0,clampf((p-settle)/maxf(0.01,1.0-settle),0.0,1.0)))
  var data: Dictionary=Habitat.sample_path(path,progress)
  # Forced departure begins at the actual contact, not its nearest baked sample.
  data.position=(data.position as Vector2)+(from-(Habitat.sample_path(path,start_p).position as Vector2))*(1.0-smoothstep(0.0,0.2,p))
  _crawl_pose(actor,data,true)
  actor["perch_blend"]=1.0-smoothstep(0.0,maxf(settle,0.01),p) if settle>0.0 else 0.0
  return
 if id in ["cat","hedgehog"]:
  var progress: float=smoothstep(0.0,1.0,clampf((p-0.1)/0.9,0.0,1.0))
  var target: Vector2=exit_endpoint(id,anchor)
  actor["pos"]=from.lerp(target,progress)
  actor["facing"]=1.0 if target.x>from.x else -1.0
  actor["gait_distance"]=from.distance_to(actor["pos"])
  actor["gait_phase"]=fposmod(float(actor["gait_distance"])/20.0,1.0)
  actor["pose"]="walk"
  actor["perch_blend"]=1.0-smoothstep(0.0,0.16,p)
  actor["travel"]=1.0-float(actor["perch_blend"])
  return
 var was_flying: bool=bool(actor.get("exit_was_flying",false)) or id in AIRBORNE
 var prep: float=0.0 if was_flying else 0.075
 if p<prep:
  actor["pos"]=from
  actor["pose"]="crouch"
  actor["flight_mode"]="takeoff"
  actor["perch_blend"]=1.0
  actor["crouch"]=sin(p/prep*PI)*0.65
  return
 actor["crouch"]=0.0
 var progress: float=pow(clampf((p-prep)/maxf(0.001,1.0-prep),0.0,1.0),1.25)
 var target: Vector2=exit_endpoint(id,anchor)
 if id in BIRDS:target=Vector2(1610 if from.x>720 else -190,maxf(-100.0,from.y-185.0))
 var heading: Vector2=actor.get("exit_heading",Vector2.RIGHT)
 if was_flying:target=Vector2(1610 if heading.x>=0.0 else -190,maxf(-100.0,from.y-130.0))
 var data: Dictionary=_flight_curve(from,target,progress,85.0,heading if was_flying else Vector2.ZERO)
 actor["pos"]=data.position
 _heading(actor,data.tangent)
 _flight_pose(actor,"takeoff" if p<0.25 else "flap",1.0,0.0)
 actor["pose"]="takeoff" if p<0.25 else "depart"
 actor["feet_reach"]=1.0-smoothstep(prep,prep+0.15,p)
 actor["tail_spread"]=1.0-smoothstep(prep,prep+0.28,p)
 actor["perch_blend"]=1.0-smoothstep(prep,prep+0.1,p) if not was_flying else 0.0
 if p>0.45 and id in ["owl","egret","magpie","swallow"]:
  actor["flight_mode"]="glide" if fmod(float(actor["motion_age"]),2.6)>1.7 else "flap"

static func _crawl_pose(actor: Dictionary, data: Dictionary, descending: bool) -> void:
 actor["pos"]=data.position
 actor["route_angle"]=(data.tangent as Vector2).angle()+(PI if descending else 0.0)
 actor["facing"]=1.0
 actor["pose"]="climb"
 actor["perch_blend"]=0.0
 actor["support"]="plant" if actor["id"]=="ladybug" else "bark"
 actor["support_side"]=1.0
 actor["gait_distance"]=data.distance
 actor["gait_phase"]=fposmod(float(data.distance)/(21.0 if actor["id"]=="squirrel" else 8.0),1.0)
 actor["travel"]=1.0

static func _heading(actor: Dictionary, tangent: Vector2) -> void:
 if absf(tangent.x)>0.08:actor["facing"]=1.0 if tangent.x>0.0 else -1.0
 actor["body_tilt"]=clampf(tangent.y*0.32*float(actor["facing"]),-0.26,0.26)
 actor["route_angle"]=tangent.angle()
 actor["turn_scale"]=lerpf(0.4,1.0,absf(tangent.x))
 actor["bank"]=tangent.y

static func _flight_pose(actor: Dictionary, mode: String, power: float, perched: float) -> void:
 actor["fly"]=true
 actor["flight_mode"]=mode
 actor["wing_power"]=power
 actor["wing_strength"]=power
 actor["perch_blend"]=perched
 actor["travel"]=1.0-perched
 actor["feet_reach"]=0.0
 actor["support"]="air"

static func _wing_rate(id: String) -> float:
 if id=="cloud_bird":return 1.0
 if id=="paper_bird":return 2.7
 if id=="clockwork_bird":return 5.0
 if id in ["owl","egret","magpie","crow","galaxy_bird","crescent_bird"]:return 3.2
 if id in ["swallow","bat"]:return 5.3
 if id in ["butterfly","luna_moth"]:return 5.0
 if id=="dragonfly":return 14.0
 return 7.5

static func _flight_curve(from: Vector2, to: Vector2, p: float, lift: float, start_heading: Vector2 = Vector2.ZERO) -> Dictionary:
 var dx: float=to.x-from.x
 var c1: Vector2=from+Vector2(dx*0.32,-lift)
 if start_heading.length_squared()>0.01:c1=from+start_heading.normalized()*minf(160.0,from.distance_to(to)*0.3)
 var c2: Vector2=to+Vector2(-dx*0.24,-lift*0.58)
 var q: float=clampf(p,0.0,1.0)
 var point: Vector2=from.bezier_interpolate(c1,c2,to,q)
 var tangent: Vector2=3.0*(1.0-q)*(1.0-q)*(c1-from)+6.0*(1.0-q)*q*(c2-c1)+3.0*q*q*(to-c2)
 return {"position":point,"tangent":tangent.normalized()}

static func _transfer(actor: Dictionary, from: Vector2, to: Vector2, p: float, lift: float = 60.0, airborne_start: bool = false) -> void:
 var prep: float=0.0 if airborne_start else 0.08
 if p<prep:
  actor["pos"]=from
  actor["pose"]="crouch"
  actor["crouch"]=sin(p/0.08*PI)*0.45
  return
 var flight_p: float=clampf((p-prep)/(0.94-prep),0.0,1.0)
 var data: Dictionary=_flight_curve(from,to,smoothstep(0.0,1.0,flight_p),lift,Vector2.from_angle(float(actor.get("relocate_heading",0.0))) if airborne_start else Vector2.ZERO)
 actor["pos"]=data.position
 _heading(actor,data.tangent)
 _flight_pose(actor,"takeoff" if p<0.25 else "flap",0.9,0.0)
 actor["pose"]="takeoff" if p<0.25 else "fly_to_food"
 actor["crouch"]=0.0
 if p>0.7:
  actor["flight_mode"]="brake" if p<0.9 else "land"
  actor["pose"]="land"
  actor["tail_spread"]=smoothstep(0.7,0.91,p)
  actor["feet_reach"]=smoothstep(0.75,0.93,p)
  actor["wing_power"]=lerpf(0.8,0.0,smoothstep(0.8,1.0,p))
  actor["perch_blend"]=smoothstep(0.9,1.0,p)
  actor["fly"]=p<0.98

static func entry_endpoint(id: String, anchor: Vector2) -> Vector2:
 if id in CRAWLERS:return Habitat.crawl_path(id,anchor)[0]
 if id=="shadow_bird":return Vector2(1620,anchor.y)
 if id=="inverted_bird":return Vector2(-180,anchor.y+120)
 if id=="hedgehog":return Vector2(-100,anchor.y)
 if id=="cat":return Vector2(1570,anchor.y)
 if id=="egret":return Vector2(1600,370)
 if id in ["swallow","bat","dragonfly"]:return Vector2(1590,anchor.y-55)
 if id in ["butterfly","luna_moth","fireflies"]:return Vector2(-130,anchor.y+45)
 return Vector2(-180,maxf(-100.0,anchor.y-95.0))

static func exit_endpoint(id: String, anchor: Vector2) -> Vector2:
 if id in CRAWLERS:return Habitat.crawl_path(id,anchor)[0]
 if id=="shadow_bird":return Vector2(1620,anchor.y)
 if id=="hedgehog":return Vector2(-120,anchor.y)
 if id=="cat":return Vector2(1600,anchor.y)
 if id in ["owl","tit","magpie","woodpecker"]:return Vector2(-190,-100)
 if id in ["butterfly","luna_moth","fireflies"]:return Vector2(-170,anchor.y-90)
 return Vector2(1620,maxf(-100.0,anchor.y-185.0))

static func route(id: String, from: Vector2, to: Vector2, p: float, incoming: bool) -> Vector2:
 if id in CRAWLERS:
  var path: PackedVector2Array=Habitat.crawl_path(id,to if incoming else from)
  return Habitat.sample_path(path,p if incoming else 1.0-p).position
 if id in ["cat","hedgehog","shadow_bird"]:return from.lerp(to,smoothstep(0.0,1.0,p))
 return _flight_curve(from,to,smoothstep(0.0,1.0,p),65.0).position

static func idle_position(actor: Dictionary, age: float, weather: int, activity: float) -> Vector2:
 var id: String=str(actor["id"])
 var anchor: Vector2=actor["anchor"]
 var t: float=maxf(0.0,age-float(actor["entry_duration"]))
 actor["fly"]=false
 actor["perch_blend"]=1.0
 actor["pose"]=idle_pose(id,float(actor["motion_age"]),false)
 actor["support"]=Habitat.support(id)
 if id=="squirrel":actor["support"]="branch"
 if id=="inverted_bird":actor["invert_blend"]=1.0
 if id=="shadow_bird":
  actor["pose"]="shadow_watch"
  return anchor
 if id in ["crow","clockwork_bird","twin_bird"]:
  var feeding_at: float=9.0+float(EXPANSION_BIRDS.find(id)%3)*1.2
  var feeder: Vector2=Vector2(1107,584) if id=="crow" else Vector2(1140,584)
  if t>=feeding_at and t<feeding_at+4.8:
   _transfer(actor,anchor,feeder,(t-feeding_at)/4.8,85.0)
   return actor["pos"]
  if t>=feeding_at+4.8:
   actor["support"]="feeder"
   return feeder
 if id in ["sparrow","tit"] and weather not in SHELTER_WEATHER:
  var start: float=7.0 if id=="sparrow" else 9.5
  var feeder: Vector2=Vector2(1140,584) if id=="sparrow" else Vector2(1107,584)
  if t>=start and t<start+4.4:
   _transfer(actor,anchor,feeder,(t-start)/4.4,70.0)
   return actor["pos"]
  if t>=start+4.4:
   actor["pose"]="peck" if fmod(t,4.7)>2.9 else "look"
   actor["support"]="feeder"
   return feeder
 if id in ["jewel_beetle","ladybug","stag_beetle"]:
  var data: Dictionary=Habitat.sample_path(Habitat.crawl_path(id,anchor),1.0-(1.0-cos(t*0.42))*0.018)
  _crawl_pose(actor,data,false)
  actor["pose"]="crawl"
  return data.position
 if id in AIRBORNE:
  var frequency: float=0.25
  var extent: Vector2=Vector2(95,24)
  match id:
   "swallow":extent=Vector2(160,34);frequency=0.28
   "bat":extent=Vector2(108,36);frequency=0.31
   "butterfly":extent=Vector2(32,18);frequency=0.38
   "luna_moth":extent=Vector2(28,16);frequency=0.25
   "dragonfly":extent=Vector2(44,12);frequency=0.34
   "fireflies":extent=Vector2(12,8);frequency=0.18
   "cloud_bird":extent=Vector2(25,10);frequency=0.20
  var sign_x: float=-1.0 if id in ["swallow","bat","dragonfly"] else 1.0
  var offset: Vector2=Vector2(sign_x*sin(t*frequency)*extent.x,sin(t*frequency*1.6)*extent.y)*activity
  var tangent: Vector2=Vector2(sign_x*cos(t*frequency)*extent.x,cos(t*frequency*1.6)*extent.y*1.6).normalized()
  _heading(actor,tangent)
  _flight_pose(actor,"glide" if id in ["swallow","bat"] and fmod(t,3.1)>2.1 else "flap",0.8,0.0)
  actor["pose"]="hover" if id in ["dragonfly","luna_moth","fireflies","cloud_bird"] else "fly"
  if id=="cloud_bird":actor["flight_mode"]="float";actor["wing_power"]=0.16
  return anchor+offset
 if id=="white_eye":
  var local: float=fmod(t,9.0)
  var progress: float=smoothstep(0.0,1.0,clampf((local-4.0)/0.55,0.0,1.0))
  var sign_x: float=1.0 if int(t/9.0)%2==0 else -1.0
  var dx: float=(progress if sign_x>0 else 1.0-progress)*10.0
  actor["pose"]="hop" if progress>0.0 and progress<1.0 else "perch"
  return anchor+Vector2(dx,-sin(progress*PI)*5.0)
 return anchor

static func idle_pose(id: String, t: float, flying: bool) -> String:
 if flying:return "hover" if id in ["dragonfly","luna_moth","fireflies"] else "glide"
 match id:
  "squirrel":return "nibble" if fmod(t,8.0)<5.4 else "look"
  "woodpecker":return "peck" if fmod(t,5.8)>4.7 else "listen"
  "owl":return "watch"
  "cat":return "groom" if fmod(t,13.0)>9.5 else "sit"
  "hedgehog":return "sniff"
  "egret":return "wade"
  "jewel_beetle","ladybug","stag_beetle":return "crawl"
  "tit":return "preen" if fmod(t,9.0)>6.0 else "look"
  "robin":return "sing" if fmod(t,9.0)>6.5 else "perch"
  "sparrow":return "peck" if fmod(t,6.0)>4.5 else "look"
 return "perch"

# New characters retain the same contact origin as ordinary birds. Only the
# hanging bird rotates the artwork around that foot origin after touching bark.
static func _shadow_slide(actor: Dictionary, from: Vector2, to: Vector2, p: float) -> void:
 actor["pos"]=from.lerp(to,smoothstep(0.0,1.0,p))
 actor["fly"]=false
 actor["support"]="sill"
 actor["facing"]=1.0 if to.x>from.x else -1.0
 actor["route_angle"]=0.0 if to.x>from.x else PI
 actor["pose"]="shadow_slide"
 actor["flight_mode"]="surface"
 actor["perch_blend"]=1.0
 actor["travel"]=sin(p*PI)
 actor["gait_distance"]=from.distance_to(actor["pos"])
 actor["gait_phase"]=fposmod(float(actor["gait_distance"])/32.0,1.0)

static func _inverted_entry(actor: Dictionary, p: float) -> void:
 var anchor: Vector2=actor["anchor"]
 var flight_p: float=smoothstep(0.0,1.0,clampf(p/0.78,0.0,1.0))
 var data: Dictionary=_flight_curve(entry_endpoint("inverted_bird",anchor),anchor,flight_p,-55.0)
 actor["pos"]=data.position
 _heading(actor,data.tangent)
 _flight_pose(actor,"flap" if p<0.54 else "brake",0.85,0.0)
 actor["pose"]="arrive" if p<0.54 else "brake"
 actor["feet_reach"]=smoothstep(0.52,0.76,p)
 actor["tail_spread"]=smoothstep(0.50,0.74,p)
 if p>=0.78:
  actor["pos"]=anchor
  actor["fly"]=false
  actor["support"]="branch_underside"
  actor["pose"]="invert_settle"
  actor["flight_mode"]="land"
  actor["perch_blend"]=smoothstep(0.78,0.94,p)
  actor["wing_power"]=lerpf(0.4,0.0,smoothstep(0.78,1.0,p))
  actor["invert_blend"]=smoothstep(0.80,1.0,p)
  actor["body_tilt"]=0.0

static func _inverted_exit(actor: Dictionary, p: float) -> void:
 var from: Vector2=actor["exit_from"]
 var inverted: float=float(actor["exit_invert_blend"])
 # Unfold around the same feet before releasing; no reposition on interruption.
 var release: float=0.20
 if p<release:
  actor["pos"]=from
  actor["invert_blend"]=inverted*(1.0-smoothstep(0.0,release,p))
  actor["fly"]=false
  actor["support"]="branch_underside"
  actor["flight_mode"]="takeoff"
  actor["pose"]="unhook"
  actor["wing_power"]=smoothstep(0.04,release,p)*0.7
  actor["perch_blend"]=1.0
  actor["body_tilt"]=0.0
  return
 var q: float=pow(clampf((p-release)/(1.0-release),0.0,1.0),1.25)
 var data: Dictionary=_flight_curve(from,Vector2(-190,from.y+150),q,-80.0)
 actor["pos"]=data.position
 _heading(actor,data.tangent)
 _flight_pose(actor,"takeoff" if p<0.36 else "flap",1.0,0.0)
 actor["pose"]="takeoff" if p<0.36 else "depart"
 actor["feet_reach"]=1.0-smoothstep(release,release+0.12,p)
 actor["perch_blend"]=1.0-smoothstep(release,release+0.08,p)

static func _gesture_pulse(p: float, start: float, end: float) -> float:
 if p<=start or p>=end:return 0.0
 return sin((p-start)/(end-start)*PI)

static func _expansion_gestures(actor: Dictionary) -> void:
 var id: String=str(actor["id"])
 var t: float=float(actor["motion_age"])
 var p: float=fposmod(t*0.145+float(EXPANSION_BIRDS.find(id))*0.073,1.0)
 var resting: bool=str(actor["phase"])=="idle" and (not bool(actor["fly"]) or id=="cloud_bird")
 var feeding: float=_gesture_pulse(p,0.50,0.80) if resting else 0.0
 actor["special_phase"]=p
 actor["special_action"]="observe"
 actor["feed_blend"]=feeding
 actor["seed_visible"]=feeding>0.06
 actor["windup"]=_gesture_pulse(p,0.14,0.44) if resting and id=="clockwork_bird" else 0.0
 actor["antenna_scan"]=(sin(t*1.7)+1.0)*0.5 if id=="alien_bird" else 0.0
 actor["head_disagreement"]=_gesture_pulse(p,0.10,0.46) if resting and id=="twin_bird" else 0.0
 actor["orbit_phase"]=fposmod(t*0.12,1.0)
 actor["fullness"]=0.5+0.5*sin(t*0.38)
 actor["body_float"]=sin(t*1.3)*2.5 if id=="cloud_bird" else 0.0
 if bool(actor["fly"]) and id=="paper_bird":
  var envelope: float=sin(float(actor["phase_progress"])*PI) if str(actor["phase"]) in ["entry","exit"] else 0.0
  actor["pos"]=(actor["pos"] as Vector2)+Vector2(0,sin(t*5.4)*7.0*envelope)
  actor["body_tilt"]+=sin(t*4.0)*0.12*envelope
  actor["flight_mode"]="flutter"
 if not resting:return
 actor["pose"]="feed" if feeding>0.05 else "look"
 actor["special_action"]="feed" if feeding>0.05 else "observe"
 match id:
  "pigeon":
   if p<0.25:actor["pose"]="head_bob";actor["special_action"]="head_bob"
  "crow":
   if p<0.30:actor["pose"]="inspect";actor["special_action"]="inspect"
  "cockatiel":
   if p<0.30:actor["pose"]="crest_pop";actor["special_action"]="crest_pop"
  "dough_bird":
   if p<0.30:actor["pose"]="inflate";actor["special_action"]="inflate"
  "dandelion_bird":
   if p<0.30:actor["pose"]="seed_sneeze";actor["special_action"]="seed_sneeze"
  "cloud_bird":actor["pose"]="hover_feed" if feeding>0.05 else "hover";actor["special_action"]="condense" if feeding>0.05 else "drift"
  "paper_bird":
   if p<0.30:actor["pose"]="fold";actor["special_action"]="fold"
  "yarn_bird":
   if p<0.30:actor["pose"]="unravel";actor["special_action"]="unravel"
  "clockwork_bird":
   if float(actor["windup"])>0.05:actor["pose"]="windup";actor["special_action"]="windup"
  "alien_bird":
   if p<0.42:actor["pose"]="calibrate";actor["special_action"]="calibrate"
  "twin_bird":
   if float(actor["head_disagreement"])>0.05:actor["pose"]="argue";actor["special_action"]="argue"
  "invisible_bird":actor["special_action"]="floating_seed" if feeding>0.05 else "invisible_blink"
  "shadow_bird":actor["pose"]="shadow_feed" if feeding>0.05 else "shadow_watch"
  "inverted_bird":actor["pose"]="hanging_feed" if feeding>0.05 else "hang"
  "galaxy_bird":actor["special_action"]="orbit"
  "crescent_bird":actor["special_action"]="moon_phase"
