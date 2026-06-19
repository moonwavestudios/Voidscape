extends Node3D

var jump_timer: float = 0.0
var jump_interval: float = 5.0
var is_jumping: bool = false
var floor_bodies: Array = []

func _ready() -> void:
	await get_tree().process_frame
	_cache_floors()

func _cache_floors() -> void:
	floor_bodies.clear()
	for node in get_tree().get_nodes_in_group(""):
		pass
	var all_nodes = get_tree().root.find_children("floor*", "StaticBody3D", true, false)
	for node in all_nodes:
		floor_bodies.append(node as StaticBody3D)

func _get_random_floor_position() -> Vector3:
	if floor_bodies.is_empty():
		return global_position
	var space = get_world_3d().direct_space_state
	var chosen_floor: StaticBody3D = floor_bodies[randi() % floor_bodies.size()]
	for _i in range(30):
		var aabb = _get_aabb(chosen_floor)
		var x = randf_range(aabb.position.x, aabb.end.x)
		var z = randf_range(aabb.position.z, aabb.end.z)
		var ray_start = Vector3(x, aabb.end.y + 2.0, z)
		var ray_end = Vector3(x, aabb.position.y - 2.0, z)
		var query = PhysicsRayQueryParameters3D.create(ray_start, ray_end)
		var result = space.intersect_ray(query)
		if result and result.collider == chosen_floor:
			return result.position + Vector3(0, 1.2, 0)
	return global_position

func _get_aabb(body: StaticBody3D) -> AABB:
	var combined = AABB()
	var first = true
	for child in body.get_children():
		if child is CollisionShape3D and child.shape != null:
			var shape_aabb = child.shape.get_debug_mesh().get_aabb()
			var world_pos = body.global_position + child.position
			var world_aabb = AABB(world_pos - shape_aabb.size / 2.0, shape_aabb.size)
			if first:
				combined = world_aabb
				first = false
			else:
				combined = combined.merge(world_aabb)
	return combined

func _process(delta: float) -> void:
	if is_jumping:
		return
	jump_timer += delta
	if jump_timer >= jump_interval:
		jump_timer = 0.0
		_do_jump()

func _do_jump() -> void:
	is_jumping = true
	var target = _get_random_floor_position()
	var start = global_position
	var peak_y = max(start.y, target.y) + 12.0
	var duration = 3.0
	var steps = 30

	var tween = create_tween()
	tween.set_parallel(false)

	for i in range(1, steps + 1):
		var t = float(i) / float(steps)
		var xz = start.lerp(target, t)
		var arc_y = lerp(start.y, target.y, t) + sin(t * PI) * (peak_y - max(start.y, target.y))
		tween.tween_property(self, "global_position", Vector3(xz.x, arc_y, xz.z), duration / steps)

	tween.tween_callback(func():
		is_jumping = false
	)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.dead = true
