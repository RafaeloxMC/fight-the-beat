extends Node

var bpm: int = 130
var tiles: Array[Node3D] = []
var speed: float

func _ready() -> void:
	var notes = get_tree().get_nodes_in_group("TILE")
	for note in notes:
		if note is Node3D:
			tiles.append(note)
	print("Found " + str(tiles.size()) + " notes!")
	
	speed = bpm / 60.0

func _process(delta: float) -> void:
	for tile in tiles:
		if !tile.is_queued_for_deletion() && tile.position.z > (tile.get_parent_node_3d() as CSGBox3D).size.z / 2:
			tile.queue_free()
			tiles.erase(tile)
			print("Tile deleted!")
		tile.position.z += speed * delta
