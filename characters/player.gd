class_name Player
extends CharacterBody3D

@export_category("Player Stats")
@export_group("Movement Settings")
@export_range(0, 360, 1) var turn_speed: float = 90.0
@export_range(0, 360, 1) var walk_speed: float = 90.0
@export_range(0, 360, 1) var run_speed: float = 90.0

func handle_turn(delta: float) -> void:
	var turn_dir = Input.get_axis("turn_left", "turn_right")
	rotation_degrees.y -= turn_dir * turn_speed * delta

func handle_walk(delta: float) -> void:
	var input_dir = Input.get_axis("move_backward", "move_forward")
	var walk_velocity = basis.z * input_dir * walk_speed * delta

	velocity.x = walk_velocity.x
	velocity.z = walk_velocity.z

func _physics_process(delta: float) -> void:
	handle_turn(delta)
	handle_walk(delta)
	move_and_slide()
