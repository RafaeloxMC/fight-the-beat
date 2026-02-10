extends Control

@export var base_tile: PackedScene
@export var lanes: Array[CSGBox3D] = []

var bpm: int = 130
var tiles: Array[CSGBox3D] = []
var speed: float

var speed_multiplier = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_lane(lanes[0])
	spawn_lane(lanes[1])
	spawn_lane(lanes[2])
	spawn_lane(lanes[3])
	
	speed = bpm / 60.0 * speed_multiplier

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	for tile in tiles:
		if !tile.is_queued_for_deletion() && tile.position.z > (tile.get_parent_node_3d() as CSGBox3D).size.z / 2:
			tile.queue_free()
			tiles.erase(tile)
			print("Tile deleted!")
		tile.position.z += speed * delta
		
	
	var lanes_queued_for_deletion: Array[String] = []
	
	if Input.is_action_just_pressed("LEFT_LANE"):
		lanes_queued_for_deletion.append("LL")
	if Input.is_action_just_pressed("ML_LANE"):
		lanes_queued_for_deletion.append("ML")
	if Input.is_action_just_pressed("MR_LANE"):
		lanes_queued_for_deletion.append("MR")
	if Input.is_action_just_pressed("RIGHT_LANE"):
		lanes_queued_for_deletion.append("RR")

func add_new_note_to_lane(lane: CSGBox3D) -> void:
	var new_tile = base_tile.instantiate()
	if new_tile is not CSGBox3D:
		new_tile.queue_free()
		return
	new_tile.position.z -= (lane).size.z / 2
	lane.add_child(new_tile)
	tiles.append(new_tile)

func spawn_lane(lane: Node3D) -> void:
	print("Spawned!")
	add_new_note_to_lane(lane)
	await get_tree().create_timer(randf_range(0.5, 4)).timeout
	spawn_lane(lane)


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
		SongInterpreter.parse_song_data(content)

func _on_settings_pressed() -> void:
	pass # Replace with function body.


func _on_quit_pressed() -> void:
	get_tree().quit()
