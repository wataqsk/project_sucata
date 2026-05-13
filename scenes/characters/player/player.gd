extends CharacterBody3D

@export_category("Camera")
@export_group("Camera Sensibility")
@export_range(0.0, 1.0) var camera_sensitivity := 0.25

## Determina o limite da câmera vertical
@export_group("Camera Pitch")
@export_range(-90.0, 0.0, 1.0, "suffix:°") var camera_pitch_min := -30.0
@export_range(0.0, 90.0, 1.0, "suffix:°") var camera_pitch_max := 60.0

@export_category("Movement")
@export_group("Character Speed")
@export var move_speed := 8.0
@export var acceleration := 20.0

@export_group("Jump")
@export var jump_force := 12.0 
## Configuração do CoyoteTime abaixo, 0.1 parece ser o melhor mesmo, 0.2 parece ser um poooouco alto demais, se quiser dar uma testada
@export var coyote_time := 0.1  # Tempo em segundos que o jogador pode pular depois de sair do chão

## Determina quanto tempo leva pro Mesh do player girar na direção da câmera
@export_group("Character Skin")
@export var rotation_speed := 8.0

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = %Mannequin

var _camera_input_direction := Vector2.ZERO
var _last_move_direction := Vector3.BACK

## Estado de pulo
var _is_jumping := false

## Timer interno pro CoyoteTime
var _coyote_timer := 0.0
var _was_on_floor := false

## Usando a gravidade default do Godot (normalmente 9.8)
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var state_machine: AnimationNodeStateMachinePlayback

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
		_camera_input_direction += event.screen_relative * camera_sensitivity

func _physics_process(delta: float) -> void:
	_update_camera(delta)
	_update_movement(delta)
	_update_gravity(delta)
	_update_coyote_time(delta)
	_update_jump()
	_update_animation()
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
		# Gravidade normal
		velocity.y -= gravity * delta
		
		# Se estiver caindo (não subindo), aplica gravidade extra
		if velocity.y < 0:
			velocity.y -= gravity * delta * 3.0  

# Função para gerenciar o coyote time
func _update_coyote_time(delta: float) -> void:
	# Se estava no chão e agora não está mais
	if _was_on_floor and not is_on_floor():
		_coyote_timer = coyote_time
	
	# Se está no chão, reseta o timer
	if is_on_floor():
		_coyote_timer = 0.0
	
	# Decrementa o timer
	if _coyote_timer > 0.0:
		_coyote_timer -= delta
	
	# Atualiza o estado anterior
	_was_on_floor = is_on_floor()

func _update_jump() -> void:
	var can_jump := is_on_floor() or _coyote_timer > 0.0
	
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = jump_force
		_is_jumping = true
		_coyote_timer = 0.0  # Reseta o timer ao pular

func _check_landing() -> void:
	if is_on_floor() and _is_jumping:
		_is_jumping = false

func _update_movement(delta: float) -> void:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x
	var move_direction := (forward * raw_input.y + right * raw_input.x)
	move_direction.y = 0.0

	if move_direction.length_squared() > 0.0:
		_last_move_direction = move_direction.normalized()
		move_direction = move_direction.normalized()

	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)

	var target_angle := Vector3.BACK.signed_angle_to(_last_move_direction, Vector3.UP)
	_skin.rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

func _update_animation() -> void:
	if _is_jumping:
		state_machine.travel("Jump")
	elif velocity.length_squared() > 0.0:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")
