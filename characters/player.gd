extends CharacterBody3D

@export_category("Camera")
@export_group("Camera Sensibility")
@export_range(0.0, 1.0) var camera_sensitivity := 0.25

## Determina o limite da câmera vertical
## Não tá mais hard-codado! Da pra alterar no inspector.
@export_group("Camera Pitch")
@export_range(-90.0, 0.0, 1.0, "suffix:°") var camera_pitch_min := -30.0
@export_range(0.0, 90.0, 1.0, "suffix:°") var camera_pitch_max := 60.0

@export_category("Movement")
@export_group("Character Speed")
@export var move_speed := 8.0
@export var acceleration := 20.0

## Determina quanto tempo leva pro Mesh do player girar na direção da câmera
@export_group("Character Skin")
@export var rotation_speed := 8.0

@onready var _camera_pivot: Node3D = %CameraPivot
@onready var _camera: Camera3D = %Camera3D
@onready var _skin: Node3D = %Mannequin

var _camera_input_direction := Vector2.ZERO
## Isso daqui é importante.
## Armazena na memória a ultima direção na qual o Mesh estava se movendo.
## Existe para manter o Mesh virado quando o player largar o controle.
var _last_move_direction := Vector3.BACK

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
	_update_animation()
	move_and_slide()

func _update_camera(delta: float) -> void:
	_camera_pivot.rotation.x += _camera_input_direction.y * delta
	## Agora o código não ta mais hard-codado e converte o degrees para radians.
	## (Exemplo: A gente pode colocar 180° graus no inpsector ao inves de [Insira número satânico])
	_camera_pivot.rotation.x = clamp(
		_camera_pivot.rotation.x,
		deg_to_rad(camera_pitch_min),
		deg_to_rad(camera_pitch_max)
	)
	_camera_pivot.rotation.y -= _camera_input_direction.x * delta
	_camera_input_direction = Vector2.ZERO

func _update_movement(delta: float) -> void:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	## [Leia ali em baixo primeiro, ou não... ]
	## Provavelmente teriamos que alterar esse cara aqui por conta do -Z. (Z Negativo)
	## "_camera.global_basis.z" -> "-_camera.global_basis.z"
	var forward := _camera.global_basis.z
	var right := _camera.global_basis.x

	var move_direction := (forward * raw_input.y + right * raw_input.x)
	move_direction.y = 0.0

	if move_direction.length_squared() > 0.0:
		_last_move_direction = move_direction.normalized()
		move_direction = move_direction.normalized()

	velocity = velocity.move_toward(move_direction * move_speed, acceleration * delta)

	## A matemática pro Mesh do player rodar ta invertida.
	## Diferente de alguns programas, Godot usa -Z (Z Negativo) como Axis da frente.
	## Ta invertido porque dai eu não preciso girar o Player Mesh em 180deg.
	## Olha o Vector3.BACK, se fosse o Z positivo seria Vector3.FORWARD
	## (E provavelmente teria de negativar o var forward. [Leia ali em cima])
	var target_angle := Vector3.BACK.signed_angle_to(_last_move_direction, Vector3.UP)
	## Essa parte é interessante, o lerp_angle interpola (se acostume com essa palavra)
	## A rotação do mesh, fazendo que ela seja progressiva ao invés de imediata.
	## Fazendo com que a animação percorra um caminho antes de virar-se.
	## Basicamente, deixa a coisa mais fluida!
	## Descomenta o código abaixo e comenta o larp_angle para você vê a diferença.
	## _skin.rotation.y = target _angle
	_skin.rotation.y = lerp_angle(_skin.rotation.y, target_angle, rotation_speed * delta)

## Existe aqui o mesmo problema do Unity.
## O personagem sempre passa pelo Idle quando você anda pro lado oposto.
## Apesar de que aqui parece um pouco mais sútil, ainda preciso ver melhor.
func _update_animation() -> void:
	if velocity.length_squared() > 0.0:
		state_machine.travel("Walk")
	else:
		state_machine.travel("Idle")
