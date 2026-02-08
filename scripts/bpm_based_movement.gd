extends Node

@onready var trigger_line: Area3D = $TriggerLine
@onready var debug: Label = $"UI Container/DEBUG"

@export var base_tile: PackedScene
@export var lanes: Array[Node3D] = []

var bpm: int = 130
var tiles: Array[Node3D] = []
var speed: float

var speed_multiplier = 2

func _ready() -> void:
	spawn_lane(SongManager.currently_playing.tiles_ll, lanes[0])
	spawn_lane(SongManager.currently_playing.tiles_ml, lanes[1])
	spawn_lane(SongManager.currently_playing.tiles_mr, lanes[2])
	spawn_lane(SongManager.currently_playing.tiles_rr, lanes[3])
	
	print("Found " + str(tiles.size()) + " notes!")
	speed = bpm / 60.0 * speed_multiplier


func _process(delta: float) -> void:
	
	debug.text = SongManager.currently_playing.title + " - " + SongManager.currently_playing.artist + " (" + str(SongManager.currently_playing.bpm) + " BPM)" + "\nLL: " + str(SongManager.currently_playing.tiles_ll) + "\nML: " + str(SongManager.currently_playing.tiles_ml) + "\nMR: " + str(SongManager.currently_playing.tiles_mr) + "\nRR: " + str(SongManager.currently_playing.tiles_rr)
	
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
		
	
	for tile in trigger_line.get_overlapping_bodies():
		tile = tile.get_parent() as CSGBox3D
		if tile.is_in_group("TILE"):
			if lanes_queued_for_deletion.has(tile.get_parent().name):
				tile.queue_free()
				tiles.erase(tile)
				print("Tile removed")

func add_new_note_to_lane(lane: Node3D, offset: float) -> void:
	print("Offset: " + str(offset))
	var new_tile = base_tile.instantiate()
	if new_tile is not Node3D:
		new_tile.queue_free()
		return
	new_tile.position.z -= offset * 2
	lane.add_child(new_tile as Node3D)
	tiles.append(new_tile as Node3D)

func spawn_lane(pattern: Array[bool], lane: Node3D) -> void:
	for i in pattern.size():
		if pattern[i]:
			add_new_note_to_lane(lane, i)
