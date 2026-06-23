extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.008
var pitch: float = 0.0
@onready var camera: Camera3D = $Camera3D
@onready var joystick: VirtualJoystick = $player_ui/Mobile/VirtualJoystick
var gifts = 0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const DASH_FORCE = 50.0
var dead = false
var has_air_dashed = false
var camera_touch_index: int = -1

func _ready() -> void:
	floor_snap_length = 0.3
	floor_max_angle = deg_to_rad(50)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$player_ui/GameOver/RetryButton.pressed.connect(_on_retry_pressed)

func _on_retry_pressed():
	$"../game".reset_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		has_air_dashed = false

	if dead:
		$player_ui/GameOver.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	var jumped := false
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jumped = true

	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if Input.is_action_just_pressed("dash") and not is_on_floor() and not has_air_dashed:
		var dash_dir := direction if input_dir != Vector2.ZERO else -transform.basis.z
		velocity.x = dash_dir.x * DASH_FORCE
		velocity.z = dash_dir.z * DASH_FORCE
		has_air_dashed = true
		move_and_slide()
		return

	if position.y <= -10 and not dead:
		position = Vector3(0, 15, 0)
		dead = true

	if direction:
		if is_on_floor() and not jumped:
			var move_dir := direction.slide(get_floor_normal()).normalized()
			velocity.x = move_dir.x * SPEED
			velocity.z = move_dir.z * SPEED
			velocity.y = move_dir.y * SPEED
		else:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _is_touch_in_joystick_zone(pos: Vector2) -> bool:
	if not joystick or not $"player_ui/Mobile".visible:
		return false
	var rect = joystick.get_global_rect()
	rect = rect.grow(40)
	return rect.has_point(pos)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if not _is_touch_in_joystick_zone(event.position) and camera_touch_index == -1:
				camera_touch_index = event.index
		else:
			if event.index == camera_touch_index:
				camera_touch_index = -1
	elif event is InputEventScreenDrag:
		if event.index == camera_touch_index:
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			pitch -= event.relative.y * MOUSE_SENSITIVITY
			pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
			camera.rotation.x = pitch
	elif event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		camera.rotation.x = pitch
