extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	player.state_machine.travel(PlayerState.FALLING)

func physics_update(_delta: float) -> void:
	if player.is_on_floor():
		finished.emit(PlayerState.LANDING)
