extends Node

var active_modifiers = {
	"Curses" = {
		
	},
	"Buffs" = {
		
	},
	"Threats" = {
		
	},
	"Altar" = [
		
	]
}

var all_modifiers = {
	"Curses" = {
		"Angry horse": "Shockwaves are bigger, the horse also creates shockwaves when jumping",
		"Sike": "Teleporter has a chance to teleport behind you",
		"Random Spawn": "Spawn location is randomized",
		"I hate you": "Rusher no longer gives a sound indicator",
		"Lower gravity": "You think that'd be helpful",
		"Offset gifts": "Gifts are offset by a random amount",
		"More altars": "More altars spawn",
	},
	"Buffs" = {
		"Adrenaline": "Increases your speed by 0.5x",
		"Rings of speed": "Increase your speed by 0.75x",
		"Shield": "Protects you from getting hit once",
		"Gift magnet": "Brings the gifts close to you closer to you",
	},
	"Altar" = [
		"Walkspeed x1.5",
		"Gift yield +0.75x",
		"Shield for all",
	],
	"Threats" = {
		"Horse": "Jumps around the map, creating massive shockwaves when landing. just be careful and don't stand still",
		"Bell": "Ringing the bell will throw you into the air, but be careful and don't ring it too many times",
		"Rusher": "Goober will try to dash towards you with a loud noise and an indicator. don't get hit",
		"Teleporter": "He will teleport in front of you with a sound indicator. Just go the other way once he does.",
		"Someone": {
			"description": "Don't move when he looks at you.",
			"min_level": 1
		}, 
		"Nuke": {
			"description": "Follows the player before exploding",
			"min_level": 1
		}
	}
}

var threat_icons = {
	"Threats" = {
		"Horse": preload("res://assets/images/horse.png"),
		"Bell": preload("res://assets/images/bell.png"),
		"Rusher": preload("res://assets/images/rusher.png"),
		"Teleporter": preload("res://assets/images/teleporter.png"),
		"Someone": preload("res://assets/images/someone.png"),
	},
	"Buffs" = {
		"Adrenaline": preload("res://assets/images/adrenaline.png"),
		"Rings of speed": preload("res://assets/images/speed rings.png"),
		"Shield": preload("res://icon.png"),
		"Gift magnet": preload("res://icon.png"),
	},
	"Curses" = {
		"Lower gravity": preload("res://assets/images/lower grav.png"),
		"Sike": preload("res://assets/images/teleporter.png"),
		"Random Spawn": preload("res://assets/images/spawn.png"),
	},
}

var buff_costs = {
	"Adrenaline": 50,
	"Rings of speed": 55,
	"Gift magnet": 150,
	"Shield": 1000,
}

func get_buff_cost(modifier_name: String) -> int:
	return buff_costs.get(modifier_name, 0)

func get_random_options(modifier_type: String, current_level: int, count: int = 3):
	if not all_modifiers.has(modifier_type):
		return []
	
	var pool = all_modifiers[modifier_type].duplicate()
	
	if pool is Array:
		pool.shuffle()
		return pool.slice(0, min(count, pool.size()))
	
	var available = {}
	
	for modifier_name in pool.keys():
		var modifier_data = pool[modifier_name]
		var min_level = modifier_data.get("min_level", 1)
		
		if current_level >= min_level:
			available[modifier_name] = modifier_data.get("description", "")
	
	var keys = available.keys()
	keys.shuffle()
	
	var result = {}
	for i in range(min(count, keys.size())):
		result[keys[i]] = available[keys[i]]
	
	return result

func get_icon(modifier_type: String, modifier_name: String):
	if threat_icons.has(modifier_type) and threat_icons[modifier_type].has(modifier_name):
		return threat_icons[modifier_type][modifier_name]
	return null

func _add_modifier(modifier_type: String, modifier_name: String, modifier_effect: String = "") -> void:
	if active_modifiers.has(modifier_type):
		if active_modifiers[modifier_type] is Array:
			active_modifiers[modifier_type].append(modifier_name)
		else:
			active_modifiers[modifier_type][modifier_name] = modifier_effect
	else:
		print("Invalid modifier type: " + modifier_type)

func _remove_modifier(modifier_type: String, modifier_name: String) -> void:
	if active_modifiers.has(modifier_type):
		if active_modifiers[modifier_type] is Array:
			active_modifiers[modifier_type].erase(modifier_name)
		else:
			active_modifiers[modifier_type].erase(modifier_name)
	else:
		print("Invalid modifier type: " + modifier_type)

func _get_modifier_names(modifier_type: String) -> Array:
	if active_modifiers.has(modifier_type):
		if active_modifiers[modifier_type] is Array:
			return active_modifiers[modifier_type]
		return active_modifiers[modifier_type].keys()
	else:
		print("Invalid modifier type: " + modifier_type)
		return []

func _get_modifiers(modifier_type: String) -> Dictionary:
	if active_modifiers.has(modifier_type):
		return active_modifiers[modifier_type]
	else:  
		print("Invalid modifier type: " + modifier_type)
		return {}

func _clear_modifiers(modifier_type: String) -> void:
	if active_modifiers.has(modifier_type):
		active_modifiers[modifier_type].clear()
	else: 
		print("Invalid modifier type: " + modifier_type)
