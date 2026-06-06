extends Node

var active_modifiers = {
	"Curses" = {
		
	},
	"Buffs" = {
		
	},
	"Threats" = {
		
	}
}

var all_modifiers = {
	"Curses" = {
		"Angry horse": "Shockwaves are bigger, the horse also creates shockwaves when jumping",
		"Sike": "Teleporter has a chance to teleport behind you",
		"Green light": "Someone has a chance to close his eyes, if he does, move",
	},
	"Buffs" = {
		"Adrenaline": "Increases your speed by 1.5x",
		"Rings of speed": "Increase your speed by 2x",
		"Lower Gravity": "You think that'd be helpful",
	},
	"Threats" = {
		"Horse": "Jumps around the map, creating massive shockwaves when landing. just be careful and don't stand still",
		"Bell": "Ringing the bell will throw you into the air, but be careful and don't ring it too many times",
		"Goober": "Goober will try to dash towards you with a loud noise and an indicator. don't get hit",
		"Teleporter": "He will teleport in front of you with a sound indicator. Just go the other way once he does.",
		"Someone": "Don't move when he looks at you."
	}
}

func get_random_options(modifier_type: String, count: int = 3) -> Dictionary:
	if not all_modifiers.has(modifier_type):
		return {}
	var pool = all_modifiers[modifier_type].duplicate()
	for key in active_modifiers[modifier_type].keys():
		pool.erase(key)
	var result = {}
	var keys = pool.keys()
	keys.shuffle()
	for i in range(min(count, keys.size())):
		result[keys[i]] = pool[keys[i]]
	return result

func _add_modifier(modifier_type: String, modifier_name: String, modifier_effect: String) -> void:
	if active_modifiers.has(modifier_type):
		active_modifiers[modifier_type][modifier_name] = modifier_effect
	else:
		print("Invalid modifier type: " + modifier_type)

func _remove_modifier(modifier_type: String, modifier_name: String) -> void:
	if active_modifiers.has(modifier_type):
		active_modifiers[modifier_type].erase(modifier_name)
	else:
		print("Invalid modifier type: " + modifier_type)

func _get_modifier_names(modifier_type: String) -> Array:
	if active_modifiers.has(modifier_type):
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
