extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		body.gifts += 1
		$"..".gifts_collected += 1
		print(str(body.gifts))
		queue_free()
