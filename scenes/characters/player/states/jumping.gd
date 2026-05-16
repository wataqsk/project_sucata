extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	player.state_machine.travel(PlayerState.JUMPING)

func physics_update(_delta: float) -> void:
	if player.velocity.y < 0.0:
		finished.emit(PlayerState.FALLING)
