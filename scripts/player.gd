extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.003
var pitch: float = 0.0
@onready var camera: Camera3D = $Camera3D
@onready var joystick: VirtualJoystick = $player_ui/VirtualJoystick

var gifts = 0
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

const DASH_FORCE = 50.0
var dead = false
var has_air_dashed = false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		has_air_dashed = false

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

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()

func _input(event: InputEvent) -> void:
	if joystick and joystick.is_pressed:
		return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch -= event.relative.y * MOUSE_SENSITIVITY
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))
		camera.rotation.x = pitch
