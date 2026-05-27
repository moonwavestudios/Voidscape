extends Node3D

@onready var game = $".."

var selection_started = false

func _ready() -> void:
	_populate_slots()
	$ProximityPrompt.prompt_triggered.connect(func(_i): _on_slot_chosen(0))
	$ProximityPrompt2.prompt_triggered.connect(func(_i): _on_slot_chosen(1))
	$ProximityPrompt3.prompt_triggered.connect(func(_i): _on_slot_chosen(2))

func _on_slot_chosen(slot_index: int) -> void:
	if not selection_started:
		return
	var slot = _get_slot(slot_index)
	if not slot or not slot.has_meta("mod_name"):
		return
	ActiveModifiers._add_modifier(
		slot.get_meta("category"),
		slot.get_meta("mod_name"),
		slot.get_meta("mod_effect")
	)
	selection_started = false
	_deactivate_other_prox()
	_hide_all_slots()

func _populate_slots() -> void:
	var level = game.level
	var categories = ["Threats"]
	if level % 3 == 0:
		categories.append("Buffs")
		categories.append("Curses")

	var all_options = []
	for category in categories:
		var options = ActiveModifiers.get_random_options(category, 3)
		for mod_name in options.keys():
			all_options.append({"category": category, "mod_name": mod_name, "mod_effect": options[mod_name]})

	for i in range(min(3, all_options.size())):
		var slot = _get_slot(i)
		if not slot:
			continue
		slot.set_meta("category", all_options[i]["category"])
		slot.set_meta("mod_name", all_options[i]["mod_name"])
		slot.set_meta("mod_effect", all_options[i]["mod_effect"])
		slot.get_node("Label3D").text = all_options[i]["mod_name"]

func _get_slot(index: int) -> Node:
	for child in get_children():
		if child.name == "slot" + str(index + 1):
			return child
	return null

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

func _hide_all_slots() -> void:
	for child in get_children():
		if child.name.contains("slot"):
			child.visible = false

func on_slot_chosen(category: String, mod_name: String, mod_effect: String) -> void:
	ActiveModifiers._add_modifier(category, mod_name, mod_effect)
	selection_started = false
	_deactivate_other_prox()
	for slot in get_children():
		if slot.name.contains("slot"):
			slot.visible = false
