extends Node

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func play() -> void:
	if not audio_stream_player.playing:
		audio_stream_player.play()

func stop() -> void:
	audio_stream_player.stop()
