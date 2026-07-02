extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.008
var pitch: float = 0.0

var joystick_active = false

var GRAVITY_MULTIPLIER = 1.0

@onready var camera: Camera3D = $Camera3D
@onready var joystick: VirtualJoystick = $player_ui/Mobile/VirtualJoystick

var gifts = 0
var SPEED = 5.0
var ignore_next_mouse_motion = false
const JUMP_VELOCITY = 6#4.5
const DASH_FORCE = 50.0
var dead = false
var has_air_dashed = false
var menu_open = false
var camera_touch_index: int = -1

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$player_ui/GameOver/RetryButton.pressed.connect(_on_retry_pressed)
	joystick.pressed.connect(func(): joystick_active = true)
	joystick.released.connect(func(_v): joystick_active = false)

func _on_retry_pressed():
	dead = false
	camera_touch_index = -1
	$"../game".reset_game()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ignore_next_mouse_motion = true

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta
	else:
		has_air_dashed = false

	if dead:
		$player_ui/GameOver.visible = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
		camera_touch_index = -1

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func _is_touch_in_joystick_zone(pos: Vector2) -> bool:
	if not joystick:
		return false
	var joystick_center = joystick.get_global_rect().get_center()
	var distance = pos.distance_to(joystick_center)
	return distance <= 100

func _input(event: InputEvent) -> void:
	if menu_open or dead:
		return
	if event is InputEventScreenTouch:
		if event.pressed and camera_touch_index == -1:
			if not _is_touch_in_joystick_zone(event.position):
				camera_touch_index = event.index
		elif event.index == camera_touch_index:
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
