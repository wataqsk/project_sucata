extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	player.state_machine.travel(PlayerState.LANDING)

func physics_update(_delta: float) -> void:
	if player.move_direction.length_squared() > 0.0:
		finished.emit(PlayerState.WALKING)
	elif player.move_direction.length_squared() == 0.0:
		finished.emit(PlayerState.IDLE)
