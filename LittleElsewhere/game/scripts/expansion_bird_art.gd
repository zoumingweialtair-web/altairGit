extends RefCounted
## Painted, articulated visitors. Every silhouette comes from an alpha atlas;
## only small secondary effects are drawn in code. The contact origin is (0, 0).
const IDS: Array[String] = [
 "pigeon", "crow", "cockatiel", "dough_bird",
 "dandelion_bird", "paper_bird", "cloud_bird", "yarn_bird",
 "clockwork_bird", "alien_bird", "twin_bird", "invisible_bird",
 "shadow_bird", "inverted_bird", "galaxy_bird", "crescent_bird"
]
const ATLAS_PATHS: Array[String] = [
 "res://assets/creatures/expansion/atlas_a.png", "res://assets/creatures/expansion/atlas_b.png",
 "res://assets/creatures/expansion/atlas_c.png", "res://assets/creatures/expansion/atlas_d.png"
]
const BODY_HEIGHTS: Array[float] = [62.0, 59.0, 66.0, 59.0, 65.0, 59.0, 58.0, 61.0, 64.0, 63.0, 45.0, 63.0, 23.0, 63.0, 67.0, 70.0]
static var _atlases: Dictionary = {}
static var _pieces: Dictionary = {}

static func clear_cache() -> void:
 _atlases.clear()
 _pieces.clear()

static func is_available(id: String) -> bool:
 return not _piece(id, 0).is_empty()

static func asset_snapshot() -> Dictionary:
 var result: Dictionary = {}
 for id: String in IDS:
  var body: Dictionary = _piece(id, 0)
  result[id] = {"ready": not body.is_empty(), "body_source_size": body.get("size", Vector2.ZERO)}
 return result

static func bounds(id: String, flying: bool = false) -> Rect2:
 if id == "shadow_bird":
  return Rect2(-53, -31, 106, 36)
 if flying:
  return Rect2(-94, -118, 188, 156)
 return Rect2(-58, -91, 116, 99)

static func bounds_for_actor(actor: Dictionary) -> Rect2:
 var id: String = str(actor.get("id", ""))
 var result: Rect2 = bounds(id, bool(actor.get("fly", false)))
 var angle: float = float(actor.get("body_tilt", 0.0))
 if id == "inverted_bird":
  angle += PI * clampf(float(actor.get("invert_blend", 0.0)), 0.0, 1.0)
 return Transform2D(angle, Vector2.ZERO) * result

static func draw_bird(canvas: Node2D, actor: Dictionary, context: Dictionary = {}) -> void:
 var id: String = str(actor.get("id", ""))
 var index: int = IDS.find(id)
 if index < 0:
  return
 var body: Dictionary = _piece(id, 0)
 if body.is_empty():
  return
 var data: Dictionary = {"body": body, "wing": _piece(id, 1), "feet": _piece(id, 3), "height": BODY_HEIGHTS[index]}
 if id == "clockwork_bird":
  data["key"] = _piece(id, 2)
  data["far_wing"] = data["wing"]
 elif id == "twin_bird":
  data["head_left"] = _piece(id, 2, 0)
  data["head_right"] = _piece(id, 2, 1)
  data["far_wing"] = data["wing"]
 else:
  data["far_wing"] = _piece(id, 2)
 var painter: Painter = Painter.new(canvas, actor, context, data)
 painter.paint()
 canvas.draw_set_transform(Vector2.ZERO)

static func _atlas(index: int) -> Dictionary:
 if _atlases.has(index):
  return _atlases[index]
 var path: String = ATLAS_PATHS[index]
 var texture: Texture2D
 var source: Image
 if ResourceLoader.exists(path):
  texture = load(path) as Texture2D
  if texture != null:
   source = texture.get_image()
 elif FileAccess.file_exists(path):
  source = Image.load_from_file(ProjectSettings.globalize_path(path))
  if source != null and not source.is_empty():
   texture = ImageTexture.create_from_image(source)
 if source == null or source.is_empty() or texture == null:
  return {}
 if source.is_compressed():
  source.decompress()
 var data: Dictionary = {"texture": texture, "image": source, "width": source.get_width(), "height": source.get_height()}
 _atlases[index] = data
 return data

static func _piece(id: String, column: int, half: int = -1) -> Dictionary:
 var key: String = id + ":" + str(column) + ":" + str(half)
 if _pieces.has(key):
  return _pieces[key]
 var index: int = IDS.find(id)
 if index < 0:
  return {}
 var atlas: Dictionary = _atlas(index / 4)
 if atlas.is_empty():
  return {}
 var width: int = int(atlas["width"])
 var height: int = int(atlas["height"])
 var row: int = index % 4
 var x0: int = roundi(float(width) * float(column) / 4.0)
 var x1: int = roundi(float(width) * float(column + 1) / 4.0)
 var y0: int = roundi(float(height) * float(row) / 4.0)
 var y1: int = roundi(float(height) * float(row + 1) / 4.0)
 if half >= 0:
  var middle: int = roundi(float(x0 + x1) * 0.5)
  if half == 0:
   x1 = middle
  else:
   x0 = middle
 if column == 1:
  x0 += 66
 if column == 0:
  x1 = mini(width, x1 + 66)
 var cell: Rect2i = Rect2i(x0, y0, x1 - x0, y1 - y0)
 var source: Image = atlas["image"]
 var cell_image: Image = source.get_region(cell)
 var mask: Image = cell_image.duplicate()
 mask.convert(Image.FORMAT_RGBA8)
 var pixels: PackedByteArray = mask.get_data()
 for offset: int in range(3, pixels.size(), 4):
  if pixels[offset] < 32:
   pixels[offset] = 0
 mask = Image.create_from_data(mask.get_width(), mask.get_height(), false, Image.FORMAT_RGBA8, pixels)
 var used: Rect2i = mask.get_used_rect()
 if used.size.x <= 0 or used.size.y <= 0:
  return {}
 var crop: Rect2i = Rect2i(cell.position + used.position, used.size)
 var part_texture: AtlasTexture = AtlasTexture.new()
 part_texture.atlas = atlas["texture"]
 part_texture.region = Rect2(crop)
 part_texture.filter_clip = true
 var piece: Dictionary = {"texture": part_texture, "size": Vector2(used.size), "source_region": crop}
 if column == 0 and id != "twin_bird" and id != "shadow_bird" or id == "twin_bird" and column == 2:
  piece["eyes"] = _find_eyes(cell_image.get_region(used))
 _pieces[key] = piece
 return piece

static func _find_eyes(source: Image) -> Array:
 # Connected dark dots, detected once per painted head, make eyelids follow the art.
 # Reject uncertain matches rather than put a blink over a feather or outline.
 var width: int = source.get_width()
 var height: int = source.get_height()
 var seen: PackedByteArray = PackedByteArray()
 seen.resize(width * height)
 var candidates: Array[Dictionary] = []
 for y: int in range(int(height * 0.12), int(height * 0.70)):
  for x: int in range(int(width * 0.10), int(width * 0.90)):
   var first: int = y * width + x
   if seen[first] != 0:
    continue
   seen[first] = 1
   var color: Color = source.get_pixel(x, y)
   if color.a < 0.80 or maxf(color.r, maxf(color.g, color.b)) > 0.28:
    continue
   var queue: PackedInt32Array = PackedInt32Array([first])
   var count: int = 0
   var min_x: int = x
   var max_x: int = x
   var min_y: int = y
   var max_y: int = y
   while count < queue.size():
    var pixel: int = queue[count]
    count += 1
    var px: int = pixel % width
    var py: int = pixel / width
    min_x = mini(min_x, px)
    max_x = maxi(max_x, px)
    min_y = mini(min_y, py)
    max_y = maxi(max_y, py)
    for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
     var nx: int = px + step.x
     var ny: int = py + step.y
     if nx < 0 or nx >= width or ny < 0 or ny >= height:
      continue
     var next: int = ny * width + nx
     if seen[next] != 0:
      continue
     seen[next] = 1
     var sample: Color = source.get_pixel(nx, ny)
     if sample.a >= 0.80 and maxf(sample.r, maxf(sample.g, sample.b)) <= 0.28:
      queue.append(next)
   var size: Vector2 = Vector2(max_x - min_x + 1, max_y - min_y + 1)
   if count < 4 or count > width * height * 0.004 or size.x > width * 0.10 or size.y > height * 0.12:
    continue
   if size.x / size.y < 0.48 or size.x / size.y > 1.85:
    continue
   var center: Vector2 = Vector2(min_x + max_x, min_y + max_y) * 0.5
   var lid: Color = source.get_pixel(clampi(int(center.x), 0, width - 1), clampi(min_y - maxi(3, int(size.y)), 0, height - 1))
   if lid.a < 0.9:
    continue
   candidates.append({"center": center, "size": size, "area": count, "lid": lid})
 var best: Array = []
 var best_score: float = INF
 for i: int in candidates.size():
  for j: int in range(i + 1, candidates.size()):
   var left: Dictionary = candidates[i]
   var right: Dictionary = candidates[j]
   var lp: Vector2 = left["center"]
   var rp: Vector2 = right["center"]
   var distance: float = absf(lp.x - rp.x)
   if distance < width * 0.07 or distance > width * 0.37 or absf(lp.y - rp.y) > height * 0.055:
    continue
   var ratio: float = float(left["area"]) / float(right["area"])
   if ratio < 0.45 or ratio > 2.2:
    continue
   var score: float = absf(lp.y - rp.y) / height * 6.0 + absf(log(ratio)) + absf((lp.x + rp.x) * 0.5 / width - 0.5)
   if score < best_score:
    best_score = score
    best = [left, right]
 for eye: Dictionary in best:
  eye["center"] = eye["center"] / Vector2(width, height)
  eye["size"] = eye["size"] / Vector2(width, height)
 return best

class Painter:
 extends RefCounted
 var c: Node2D
 var a: Dictionary
 var art: Dictionary
 var id: String
 var t: float
 var special: float
 var activity: float
 var light: Color
 var alpha: float
 var flying: bool
 var mode: String
 var landing: float
 var reach: float
 var root: Transform2D
 var torso: Transform2D
 var body_rect: Rect2
 var body_width: float
 var body_height: float
 var wing_cycle: float
 var blink: float
 var action: String

 func _init(canvas: Node2D, actor: Dictionary, context: Dictionary, pieces: Dictionary) -> void:
  c = canvas
  a = actor
  art = pieces
  id = str(a["id"])
  t = float(a.get("motion_age", a.get("age", 0.0)))
  activity = float(context.get("activity", 1.0))
  light = context.get("light", Color.WHITE)
  alpha = float(context.get("alpha", a.get("alpha", 1.0)))
  flying = bool(a.get("fly", false)) and id != "shadow_bird"
  mode = str(a.get("flight_mode", "flap" if flying else "perch"))
  landing = clampf(float(a.get("perch_blend", 0.0 if flying else 1.0)), 0.0, 1.0) if flying else 1.0
  reach = clampf(float(a.get("feet_reach", landing)), 0.0, 1.0)
  special = clampf(float(a.get("special_phase", fposmod(t / 7.0, 1.0))), 0.0, 1.0)
  action = str(a.get("special_action", ""))
  wing_cycle = sin(float(a.get("wing_phase", fposmod(t * 6.0, 1.0))) * TAU)
  body_height = float(art["height"])
  var source_size: Vector2 = art["body"]["size"]
  body_width = minf(91.0, body_height * source_size.x / maxf(1.0, source_size.y))
  if id == "shadow_bird":
   body_width = 88.0
  body_rect = Rect2(-body_width * 0.5, -body_height - 6.0, body_width, body_height)
  var face: float = -1.0 if float(a.get("facing", 1.0)) < 0.0 else 1.0
  var turn: float = maxf(0.28, float(a.get("turn_scale", 1.0)))
  var tilt: float = float(a.get("body_tilt", 0.0)) * face
  var invert: float = PI * clampf(float(a.get("invert_blend", 0.0)), 0.0, 1.0) if id == "inverted_bird" else 0.0
  root = Transform2D(tilt + invert, Vector2(face * turn, 1.0), 0.0, a.get("pos", Vector2.ZERO))
  var breath: float = sin(t * 2.15 + float(IDS.find(id)) * 0.7) * 0.012 * activity * landing
  var bob: float = -sin(t * 2.15) * 0.65 * activity * landing
  var feed: float = clampf(float(a.get("feed_blend", 0.0)), 0.0, 1.0) * landing
  var squash: float = clampf(float(a.get("crouch", 0.0)), 0.0, 1.0) * 0.07
  var body_angle: float = sin(t * 0.7) * 0.022 * activity * landing + feed * 0.18
  var body_scale: Vector2 = Vector2(1.0 - breath + squash, 1.0 + breath - squash)
  if id == "dough_bird":
   var puff: float = (0.5 + 0.5 * sin(t * 1.45)) * 0.065 * activity * landing
   body_scale += Vector2(puff, puff * 0.6)
   bob -= puff * 10.0
  elif id == "paper_bird":
   body_angle += sin(t * 4.8) * 0.045 * activity
   body_scale.x += sin(t * 3.4) * 0.035 * activity
  elif id == "cloud_bird":
   body_scale += Vector2(sin(t * 1.3), cos(t * 1.3)) * 0.018 * activity
  elif id == "alien_bird":
   body_angle += sin(t * 4.2) * float(a.get("antenna_scan", 0.5)) * 0.035 * landing
  elif id == "crescent_bird":
   body_scale += Vector2.ONE * float(a.get("fullness", 0.0)) * 0.07
  var body_offset: Vector2 = Vector2(feed * 2.2, bob + feed * 3.5 + (float(a.get("body_float", 0.0)) if id == "cloud_bird" else 0.0))
  torso = root * Transform2D(body_angle, body_scale, 0.0, body_offset)
  var blink_clock: float = fposmod(t + float(IDS.find(id)) * 0.37, 5.9)
  blink = sin(clampf((blink_clock - 4.92) / 0.17, 0.0, 1.0) * PI) if blink_clock > 4.92 and blink_clock < 5.09 else 0.0

 func tint(opacity: float = 1.0) -> Color:
  return Color(light.r, light.g, light.b, alpha * opacity)

 func piece(data: Dictionary, rect: Rect2, transform: Transform2D, opacity: float = 1.0, mirrored: bool = false) -> void:
  if data.is_empty():
   return
  var drawing_transform: Transform2D = transform
  if mirrored:
   drawing_transform = transform * Transform2D(0.0, Vector2(-1.0, 1.0), 0.0, Vector2.ZERO)
  c.draw_set_transform_matrix(drawing_transform)
  c.draw_texture_rect(data["texture"], rect, false, tint(opacity))

 func paint() -> void:
  if id == "shadow_bird":
   paint_shadow()
   return
  if id == "clockwork_bird":
   paint_key()
  paint_wing(false)
  paint_feet()
  var opacity: float = 0.82 + sin(t * 1.4) * 0.09 if id == "invisible_bird" else 1.0
  piece(art["body"], body_rect, torso, opacity)
  paint_blink(art["body"], body_rect, torso)
  if id == "twin_bird":
   paint_heads()
  paint_wing(true)
  paint_special()

 func paint_feet() -> void:
  var foot_data: Dictionary = art["feet"]
  if foot_data.is_empty():
   return
  var foot_size: Vector2 = foot_data["size"]
  var width: float = clampf(body_width * (0.64 if id == "alien_bird" else 0.43), 18.0, 41.0)
  var height: float = clampf(width * foot_size.y / maxf(foot_size.x, 1.0), 6.0, 12.0)
  var floor_y: float = lerpf(-14.0, 0.0, reach)
  var foot_scale: Vector2 = Vector2(1.0, lerpf(0.70, 1.0, reach))
  var shuffle: float = sin(t * 9.5) * 0.7 * activity * landing if id == "alien_bird" else 0.0
  piece(foot_data, Rect2(-width * 0.5, -height, width, height), root * Transform2D(shuffle * 0.018, foot_scale, 0.0, Vector2(shuffle, floor_y)))

 func paint_wing(near: bool) -> void:
  var data: Dictionary = art["wing" if near else "far_wing"]
  if data.is_empty():
   return
  var side: float = -1.0 if near else 1.0
  var shoulder: Vector2 = Vector2(body_width * side * (0.30 if near else 0.23), body_rect.position.y + body_height * 0.43)
  var flight: float = 1.0 - landing
  var stroke: float = (wing_cycle + 1.0) * 0.5
  var angle: float = lerpf(0.12, 2.70, stroke)
  if mode in ["glide", "cruise", "float"]:
   angle = 1.30 + sin(t * 3.4) * (0.13 if mode != "float" else 0.06)
  elif mode in ["brake", "land"]:
   angle = 1.12 + stroke * 1.35
  var little_flick: float = pow(maxf(0.0, sin(t * 1.6 - 0.6)), 14.0) * 0.16 * activity
  var rotation: float = side * -lerpf(0.10 + little_flick, angle, flight)
  var source: Vector2 = data["size"]
  var height: float = lerpf(body_height * 0.35, body_height * 0.72, flight)
  var width: float = clampf(height * source.x / maxf(source.y, 1.0), 12.0, body_height * 0.48)
  var feather_compress: float = lerpf(1.0, 0.69 + 0.31 * absf(wing_cycle), flight)
  var transform: Transform2D = torso * Transform2D(rotation, Vector2(feather_compress, 1.0), 0.0, shoulder)
  piece(data, Rect2(-width * 0.5, -1.4, width, height), transform, 1.0 if near else 0.84, not near and id in ["clockwork_bird", "twin_bird"])

 func paint_heads() -> void:
  var argument: float = float(a.get("head_disagreement", 0.0))
  for index: int in 2:
   var data: Dictionary = art["head_left" if index == 0 else "head_right"]
   if data.is_empty():
    continue
   var side: float = -1.0 if index == 0 else 1.0
   var height: float = 31.0
   var source: Vector2 = data["size"]
   var width: float = minf(35.0, height * source.x / maxf(source.y, 1.0))
   var angle: float = side * (0.06 + sin(t * 1.8 + index * 2.5) * 0.07 + argument * 0.20)
   var neck: Vector2 = Vector2(side * body_width * 0.22, body_rect.position.y + 7.0)
   var transform: Transform2D = torso * Transform2D(angle, neck + Vector2(0.0, sin(t * 2.1 + index * PI) * 1.2))
   var rect: Rect2 = Rect2(-width * 0.5, -height + 5.0, width, height)
   piece(data, rect, transform)
   paint_blink(data, rect, transform)

 func paint_blink(data: Dictionary, rect: Rect2, transform: Transform2D) -> void:
  if blink < 0.6 or not data.has("eyes"):
   return
  c.draw_set_transform_matrix(transform)
  for eye: Dictionary in data["eyes"]:
   var center: Vector2 = rect.position + eye["center"] * rect.size
   var size: Vector2 = eye["size"] * rect.size * 1.7
   var lid: Color = eye["lid"]
   lid = Color(lid.r * light.r, lid.g * light.g, lid.b * light.b, alpha)
   var eyelid: PackedVector2Array = PackedVector2Array()
   for index: int in 16:
    eyelid.append(center + Vector2(cos(index * TAU / 16.0) * size.x * 0.6, sin(index * TAU / 16.0) * size.y * 0.65))
   c.draw_colored_polygon(eyelid, lid)
   c.draw_line(center - Vector2(size.x * 0.32, 0), center + Vector2(size.x * 0.32, 0.3), Color(0.17 * light.r, 0.19 * light.g, 0.18 * light.b, alpha), 0.9, true)

 func paint_key() -> void:
  var data: Dictionary = art.get("key", {})
  if data.is_empty():
   return
  var windup: float = float(a.get("windup", 0.0))
  var angle: float = t * 0.65 + windup * TAU * 2.0
  var key_size: Vector2 = data["size"]
  var width: float = 24.0
  var height: float = minf(27.0, width * key_size.y / maxf(key_size.x, 1.0))
  var transform: Transform2D = torso * Transform2D(angle, Vector2(-body_width * 0.48, body_rect.position.y + body_height * 0.57))
  piece(data, Rect2(-width * 0.5, -height * 0.5, width, height), transform)

 func paint_shadow() -> void:
  var scale: Vector2 = Vector2(1.0 + sin(t * 1.7) * 0.025, 1.0 + sin(t * 2.2) * 0.035)
  var transform: Transform2D = root * Transform2D(0.0, scale, 0.0, Vector2.ZERO)
  var rect: Rect2 = Rect2(-body_width * 0.5, -body_height, body_width, body_height)
  piece(art["body"], rect, transform)
  # A ground-bound ripple, never a floating ordinary bird silhouette.
  c.draw_set_transform_matrix(root)
  var ripple: float = fposmod(t * 0.28, 1.0)
  c.draw_arc(Vector2(0, -2), 16.0 + ripple * 20.0, 0.05, PI - 0.05, 24, Color(0.23, 0.28, 0.31, alpha * (1.0 - ripple) * 0.12), 0.8, true)

 func paint_special() -> void:
  c.draw_set_transform_matrix(torso)
  var belly: Vector2 = Vector2(0.0, body_rect.position.y + body_height * 0.65)
  match id:
   "dandelion_bird":
    var sneeze: float = pow(maxf(0.0, sin(t * 0.90)), 18.0) * activity
    if sneeze > 0.05:
     for index: int in 4:
      var p: Vector2 = Vector2(body_width * 0.25 + index * 3.0 + sneeze * 12.0, body_rect.position.y + 9.0 - index * 4.0 - sneeze * 7.0)
      var color: Color = Color(0.94 * light.r, 0.93 * light.g, 0.83 * light.b, alpha * sneeze * 0.7)
      c.draw_line(p, p + Vector2(0, 4), color, 0.7, true)
      c.draw_line(p - Vector2(2, 1), p + Vector2(2, 1), color, 0.7, true)
   "cloud_bird":
    for index: int in 3:
     var drop: float = fposmod(t * 0.63 + index * 0.31, 1.0)
     var p: Vector2 = Vector2(-13 + index * 13, -2 + drop * 15)
     c.draw_line(p, p + Vector2(-0.7, 2.4), Color(0.53 * light.r, 0.73 * light.g, 0.77 * light.b, alpha * sin(drop * PI) * 0.45), 1.0, true)
   "yarn_bird":
    var thread: PackedVector2Array = PackedVector2Array()
    for index: int in 12:
     thread.append(Vector2(body_width * 0.35 + index * 1.5, -7.0 + sin(index * 0.7 + t * 2.0) * 1.5))
    c.draw_polyline(thread, Color(0.44 * light.r, 0.55 * light.g, 0.43 * light.b, alpha * 0.7), 1.0, true)
   "alien_bird":
    var scan: float = float(a.get("antenna_scan", 0.5))
    if scan > 0.45:
     var p: Vector2 = Vector2(0.0, body_rect.position.y - 3.0)
     c.draw_arc(p, 4.0 + scan * 6.0, PI * 1.1, PI * 1.9, 16, Color(0.68 * light.r, 0.89 * light.g, 0.65 * light.b, alpha * (scan - 0.45) * 0.55), 0.8, true)
   "invisible_bird":
    if bool(a.get("seed_visible", true)):
     paint_seed(belly + Vector2(sin(t * 1.4) * 1.2, cos(t * 1.1) * 1.3), 0.9)
   "galaxy_bird":
    var orbit: float = float(a.get("orbit_phase", fposmod(t * 0.18, 1.0))) * TAU
    paint_seed(belly + Vector2(cos(orbit) * 10.0, sin(orbit) * 5.0), 0.75 + sin(orbit) * 0.18)
    var glint: Vector2 = belly + Vector2(-9.0, -8.0)
    var shimmer: float = 0.3 + 0.5 * pow(maxf(0.0, sin(t * 2.0)), 8.0)
    var star: Color = Color(0.96 * light.r, 0.87 * light.g, 0.59 * light.b, alpha * shimmer)
    c.draw_line(glint - Vector2(2, 0), glint + Vector2(2, 0), star, 0.8, true)
    c.draw_line(glint - Vector2(0, 2), glint + Vector2(0, 2), star, 0.8, true)
   "crescent_bird":
    var trail: float = 0.5 + 0.5 * sin(t * 1.4)
    var star: Vector2 = Vector2(body_width * 0.4 + 5.0, body_rect.position.y + 7.0)
    c.draw_circle(star, 1.1 + trail * 0.4, Color(light.r, 0.88 * light.g, 0.61 * light.b, alpha * trail * 0.45), true, -1.0, true)

 func paint_seed(center: Vector2, opacity: float) -> void:
  var seed: PackedVector2Array = PackedVector2Array([center + Vector2(-1.9, 0.0), center + Vector2(-0.7, -1.3), center + Vector2(1.8, -0.5), center + Vector2(1.2, 1.1), center + Vector2(-0.8, 1.3)])
  c.draw_colored_polygon(seed, Color(0.82 * light.r, 0.65 * light.g, 0.35 * light.b, alpha * opacity))
