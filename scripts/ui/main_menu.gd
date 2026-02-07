extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_play_pressed() -> void:
	SceneManager.call_scene("game")

func _on_load_song_pressed() -> void:
	DisplayServer.file_dialog_show("Select a Song file", "~/", "", false, DisplayServer.FILE_DIALOG_MODE_OPEN_FILE, [], _on_file_picked)


func _on_file_picked(status: bool, selected_paths: PackedStringArray, _selected_filter_index: int) -> void:
	if status == true:
		var file = selected_paths[0]
		print("Loading song file at " + file)
		var fa = FileAccess.open(file, FileAccess.ModeFlags.READ)
		var content = fa.get_as_text()
		print("Loaded song file! Content: " + content)

func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
