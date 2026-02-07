extends Node

@export var scenes: Dictionary[String, PackedScene] = {}

func call_packed(scene: PackedScene) -> void:
	get_tree().change_scene_to_packed(scene)
	
func call_scene(scene: String) -> void:
	var packed = scenes.get(scene)
	if !packed:
		print("Scene " + scene + " not found!")
		return
	call_packed(packed)
