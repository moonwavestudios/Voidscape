extends Area3D
var time := 0.0
var start_y = 0.0

var golden = false
var gold = 15

func _ready() -> void:
	start_y = position.y
	if ActiveModifiers.active_modifiers["Curses"].has("Offset gifts"):
		position.x += randi_range(0,1)
		position.z += randi_range(0,1)

func _process(delta):
	time += delta
	position.y = start_y + sin(time * 2.0) * 0.1
	rotation.y += 0.05

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		if not golden:
			body.gifts += 1
			body.get_node("AudioStreamPlayer3D").play()
			$CPUParticles3D.emitting = true
			$"A Gift Box".visible = false
			$OmniLight3D.visible = false
			$CollisionShape3D.disabled = true
		else:
			body.golden_gifts += gold * body.multiplier
			body.get_node("AudioStreamPlayer3D").play()
			queue_free()
