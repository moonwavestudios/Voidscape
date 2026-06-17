extends Node3D

var level = 1

var rng := RandomNumberGenerator.new()

var player_count = 1

var gifts_collected = 0
var all_gifts = 0

var gift_count = 10

var giftScene = preload("res://scenes/gifts.tscn")

var round_started = false

var generated_floors = []

var exit_open = false

var floors = {
	1: [
		preload("res://scenes/world_test.tscn"),
		preload("res://scenes/world_1.tscn"),
		preload("res://scenes/world_2.tscn"),
		preload("res://scenes/world_3.tscn"),
	],
	3: [
		preload("res://scenes/world_4.tscn"),
		preload("res://scenes/world_5.tscn"),
		preload("res://scenes/world_6.tscn"),
		preload("res://scenes/world_7.tscn"),
	],
	5: [
		preload("res://scenes/world_8.tscn"),
	]
}

var threat_scenes = {
	"Bell" = preload("res://scenes/threats/bell.tscn"),
}

func seeded_pick_random(array: Array):
	if array.is_empty():
		return null
	return array[rng.randi() % array.size()]

func seeded_randf() -> float:
	return rng.randf()

func seeded_randf_range(min_val: float, max_val: float) -> float:
	return rng.randf_range(min_val, max_val)
	
func _get_altar(map):
	for child in map.get_children():
		if child.name.to_lower().contains("altar"):
			print("altar available")
			return child
		var result = _get_altar(child)
		if result:
			return result
	return null

func spawn_random_room() -> Node3D:
	var picked_scene = seeded_pick_random(floors.get(level, 1))
	if picked_scene == null:
		push_error("No floors available to spawn")
		return null
	
	var room_instance = picked_scene.instantiate()
	$Maps.add_child(room_instance)
	generated_floors.append(room_instance)
	
	return room_instance

func start_round():
	round_started = true
	var map = _spawn_map()
	$lobby.visible = false
	$Maps.visible = true
	spawn_monsters()
	
	if level > 2:
		var altar = _get_altar(map)
		if altar:
			print("Found altar: ", altar.name)
	
	for players in get_players():
		players.global_position = $Maps/PlayerSpawn.position
		players.get_node("player_ui/GiftsLabel").visible = true

func end_round():
	round_started = false
	remove_maps()
	$lobby.visible = true
	$Maps.visible = false
	$lobby.start_selection()
	
	for players in get_players():
		players.global_position = $lobby/PlayerSpawn.global_position
		players.get_node("player_ui/GiftsLabel").visible = false
		players.gifts = 0

func remove_maps():
	for floor_instance in generated_floors:
		if is_instance_valid(floor_instance):
			floor_instance.queue_free()
	generated_floors.clear()
	all_gifts = 0
	gifts_collected = 0
	exit_open = false
	$Maps/Beacon.visible = false
	$Maps/Beacon/CollisionShape3D.disabled = true

func _spawn_map():
	spawn_random_room()
	
	for gifts in $Maps.get_children():
		if gifts.is_in_group("map"):
			for map in gifts.get_children():
				if map.is_in_group("gifts"):
					all_gifts += 1
	
	return $Maps

func get_players():
	return get_tree().get_nodes_in_group("player")

func spawn_monsters():
	var threats = ActiveModifiers._get_modifier_names("Threats")
	print(threats)
	
	for threat_name in threats:
		if threat_scenes.has(threat_name):
			var instance = threat_scenes[threat_name].instantiate()
			$Maps.add_child(instance)
		else:
			print("No scene found for threat: ", threat_name)

func _process(_delta: float) -> void:
	if gifts_collected == all_gifts and round_started:
		if not exit_open:
			print("exit")
			exit_open = true
			$Maps/Beacon.visible = true
			$Maps/Beacon/CollisionShape3D.disabled = false
	
	for player in get_players():
		gifts_collected = player.gifts
		player.get_node('player_ui/GiftsLabel').text = str(gifts_collected) + "/" + str(all_gifts)

func _on_beacon_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		end_round()
