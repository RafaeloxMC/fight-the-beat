extends Control

@onready var background: Button = $Control/Background

func _ready() -> void:
	_update_background_btn_text()

func _on_background_pressed() -> void:
	GameManager.background_mode = !GameManager.background_mode
	_update_background_btn_text()

func _update_background_btn_text() -> void:
	if GameManager.background_mode:
		background.text = "BACKGROUND - 3D"
	else:
		background.text = "BACKGROUND - 2D"

func _on_back_pressed() -> void:
	SceneManager.call_scene("main_menu")
