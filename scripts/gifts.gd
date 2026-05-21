extends Area3D

var time := 0.0
var start_y := 1.0

func _process(delta):
	time += delta
	position.y = start_y + sin(time * 2.0) * 0.1

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.gifts += 1
		$"../..".gifts_collected += 1
		queue_free()
