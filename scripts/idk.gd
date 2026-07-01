extends Node3D
@onready var game = $".."
var selection_started = false
var pending_selections = 0
var total_selections = 0

func _ready() -> void:
	_populate_slots()
	start_selection()
	$ProximityPrompt.prompt_triggered.connect(func(_i): _on_slot_chosen(1))
	$ProximityPrompt2.prompt_triggered.connect(func(_i): _on_slot_chosen(2))
	$ProximityPrompt3.prompt_triggered.connect(func(_i): _on_slot_chosen(3))

func _on_slot_chosen(slot_index: int) -> void:
	if not selection_started:
		return
	var slot = _get_slot(slot_index - 1)
	if not slot or not slot.has_meta("mod_name"):
		return

	var category = slot.get_meta("category")
	var mod_name = slot.get_meta("mod_name")
	var mod_effect = slot.get_meta("mod_effect")

	ActiveModifiers._add_modifier(category, mod_name, mod_effect)

	for player in get_players():
		var stuff = player.get_node("player_ui/StuffPanel/GridContainer")
		var entity_icon = preload("res://scenes/entity_ui.tscn").instantiate()
		stuff.add_child(entity_icon)
		entity_icon.get_node("TextureRect").texture = ActiveModifiers.get_icon(category, mod_name)

	pending_selections -= 1
	if pending_selections <= 0:
		selection_started = false
		_deactivate_other_prox()
		_hide_all_slots()
		start_round()
	else:
		_activate_other_prox()
		_populate_slots()

func get_players():
	return get_tree().get_nodes_in_group("player")

func _populate_slots() -> void:
	var level = game.level
	var categories = []
	var pick_number = total_selections - pending_selections + 1
	if level % 3 == 0 and pick_number >= 2:
		categories.append("Buffs")
		categories.append("Curses")
	else:
		categories.append("Threats")
	var all_options = []
	for category in categories:
		var options = ActiveModifiers.get_random_options(category, 3)
		for mod_name in options.keys():
			all_options.append({"category": category, "mod_name": mod_name, "mod_effect": options[mod_name]})
	all_options.shuffle()
	for i in range(min(3, all_options.size())):
		var slot = _get_slot(i)
		if not slot:
			continue
		slot.set_meta("category", all_options[i]["category"])
		slot.set_meta("mod_name", all_options[i]["mod_name"])
		slot.set_meta("mod_effect", all_options[i]["mod_effect"])
		slot.get_node("Label3D").text = all_options[i]["mod_name"]
		slot.texture = ActiveModifiers.get_icon(all_options[i]["category"], all_options[i]["mod_name"])

func _get_slot(index: int) -> Node:
	for child in get_children():
		if child.name == "slot" + str(index + 1):
			return child
	return null

func _activate_other_prox() -> void:
	for prox in get_children():
		if prox.name.contains("ProximityPrompt"):
			prox.reset_activations()
			prox.enabled = true

func start_selection() -> void:
	var level = game.level
	pending_selections = 2 if level % 3 == 0 else 1
	total_selections = pending_selections
	selection_started = true
	_activate_other_prox()
	_activate_all_slots()
	_populate_slots()

func _activate_all_slots() -> void:
	for slot in get_children():
		if slot.name.contains("slot"):
			slot.visible = true

func _deactivate_other_prox() -> void:
	for prox in get_children():
		if prox.name.contains("ProximityPrompt"):
			prox.enabled = false

func start_round():
	$"..".start_round()

func _hide_all_slots() -> void:
	for child in get_children():
		if child.name.contains("slot"):
			child.visible = false
