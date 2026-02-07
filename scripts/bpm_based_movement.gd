extends Node

@onready var trigger_line: Area3D = $TriggerLine

@export var base_tile = PackedScene
@export var lanes: Array[Node3D] = []

var bpm: int = 130
var tiles: Array[Node3D] = []
var speed: float

var speed_multiplier = 2

func _ready() -> void:
	var notes = get_tree().get_nodes_in_group("TILE")
	for note in notes:
		if note is Node3D:
			tiles.append(note)
	print("Found " + str(tiles.size()) + " notes!")
	
	speed = bpm / 60.0 * speed_multiplier

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
		
	
	for tile in trigger_line.get_overlapping_bodies():
		tile = tile.get_parent() as CSGBox3D
		if tile.is_in_group("TILE"):
			if lanes_queued_for_deletion.has(tile.get_parent().name):
				tile.queue_free()
				tiles.erase(tile)
				print("Tile removed")

func add_new_note_to_lane(lane: Node3D) -> void:
	var new_tile = base_tile.new().instantiate()
	if new_tile is not Node3D:
		new_tile.queue_free()
		return
	lane.add_child(new_tile as Node3D)
	tiles.append(new_tile as Node3D)
