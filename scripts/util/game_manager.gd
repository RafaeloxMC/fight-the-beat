extends Node

# True = 3D, false = 2D
var background_mode: bool = true

@warning_ignore("unused_signal")
signal transition(direction: String)

func _ready() -> void:
	BackgroundMusicPlayer.play()
