extends Node3D

var teleport_timer: float = 0.0
var teleport_interval: float = 10.0
var teleport_radius_min: float = 5.0
var teleport_radius_max: float = 15.0

func _process(delta: float) -> void:
	teleport_timer += delta
	if teleport_timer >= teleport_interval:
		teleport_timer = 0.0
		_teleport_near_player()

func _teleport_near_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	
	var player = players[0]
	var angle = randf() * TAU
	var distance = randf_range(teleport_radius_min, teleport_radius_max)
	var offset = Vector3(cos(angle) * distance, randf_range(-2.0, 4.0), sin(angle) * distance)
	
	global_position = player.global_position + offset
