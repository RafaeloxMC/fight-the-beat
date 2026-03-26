extends Node

@export var scenes: Dictionary[String, PackedScene] = {}

func call_packed(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
	
func call_scene(scene: String) -> void:
	var packed = scenes.get(scene)
	if !packed:
		print("Scene " + scene + " not found!")
		return
	GameManager.transition.emit("rev")
	await get_tree().create_timer(TransitionManager.duration).timeout
	call_packed(packed)
	await get_tree().create_timer(0.25).timeout
	GameManager.transition.emit("fwd")
