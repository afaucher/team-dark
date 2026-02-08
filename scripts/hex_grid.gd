extends RefCounted

# Hexagon size (radius)
const HEX_SIZE = 128.0
# Height of a single step
const HEIGHT_STEP = 16.0

# Axial coordinates (q, r)
var q: int
var r: int
var height: int = 0

func _init(_q: int, _r: int, _height: int = 0):
	q = _q
	r = _r
	height = _height

# Convert Axial to World Position
static func axial_to_pixel(q: int, r: int) -> Vector2:
	var x = HEX_SIZE * (3.0/2.0 * q)
	var y = HEX_SIZE * (sqrt(3.0)/2.0 * q + sqrt(3.0) * r)
	return Vector2(x, y)

# Convert World Position to Axial (Rounding)
static func pixel_to_axial(point: Vector2) -> Vector2i:
	var q = (2.0/3.0 * point.x) / HEX_SIZE
	var r = (-1.0/3.0 * point.x + sqrt(3.0)/3.0 * point.y) / HEX_SIZE
	return _axial_round(q, r)

static func _axial_round(q: float, r: float) -> Vector2i:
	var s = -q - r
	var rq = round(q)
	var rr = round(r)
	var rs = round(s)

	var q_diff = abs(rq - q)
	var r_diff = abs(rr - r)
	var s_diff = abs(rs - s)

	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	
	return Vector2i(rq, rr)

# Get all 6 neighbors
static func get_neighbors(q: int, r: int) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	var directions = [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1)
	]
	for dir in directions:
		neighbors.append(Vector2i(q + dir.x, r + dir.y))
	return neighbors

func get_world_position() -> Vector2:
	return axial_to_pixel(q, r)
