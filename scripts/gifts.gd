extends Area3D
var time := 0.0
var start_y = 0.0

var golden = false

func _ready() -> void:
	start_y = position.y

func _process(delta):
	time += delta
	position.y = start_y + sin(time * 2.0) * 0.1
	rotation.y += 0.05

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.gifts += 1
		body.get_node("AudioStreamPlayer3D").play()
		#queue_free()
		visible = false
		$CollisionShape3D.disabled = true
