extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	player.state_machine.travel(PlayerState.IDLE)

func physics_update(_delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		finished.emit(PlayerState.JUMPING)
	elif player.move_direction.length_squared() > 0.0:
		finished.emit(PlayerState.WALKING)
