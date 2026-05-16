# MAJOR BUG: CHAR IS SLOWLY FALLING WHEN IDLE/JUMPING.
# TO-DO: Add input buffering.
# TO-DO: Remove hardcoded walking-down speed and walking-up-ramps speed.
# TO-DO: Tilt character sprite when walking up and down ramps.
class_name Player extends CharacterBody3D

@export_category("Camera")
@export_group("Camera Sensibility")
@export_range(0.0, 1.0, 0.05) var camera_sensibility := 0.25

@export_group("Camera Pitch")
@export_range(-90.0, 0.0, 5.0, "suffix:°") var camera_pitch_min := -30.0
@export_range(0.0, 90.0, 5.0, "suffix:°") var camera_pitch_max := 60.0

@export_category("Movement")
@export_group("Character Speed")
@export_range(0.0, 20.0, 0.5, "suffix:m/s") var move_speed := 8.0
@export_range(0.0, 40.0, 0.5, "suffix:m/s²") var acceleration := 20.0
@export_range(0.0, 2.0, 0.01) var stopping_speed := 1.0

@export_group("Character Jump")
@export_range(0.0, 25.0, 0.5, "suffix:m/s") var jump_height := 12.0
@export_range(0.0, 0.2, 0.01, "suffix:s") var coyote_time := 0.1

@export_group("Character Skin")
@export_range(1.0, 20.0, 0.5, "suffix:°/s") var rotation_speed := 8.0

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = %Mannequin

var _camera_input_direction := Vector2.ZERO
var _last_move_direction := Vector3.BACK
var _coyote_timer := 0.0
var _is_jumping := false
var _was_on_floor := false

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var state_machine: AnimationNodeStateMachinePlayback
var move_direction := Vector3.ZERO

func _ready() -> void:
	state_machine = $AnimationTree.get("parameters/Movement/playback") as AnimationNodeStateMachinePlayback

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	var is_camera_motion := (
		event is InputEventMouseMotion and
		Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	)
	if is_camera_motion:
		_camera_input_direction += event.screen_relative * camera_sensibility

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_movement(delta)
	_update_coyote_time(delta)
	_update_jump()
	_update_gravity(delta)
	move_and_slide()
	_check_landing()

func _update_camera(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	_camera_pivot.rotation.x = clamp(
		_camera_pivot.rotation.x,
		deg_to_rad(camera_pitch_min),
		deg_to_rad(camera_pitch_max)
	)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO

func _update_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		if velocity.y < 0:
			velocity.y -= gravity * delta * 3.0

func _update_coyote_time(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = 0.0
	elif _was_on_floor:
		_coyote_timer = coyote_time

	if _coyote_timer > 0.0:
		_coyote_timer -= delta

	_was_on_floor = is_on_floor()

func _update_jump() -> void:
	var can_jump := is_on_floor() or _coyote_timer > 0.0
	
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = jump_height
		_is_jumping = true
		_coyote_timer = 0.0

func _check_landing() -> void:
	if is_on_floor() and _is_jumping:
		_is_jumping = false

func _update_movement(delta: float) -> void:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	move_direction = (forward * raw_input.y + right * raw_input.x)
	move_direction.y = 0.0

	if move_direction.length_squared() > 0.0:
		_last_move_direction = move_direction.normalized()
		move_direction = move_direction.normalized()

	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)

	var target_angle := Vector3.BACK.signed_angle_to(_last_move_direction, Vector3.UP)
	_skin.rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

	if is_equal_approx(move_direction.length(), 0.0) and velocity.length() < stopping_speed:
		velocity = Vector3.ZERO
