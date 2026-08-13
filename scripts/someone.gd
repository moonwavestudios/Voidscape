extends Node3D

var teleport_timer: float = 0.0
var teleport_interval: float = 15.0
var someone_timer: float = 0.0
var someone_active: bool = false
var player_was_moving: bool = false
var shake_original_pos: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	teleport_timer += delta
	if teleport_timer >= teleport_interval:
		teleport_timer = 0.0
		_teleport_near_player()

	if someone_active:
		var players = get_tree().get_nodes_in_group("player")
		if players.is_empty():
			return
		var player = players[0]
		var someone = player.get_node('player_ui/Someone')

		var input_dir = Vector2(
			Input.get_axis("ui_left", "ui_right"),
			Input.get_axis("ui_up", "ui_down")
		)
		var is_moving = input_dir.length() > 0.1

		if is_moving:
			player_was_moving = true
			someone_timer += delta
			var shake_x = randf_range(-4.0, 4.0)
			var shake_y = randf_range(-4.0, 4.0)
			someone.position = shake_original_pos + Vector2(shake_x, shake_y)
			if someone_timer >= 5.0:
				someone_active = false
				someone_timer = 0.0
				someone.visible = false
				someone.position = shake_original_pos
				if player.has_shield:
					player.has_shield = false
				else:
					player.dead = true
		else:
			someone.position = shake_original_pos
			if player_was_moving:
				someone_timer = 0.0
				player_was_moving = false
			someone_timer += delta
			if someone_timer >= 1.0:
				someone_active = false
				someone_timer = 0.0
				someone.visible = false

func _teleport_near_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var player = players[0]
	var someone = player.get_node('player_ui/Someone')
	shake_original_pos = someone.position
	someone.visible = true
	someone_active = true
	someone_timer = 0.0
	player_was_moving = false
