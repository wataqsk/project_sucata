# This script doesn't do anything by itself
# But it defines what functions every state must be able to have
# Without it, each state script would be completely unrelated

class_name State extends Node

@warning_ignore("unused_signal")
signal finished(next_state_path: String, data: Dictionary)

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func enter(_previous_state_path: String, _data := {}) -> void:
	pass

func exit() -> void:
	pass
