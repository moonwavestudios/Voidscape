extends Node3D

var level = 1

var rng := RandomNumberGenerator.new()

var player_count = 1

var gifts_collected = 0
var all_gifts = 0

var gift_count = 10

var giftScene = preload("res://scenes/gifts.tscn")

var generated_floors = []

var exit_open = false

var floors: Array[PackedScene] = [
	preload("res://scenes/world_test.tscn"),
]

func seeded_pick_random(array: Array):
	if array.is_empty():
		return null
	return array[rng.randi() % array.size()]

func seeded_randf() -> float:
	return rng.randf()

func seeded_randf_range(min_val: float, max_val: float) -> float:
	return rng.randf_range(min_val, max_val)

func spawn_random_room() -> Node3D:
	var picked_scene = seeded_pick_random(floors)
	if picked_scene == null:
		push_error("No fwoors available to spawn! ;-;")
		return null
	
	var room_instance = picked_scene.instantiate()
	add_child(room_instance)
	generated_floors.append(room_instance)
	
	return room_instance

func _ready() -> void:
	spawn_random_room()
	
	for gifts in get_children():
		if gifts.is_in_group("map"):
			for map in gifts.get_children():
				if map.is_in_group("gifts"):
					all_gifts += 1

func get_players():
	return get_tree().get_nodes_in_group("players")

func _process(_delta: float) -> void:
	if gifts_collected == all_gifts:
		if not exit_open:
			print("exit")
			exit_open = true
	
	for player in get_players():
		gifts_collected = player.gifts
