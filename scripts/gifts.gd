extends Area3D


func _on_body_entered(body: Node3D) -> void:
	body.gifts += 1
	print(str(body.gifts))
	queue_free()
