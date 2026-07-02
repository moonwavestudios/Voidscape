extends Node3D

@export var dash_speed: float = 20.0
@export var dash_windup: float = 0.8
@export var cooldown: float = 1.5
@export var indicator_color: Color = Color(1.0, 0.2, 0.2, 0.8)

var player: Node3D
var state: String = "idle"
var windup_timer: float = 0.0
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_duration: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var dash_target: Vector3 = Vector3.ZERO

var indicator_mesh: ImmediateMesh
var indicator_instance: MeshInstance3D
var indicator_material: StandardMaterial3D

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	_setup_indicator()
	cooldown = randf_range(1.5, 2.5)

func _setup_indicator() -> void:
	indicator_mesh = ImmediateMesh.new()
	indicator_instance = MeshInstance3D.new()
	indicator_instance.mesh = indicator_mesh
	add_child(indicator_instance)

	indicator_material = StandardMaterial3D.new()
	indicator_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	indicator_material.albedo_color = indicator_color
	indicator_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	indicator_material.vertex_color_use_as_albedo = true
	indicator_instance.material_override = indicator_material

func _process(delta: float) -> void:
	for curses in ActiveModifiers.active_modifiers.get("Curses", {}):
		if curses.contains("I hate you"):
			$AudioStreamPlayer3D.volume_db = -100.0
	
	if not player:
		return

	match state:
		"idle":
			state = "windup"
			windup_timer = 0.0
			dash_target = player.global_position

		"windup":
			windup_timer += delta
			_draw_indicator(dash_target)
			if windup_timer >= dash_windup:
				state = "dashing"
				var dist = global_position.distance_to(dash_target)
				dash_direction = (dash_target - global_position).normalized()
				dash_timer = 0.0
				dash_duration = dist / dash_speed
				indicator_mesh.clear_surfaces()

		"dashing":
			dash_timer += delta
			global_position += dash_direction * dash_speed * delta
			if not $AudioStreamPlayer3D.playing:
				$AudioStreamPlayer3D.play()
			if dash_timer >= dash_duration:
				state = "cooldown"
				cooldown_timer = 0.0

		"cooldown":
			$AudioStreamPlayer3D.stop()
			cooldown_timer += delta
			if cooldown_timer >= cooldown:
				state = "idle"

func _draw_indicator(target: Vector3) -> void:
	var progress = windup_timer / dash_windup
	var alpha = 0.3 + progress * 0.7
	var color_with_alpha = Color(indicator_color.r, indicator_color.g, indicator_color.b, alpha)

	var local_end = to_local(target)
	var local_end_flat = Vector3(local_end.x, 0.1, local_end.z)
	var dir = local_end_flat.normalized()
	var perp = dir.cross(Vector3.UP).normalized() * 0.3
	var tip_back = local_end_flat - dir * 0.5

	indicator_mesh.clear_surfaces()
	indicator_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	indicator_mesh.surface_set_color(color_with_alpha)
	indicator_mesh.surface_add_vertex(Vector3(0, 0.1, 0))
	indicator_mesh.surface_set_color(color_with_alpha)
	indicator_mesh.surface_add_vertex(local_end_flat)

	indicator_mesh.surface_set_color(color_with_alpha)
	indicator_mesh.surface_add_vertex(local_end_flat)
	indicator_mesh.surface_set_color(color_with_alpha)
	indicator_mesh.surface_add_vertex(tip_back + perp)

	indicator_mesh.surface_set_color(color_with_alpha)
	indicator_mesh.surface_add_vertex(local_end_flat)
	indicator_mesh.surface_set_color(color_with_alpha)
	indicator_mesh.surface_add_vertex(tip_back - perp)

	indicator_mesh.surface_end()
