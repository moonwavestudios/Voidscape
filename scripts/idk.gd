extends Node3D

@onready var game = $".."
var selection_started = false
var pending_selections = 0
var total_selections = 0

func _ready() -> void:
	_populate_slots()
	start_selection()
	$ProximityPrompt.prompt_triggered.connect(func(body): _on_slot_chosen(1, body))
	$ProximityPrompt2.prompt_triggered.connect(func(body): _on_slot_chosen(2, body))
	$ProximityPrompt3.prompt_triggered.connect(func(body): _on_slot_chosen(3, body))
	
	$ProximityPrompt4.prompt_triggered.connect(func(): refresh_slot())

func refresh_slot() -> void:
	if not selection_started:
		return
	_populate_slots()

func _on_slot_chosen(slot_index: int, player: Node = null) -> void:
	if not selection_started:
		return
	var slot = _get_slot(slot_index - 1)
	
	if not slot or not slot.has_meta("mod_name"):
		return
		
	if slot.get_meta("is_skip", false):
		_advance_selection()
		return
		
	var category = slot.get_meta("category")
	var mod_name = slot.get_meta("mod_name")
	var mod_effect = slot.get_meta("mod_effect")
	
	if category == "Buffs":
		var cost = ActiveModifiers.get_buff_cost(mod_name)
		if not player or not ("gifts" in player) or player.gifts < cost:
			return
		player.gifts -= cost
	
	ActiveModifiers._add_modifier(category, mod_name, mod_effect)
	
	for p in get_players():
		var stuff = p.get_node("player_ui/StuffPanel/GridContainer")
		var entity_icon = preload("res://scenes/entity_ui.tscn").instantiate()
		stuff.add_child(entity_icon)
		entity_icon.get_node("TextureRect").texture = ActiveModifiers.get_icon(category, mod_name)
		if category == "Buffs":
			if mod_name.contains("Adrenaline"):
				p.SPEED += 0.5
			elif mod_name.contains("Rings of speed"):
				p.SPEED += 0.75
			elif mod_name.contains("Lower gravity"):
				p.GRAVITY_MULTIPLIER -= 0.2
				
	_advance_selection()

func _advance_selection() -> void:
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
		categories.append("Buffs" if randi() % 2 == 0 else "Curses")
	else:
		categories.append("Threats")
		
	var is_buff_round = categories.has("Buffs")
	var all_options = []
	
	for category in categories:
		var count = 2 if is_buff_round else 3
		var options = ActiveModifiers.get_random_options(category, count)
		for mod_name in options.keys():
			all_options.append({"category": category, "mod_name": mod_name, "mod_effect": options[mod_name]})
	all_options.shuffle()
	
	var option_index = 0
	
	for i in range(3):
		var slot = _get_slot(i)
		
		if not slot:
			continue
			
		if is_buff_round and i == 1:
			slot.set_meta("category", "Skip")
			slot.set_meta("mod_name", "Skip")
			slot.set_meta("mod_effect", "")
			slot.set_meta("is_skip", true)
			slot.get_node("Label3D").text = "Skip"
			slot.texture = null
			continue
		slot.set_meta("is_skip", false)
		
		if option_index < all_options.size():
			slot.set_meta("category", all_options[option_index]["category"])
			slot.set_meta("mod_name", all_options[option_index]["mod_name"])
			slot.set_meta("mod_effect", all_options[option_index]["mod_effect"])
			var label_text = all_options[option_index]["mod_name"]
			if all_options[option_index]["category"] == "Buffs":
				label_text += " (" + str(ActiveModifiers.get_buff_cost(all_options[option_index]["mod_name"])) + " gifts)"
			slot.get_node("Label3D").text = label_text
			slot.texture = ActiveModifiers.get_icon(all_options[option_index]["category"], all_options[option_index]["mod_name"])
			option_index += 1

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
