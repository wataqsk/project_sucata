# This script exists to avoid repeating the same boilerplate in every state script.
# Boilerplate = A code you have to write repeatedly across multiple files that is always the same

class_name PlayerState extends State

const IDLE    = "Idle"
const WALKING = "Walking"
const JUMPING = "Jumping"
const FALLING = "Falling"
const LANDING = "Landing"

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the player scene. It needs the owner to be a Player node.")
