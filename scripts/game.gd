extends Node3D

var level = 1

var gifts_collected = 0
var all_gifts = 0

var exit_open = false

func _ready() -> void:
	#$FloorGeneration.generate(level) 
	for gifts in get_children():
		if gifts.is_in_group("gifts"):
			all_gifts += 1
			print(all_gifts)

func _process(_delta: float) -> void:
	if gifts_collected == all_gifts:
		if not exit_open:
			print("exit")
			exit_open = true
