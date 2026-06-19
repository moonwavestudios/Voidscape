extends Node3D

var teleport_timer: float = 0.0
var teleport_interval: float = 15.0

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
	player.get_node('player_ui/Someone').visible = true
	#$Appear.play()
