extends Node3D

func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)
	
func _on_interacted(interactor: Node) -> void:
	var modifier = ActiveModifiers.get_random_options("Altar", 1)
	ActiveModifiers._add_modifier("Altar", modifier, "")
	
	for altar in ActiveModifiers.active_modifiers.get("Altar", []):
			if altar.contains("Walkspeed x1.5"):
				interactor.SPEED *= 1.5
