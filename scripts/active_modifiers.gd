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
	},
	"Buffs" = {
		"Adrenaline": "Increases your speed by 1.5x",
		"Rings of speed": "Increase your speed by 2x",
	},
	"Threats" = {
		"Horse": "Jumps around the map, creating massive shockwaves when landing. just be careful and don't stand still",
		"Bell": "Ringing the bell will throw you into the air, but be careful and don't ring it too many times",
	}
}

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
