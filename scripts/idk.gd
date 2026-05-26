extends Node3D

@onready var game = $".."

var selection_started = false

func _ready() -> void:
	$ProximityPrompt.prompt_triggered.connect(_on_interacted)
	$ProximityPrompt2.prompt_triggered.connect(_on_interacted_2)
	$ProximityPrompt3.prompt_triggered.connect(_on_interacted_3)

func _on_interacted(interactor: Node) -> void:
	print("test")

func _on_interacted_2(interactor: Node) -> void:
	if not selection_started:
		selection_started = true
		print(selection_started)
		$ProximityPrompt2.reset_activations()
		_activate_other_prox()
		_activate_all_slots()
	else:
		print("test")

func _on_interacted_3(interactor: Node) -> void:
	print("test")

func _activate_other_prox() -> void:
	for prox in get_children():
		if prox.name.contains("ProximityPrompt"):
			prox.enabled = true

func _activate_all_slots() -> void:
	for slot in get_children():
		if slot.name.contains("slot"):
			slot.visible = true

func _deactivate_other_prox() -> void:
	for prox in get_children():
		if prox.name.contains("ProximityPrompt"):
			prox.enabled = false
