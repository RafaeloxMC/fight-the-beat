extends Node3D

var bpm: int = 130

func _ready() -> void:
	tick_bpm()

func tick_bpm() -> void:
	await get_tree().create_timer(60.0 / bpm).timeout
	print("Ping")
	self.position.z += 1
	tick_bpm()
