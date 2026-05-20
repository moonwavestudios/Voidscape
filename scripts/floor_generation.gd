class_name FloorGenerator
extends Node3D
 
# ── Tunables ───────────────────────────────────────────────────────────────── #
 
@export var level: int = 1
@export var platform_count: int = 8
@export var stair_count:    int = 4
 
## Platform slab dimensions
@export var platform_size: Vector3 = Vector3(10.0, 0.5, 10.0)
 
## Each individual stair step
@export var step_width:  float = 3.0   ## X size (perpendicular to travel)
@export var step_depth:  float = 1.2   ## Z size (along travel direction)
@export var step_height: float = 0.4   ## Y rise per step
 
## Horizontal spread: radius = base + growth × (level - 1)
@export var base_radius:         float = 14.0
@export var level_radius_growth: float = 6.0
 
## Vertical range (above/below y = 0)
@export var base_height_range:         float = 4.0
@export var level_height_range_growth: float = 2.0
 
@export var floor_material: Material
@export var stair_material: Material
 
## Minimum gap between platform centres (avoids overlap)
@export var min_platform_gap: float = 12.0
 
# ── Runtime ────────────────────────────────────────────────────────────────── #
 
var _rng              := RandomNumberGenerator.new()
var _placed_centers   : Array[Vector3] = []


func generate(p_level: int = level, p_seed: int = -1) -> void:
	level = p_level
	_clear_generated()
	_placed_centers.clear()
 
	if p_seed >= 0:
		_rng.seed = p_seed
	else:
		_rng.randomize()
 
	var radius      := base_radius       + level_radius_growth       * (level - 1)
	var half_height := base_height_range + level_height_range_growth * (level - 1)
 
	_spawn_platforms(platform_count, radius, half_height)
	_spawn_stairs   (stair_count)


# ── Internal ───────────────────────────────────────────────────────────────── #

func _clear_generated() -> void:
	for child in get_children():
		if child.is_in_group("generated"):
			child.queue_free()


func _spawn_platforms(count: int, radius: float, half_height: float) -> void:
	var budget  := count * 20
	var spawned := 0
 
	while spawned < count and budget > 0:
		budget -= 1
		var pos := _random_disc_point(radius, half_height)
		if not _too_close(pos):
			_placed_centers.append(pos)
			_make_platform(pos)
			spawned += 1
 
 
func _spawn_stairs(count: int) -> void:
	if _placed_centers.size() < 2:
		return
 
	# Shuffle indices and pair them up; each pair gets one staircase.
	var indices: Array = range(_placed_centers.size())
	indices.shuffle()
 
	var built := 0
	var i     := 0
 
	while built < count and i + 1 < indices.size():
		_make_staircase(
			_placed_centers[indices[i]],
			_placed_centers[indices[i + 1]]
		)
		built += 1
		i     += 2
 
	# If we still need more, link the centre to remaining platforms.
	while built < count and built < _placed_centers.size():
		_make_staircase(Vector3.ZERO, _placed_centers[built])
		built += 1
 
 
# ── Geometry ───────────────────────────────────────────────────────────────── #
 
func _make_platform(pos: Vector3) -> void:
	var mi   := MeshInstance3D.new()
	mi.add_to_group("generated")
	mi.position = pos
	var box  := BoxMesh.new()
	box.size  = platform_size
	mi.mesh   = box
	if floor_material:
		mi.material_override = floor_material
	add_child(mi)
	_attach_box_collision(mi, platform_size)
 
 
func _make_staircase(from_center: Vector3, to_center: Vector3) -> void:
	## Builds a staircase that walks FROM the top surface of platform A
	## TO the top surface of platform B, going either up or down correctly.
 
	# Top surface Y of each platform.
	var y_from := from_center.y + platform_size.y * 0.5
	var y_to   := to_center.y   + platform_size.y * 0.5
 
	# Horizontal direction (flat, normalized).
	var flat_diff := Vector3(
		to_center.x - from_center.x,
		0.0,
		to_center.z - from_center.z
	)
	var flat_dist := flat_diff.length()
 
	if flat_dist < 0.001:
		return   # platforms directly on top of each other — skip
 
	var dir_flat := flat_diff / flat_dist   # unit vector along ground
 
	# How many steps do we need to cover the height difference?
	var height_diff := y_to - y_from        # positive = going UP, negative = DOWN
	var steps_needed := int(ceil(abs(height_diff) / step_height))
	steps_needed = max(steps_needed, 1)
 
	# Actual rise per step (preserves sign: + = up, - = down).
	var rise_per_step := height_diff / float(steps_needed)
 
	# Horizontal travel per step (spread evenly).
	var run_per_step := (flat_dist - platform_size.z) / float(steps_needed)
	run_per_step = max(run_per_step, step_depth)
 
	# Build steps from the FROM platform edge outward.
	# The first step sits flush against the FROM platform top surface.
	var half_plat_depth := platform_size.z * 0.5
 
	for s in steps_needed:
		# Centre of this step along the travel axis.
		var along := half_plat_depth + step_depth * 0.5 + run_per_step * s
 
		# Horizontal world position.
		var world_xz := Vector3(from_center.x, 0.0, from_center.z) + dir_flat * along
 
		# Y: step s sits at y_from + rise accumulated so far.
		# We place the TOP surface at that height, so box centre is half step_height below.
		var top_y    := y_from + rise_per_step * (s + 1)
		var center_y := top_y - step_height * 0.5
 
		var mi       := MeshInstance3D.new()
		mi.add_to_group("generated")
		mi.position   = Vector3(world_xz.x, center_y, world_xz.z)
 
		# Rotate so step depth faces the direction of travel.
		mi.look_at(mi.position + dir_flat, Vector3.UP)
 
		var box  := BoxMesh.new()
		box.size  = Vector3(step_width, step_height, step_depth)
		mi.mesh   = box
		mi.material_override = stair_material if stair_material else floor_material
		add_child(mi)
		_attach_box_collision(mi, Vector3(step_width, step_height, step_depth))
 
 
func _attach_box_collision(parent: Node3D, size: Vector3) -> void:
	var body   := StaticBody3D.new()
	var cshape := CollisionShape3D.new()
	var box    := BoxShape3D.new()
	box.size    = size
	cshape.shape = box
	body.add_child(cshape)
	parent.add_child(body)
 
 
# ── Utilities ─────────────────────────────────────────────────────────────── #
 
func _random_disc_point(radius: float, half_height: float) -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var dist  := sqrt(_rng.randf()) * radius
	return Vector3(
		cos(angle) * dist,
		_rng.randf_range(-half_height, half_height),
		sin(angle) * dist
	)
 
 
func _too_close(pos: Vector3) -> bool:
	for p in _placed_centers:
		if p.distance_to(pos) < min_platform_gap:
			return true
	return false
