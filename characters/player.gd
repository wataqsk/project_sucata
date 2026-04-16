class_name Player extends CharacterBody3D

@export_group("Movement Settings")
@export var turn_speed := 180.0
@export var walk_speed := 80.0
@export var run_speed := 280.0

func handle_turn(delta):
	var turn_dir = Input.get_axis ("turn_left","turn_right")
	rotation_degrees.y -= turn_dir * turn_speed * delta
	
func handle_walk(delta):
	var input_dir = Input.get_axis("move_backward","move_forward")	
	var walk_velocity = -basis.z * input_dir * walk_speed * delta
	velocity.x = walk_velocity.x
	velocity.x = walk_velocity.z
	
func _physics_process(delta: float) -> void:
	handle_turn(delta)
	handle_walk(delta)		
	
	move_and_slide()


#extends CharacterBody3D


#const SPEED = 5.0
#const JUMP_VELOCITY = 4.5


#func _physics_process(delta: float) -> void:
	# Add the gravity.
#	if not is_on_floor():
#		velocity += get_gravity() * delta

	# Handle jump.
#	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
#		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
#	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
#	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
#	if direction:
#		velocity.x = direction.x * SPEED
#		velocity.z = direction.z * SPEED
#	else:
#		velocity.x = move_toward(velocity.x, 0, SPEED)
#		velocity.z = move_toward(velocity.z, 0, SPEED)

#	move_and_slide()
