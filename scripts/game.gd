extends Node3D

var level = 1

var player_count = 1

var gifts_collected = 0
var all_gifts = 0

var gift_count = 10

var giftScene = preload("res://scenes/gifts.tscn")

var exit_open = false

func _ready() -> void:
	for gifts in get_children():
		if gifts.is_in_group("gifts"):
			all_gifts += 1
			print(all_gifts)
	
	for floors in get_children():
		if floors.is_in_group("map"):
			for floore in floors.get_children():
				if floore.name.contains("floor"):
					var gift = giftScene.instantiate()
					add_child(gift)
					gift.position = floore.position + Vector3(0, 1, 0)

func _process(_delta: float) -> void:
	if gifts_collected == all_gifts:
		if not exit_open:
			print("exit")
			exit_open = true
