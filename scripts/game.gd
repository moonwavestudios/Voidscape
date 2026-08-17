extends Node3D

var level = 1

var rng := RandomNumberGenerator.new()

var destroyParticleScene = preload("res://scenes/destroy_particle.tscn")
var destroyMaterial = preload("res://materials/destroyed_floor.tres")

# -------------- For the rewrite --------------
var floor_scenes = {
	"straight_floor" = preload("res://scenes/floors/floorA.tscn"),
	"end_floor_with_platform" = preload("res://scenes/floors/floorB.tscn"),
	"stairs" = preload("res://scenes/floors/floorD.tscn")
}

const SPAWN_DIRECTIONS := {
	"LeftSpawn" = Vector3.LEFT,
	"RightSpawn" = Vector3.RIGHT,
	"ForwardSpawn" = Vector3.FORWARD,
	"BackSpawn" = Vector3.BACK,
}

# ---------------------------------------------

var difficulty = "standard"

var floor_destruction_delay = 5.0
var floor_destruction_stagger = 1.5

var player_count = 1

var gifts_collected = 0
var all_gifts = 0

var gift_count = 10

var gameover = false

var giftScene = preload("res://scenes/gifts.tscn")
var tripmineScene = preload("res://scenes/tripmine.tscn")
var tripmine_chance = 0.1

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
		preload("res://scenes/world_9.tscn"),
		preload("res://scenes/world_10.tscn"),
		preload("res://scenes/world_11.tscn"),
		preload("res://scenes/world_12.tscn"),
	],
}

var threat_scenes = {
	"Bell" = preload("res://scenes/threats/bell.tscn"),
	"Horse" = preload("res://scenes/threats/horse.tscn"),
	"Teleporter" = preload("res://scenes/threats/teleporter.tscn"),
	"Someone" = preload("res://scenes/threats/someone.tscn"),
	"Rusher" = preload("res://scenes/threats/goober.tscn"),
}

func seeded_pick_random(array: Array):
	if array.is_empty():
		return null
	return array[rng.randi() % array.size()]

func seeded_randf() -> float:
	return rng.randf()

func seeded_randf_range(min_val: float, max_val: float) -> float:
	return rng.randf_range(min_val, max_val)

func _find_mesh_instances(node: Node) -> Array:
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result

func _get_floor_pieces(world_instance: Node3D) -> Array:
	var pieces = []
	for child in world_instance.get_children():
		if child.name.to_lower().begins_with("floor"):
			pieces.append(child)
	return pieces

func _destroy_pieces_sequentially(pieces: Array) -> void:
	if pieces.is_empty():
		return
	var piece = pieces.pop_front()
	if not is_instance_valid(piece):
		_destroy_pieces_sequentially(pieces)
		return
	
	var particles = destroyParticleScene.instantiate()
	piece.add_child(particles)
	
	for mesh_instance in _find_mesh_instances(piece):
		mesh_instance.material_override = destroyMaterial
	
	get_tree().create_timer(floor_destruction_delay).timeout.connect(func():
		if is_instance_valid(piece):
			piece.queue_free()
		_destroy_pieces_sequentially(pieces)
	)

func _start_floor_destruction() -> void:
	var pieces = []
	for world_instance in generated_floors:
		pieces.append_array(_get_floor_pieces(world_instance))
	pieces.shuffle()
	_destroy_pieces_sequentially(pieces)

func _get_altar(map):
	for child in map.get_children():
		if child.name.to_lower().contains("altar"):
			print("altar available")
			return child
		var result = _get_altar(child)
		if result:
			return result
	return null

func _get_floor_pool() -> Array:
	var best_key = 1
	for key in floors.keys():
		if level >= key:
			best_key = key
	return floors[best_key]

func _place_floor_piece(scene: PackedScene, target_position: Vector3, target_basis: Basis, parent: Node3D) -> Node3D:
	var piece = scene.instantiate()
	parent.add_child(piece)
	var start_marker: Marker3D = piece.get_node("Start_Pos")
	var local_offset = start_marker.position
	var rotated_offset = target_basis * local_offset
	var t = piece.global_transform
	t.basis = target_basis
	t.origin = target_position - rotated_offset
	piece.global_transform = t
	return piece

func _generate_corridor(spawn_marker: Marker3D, length: int) -> void:
	var local_dir = SPAWN_DIRECTIONS.get(spawn_marker.name, Vector3.FORWARD)
	var world_dir = ($Maps/middle.global_transform.basis * local_dir).normalized()
	var corridor_basis = Basis.looking_at(world_dir, Vector3.UP)
	var current_position = spawn_marker.global_position
	for i in range(length):
		var piece = _place_floor_piece(floor_scenes["straight_floor"], current_position, corridor_basis, $Maps)
		generated_floors.append(piece)
		var end_marker: Marker3D = piece.get_node("End_Pos")
		current_position = end_marker.global_position

func _generate_corridors_from_middle() -> void:
	for spawns in $Maps/middle.get_children():
		if spawns is Marker3D:
			var length = rng.randi_range(3, 6)
			_generate_corridor(spawns, length)

func spawn_random_room() -> Node3D:
	var picked_scene = seeded_pick_random(_get_floor_pool())
	if picked_scene == null:
		push_error("No floors available to spawn")
		return null
		
	_generate_corridors_from_middle()
	
	var room_instance = picked_scene.instantiate()
	$Maps.add_child(room_instance)
	room_instance.global_position.y += 5
	generated_floors.append(room_instance)
	
	return room_instance

func activate_golden_gifts():
	for gifts in $Maps.get_children():
		if gifts.is_in_group("map"):
			for map in gifts.get_children():
				if map.is_in_group("gifts"):
					map.get_node("A Gift Box").visible = false
					map.get_node("Gold_Gift").visible = true
					map.get_node("OmniLight3D").visible = false
					map.get_node("gold_light").visible = true
					map.visible = true
					map.golden = true
					map.get_node("CollisionShape3D").disabled = false

func start_round():
	round_started = true
	var map = _spawn_map()
	$lobby.visible = false
	$Maps.visible = true
	$"../Game".play()
	$"../Intermission".stop()
	
	if level > 2:
		var altar = _get_altar(map)
		if altar:
			print("Found altar: ", altar.name)
	
	for players in get_players():
		players.global_position = $Maps/PlayerSpawn.position
		players.get_node("player_ui/GiftsLabel").visible = true
		
		for buffs in ActiveModifiers.active_modifiers.get("Buffs", {}):
			if buffs.contains("Shield"):
				players.has_shield = true
				players.get_node("shield_a").visible = true
	
	get_tree().create_timer(3.0).timeout.connect(spawn_monsters)

func end_round():
	round_started = false
	remove_maps()
	clear_monsters()
	level += 1
	$lobby.visible = true
	$Maps.visible = false
	$lobby.start_selection()
	$"../Game".stop()
	$"../Intermission".play()
	
	ActiveModifiers._clear_modifiers("Altar")
	
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

func _delayed_spawn_monsters():
	if round_started:
		spawn_monsters()

func _spawn_map():
	spawn_random_room()
	
	for gifts in $Maps.get_children():
		if gifts.is_in_group("map"):
			for map in gifts.get_children():
				if map.is_in_group("gifts"):
					all_gifts += 1
	
	if level >= 5:
		_replace_gifts_with_tripmines()
	
	return $Maps

func _swap_gift_for_tripmine(gift: Node3D) -> void:
	var pos = gift.global_position
	gift.queue_free()
	all_gifts -= 1
	var tripmine = tripmineScene.instantiate()
	$Maps.add_child(tripmine)
	tripmine.global_position = pos

func reset_game():
	level = 1
	gifts_collected = 0
	all_gifts = 0
	gameover = false
	exit_open = false
	round_started = false
	
	ActiveModifiers._clear_modifiers("Curses")
	ActiveModifiers._clear_modifiers("Buffs")
	ActiveModifiers._clear_modifiers("Threats")
	ActiveModifiers._clear_modifiers("Altar")
	
	remove_maps()
	clear_monsters()
	
	$lobby.visible = true
	$Maps.visible = false
	$lobby.start_selection()
	$"../GameOver".stop()
	$"../Intermission".play()
	
	for player in get_players():
		player.dead = false
		player.gifts = 0
		player.global_position = $lobby/PlayerSpawn.global_position
		player.get_node("player_ui/GameOver").visible = false
		player.get_node("player_ui/GiftsLabel").visible = false
		var grid = player.get_node("player_ui/StuffPanel/GridContainer")
		for child in grid.get_children():
			child.queue_free()

func _replace_gifts_with_tripmines() -> void:
	for map_node in $Maps.get_children():
		if not map_node.is_in_group("map"):
			continue
		for child in map_node.get_children():
			if child.is_in_group("gifts") and seeded_randf() < tripmine_chance:
				_swap_gift_for_tripmine(child)

func get_players():
	return get_tree().get_nodes_in_group("player")

func spawn_monsters():
	var threats = ActiveModifiers._get_modifier_names("Threats")
	var threat_counts := {}
	for threat_name in threats:
		threat_counts[threat_name] = threat_counts.get(threat_name, 0) + 1
	
	for threat_name in threat_counts.keys():
		if not threat_scenes.has(threat_name):
			print("No scene found for threat: ", threat_name)
			continue
		var count = threat_counts[threat_name]
		for i in range(count):
			var instance = threat_scenes[threat_name].instantiate()
			$Maps.add_child(instance)
			instance.add_to_group("threats")
			var spawn_pos = $Maps/middle.global_position
			spawn_pos.z += 10 + i * 2
			instance.global_position = spawn_pos

func clear_monsters() -> void:
	for threat in get_tree().get_nodes_in_group('threats'):
		threat.queue_free()

func _process(_delta: float) -> void:
	if gifts_collected == all_gifts and round_started:
		if not exit_open:
			print("exit")
			exit_open = true
			$Maps/Beacon.visible = true
			$Maps/Beacon/CollisionShape3D.disabled = false
			activate_golden_gifts()
			_start_floor_destruction()
			
	if level >= 15:
		$DirectionalLight3D.light_color = Color(0.904, 0.001, 0.904, 1.0)
	
	for player in get_players():
		gifts_collected = player.gifts
		player.get_node('player_ui/GiftsLabel').text = str(gifts_collected) + "/" + str(all_gifts)
		player.get_node("player_ui/LevelLabel").text = "Level:" + str(level)
		player.get_node("player_ui/GameOver/Label3").text = "High score: " + str(level)
		
		if player.dead and not gameover:
			gameover = true
			$"../GameOver".play()
			$"../Game".stop()
			$"../Intermission".stop()

func _on_beacon_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		end_round()
