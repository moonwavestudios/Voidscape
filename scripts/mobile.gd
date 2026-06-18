extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("mobile"):
		visible = true

func _on_button_button_down() -> void:
	Input.action_press("ui_accept")
	
func _on_button_button_up() -> void:
	Input.action_release("ui_accept")

func _on_button_2_button_up() -> void:
	Input.action_release("dash")

func _on_button_2_button_down() -> void:
	Input.action_press("dash")
