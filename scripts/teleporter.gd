extends Node3D

var teleport_timer: float = 0.0
var teleport_interval: float = 8.0
var teleport_radius_min: float = 5.0
var teleport_radius_max: float = 15.0
var forward_arc: float = 0.6
var move_speed: float = 2.0

func _process(delta: float) -> void:
	teleport_timer += delta
	if teleport_timer >= teleport_interval:
		teleport_timer = 0.0
		_teleport_near_player()
	_move_towards_player(delta)

func _teleport_near_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var player_forward = -player.global_transform.basis.z
	var random_angle = randf_range(-forward_arc, forward_arc)
	var rotated_dir = player_forward.rotated(Vector3.UP, random_angle)
	var distance = randf_range(teleport_radius_min, teleport_radius_max)
	var offset = rotated_dir * distance
	offset.y = randf_range(-2.0, 4.0)
	global_position = player.global_position + offset
	#$Appear.play()

func _move_towards_player(delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var direction = (player.global_position - global_position).normalized()
	global_position += direction * move_speed * delta
	look_at(player.global_position, Vector3.UP)
