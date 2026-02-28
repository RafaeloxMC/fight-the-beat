extends Node

@onready var trigger_line: Area3D = $TriggerLine
@onready var debug: Label = $"UI Container/DEBUG"

@export var base_tile: PackedScene
@export var lanes: Array[Node3D] = []

var bpm: int = 130
var tiles: Array[Node3D] = []
var speed: float
var speed_multiplier = 4

const LOOKAHEAD_BEATS: float = 8.0

var elapsed_time: float = 0.0
var beats_per_second: float = 0.0

var cursors: Array[int] = [0, 0, 0, 0]
var lane_patterns: Array = []
var lane_names: Array[String] = ["LL", "ML", "MR", "RR"]

var combo: int = 0

const SUBDIVISIONS: int = 48

func _ready() -> void:
	var song = SongManager.currently_playing
	bpm = song.bpm
	beats_per_second = bpm / 60.0
	speed = beats_per_second * speed_multiplier

	lane_patterns = [
		song.tiles_ll,
		song.tiles_ml,
		song.tiles_mr,
		song.tiles_rr,
	]

	print("Found %d / %d / %d / %d notes across 4 lanes." % [
		_count_true(song.tiles_ll),
		_count_true(song.tiles_ml),
		_count_true(song.tiles_mr),
		_count_true(song.tiles_rr),
	])

func _count_true(arr: Array[bool]) -> int:
	var n: int = 0
	for v in arr:
		if v: n += 1
	return n

func _process(delta: float) -> void:
	elapsed_time += delta

	var current_sub: float = elapsed_time * beats_per_second * SUBDIVISIONS
	var lookahead_sub: float = current_sub + LOOKAHEAD_BEATS * SUBDIVISIONS

	for i in 4:
		var pattern: Array[bool] = lane_patterns[i]
		var cursor: int = cursors[i]
		while cursor < pattern.size():
			if not pattern[cursor]:
				cursor += 1
				continue
			if cursor > lookahead_sub:
				break
			var beats_ahead: float = (cursor - current_sub) / SUBDIVISIONS
			var z_offset: float = beats_ahead * speed_multiplier
			_spawn_tile(lanes[i], z_offset)
			cursor += 1
		cursors[i] = cursor

	for tile in tiles:
		if tile.is_queued_for_deletion():
			continue
		tile.position.z += speed * delta
		if tile.position.z > (tile.get_parent_node_3d() as CSGBox3D).size.z / 2:
			tile.queue_free()
			tiles.erase(tile)
			combo = 0

	var lanes_queued_for_deletion: Array[String] = []
	if Input.is_action_just_pressed("LEFT_LANE"):
		lanes_queued_for_deletion.append("LL")
	if Input.is_action_just_pressed("ML_LANE"):
		lanes_queued_for_deletion.append("ML")
	if Input.is_action_just_pressed("MR_LANE"):
		lanes_queued_for_deletion.append("MR")
	if Input.is_action_just_pressed("RIGHT_LANE"):
		lanes_queued_for_deletion.append("RR")

	var overlapping: Array[Node3D] = trigger_line.get_overlapping_bodies()
	if overlapping.size() == 0 && lanes_queued_for_deletion.size() > 0:
		combo = 0
	else:
		for tile in overlapping:
			var box: CSGBox3D = tile.get_parent() as CSGBox3D
			if box and box.is_in_group("TILE"):
				if lanes_queued_for_deletion.has(box.get_parent().name):
					tiles.erase(box)
					if box.has_node("AnimationPlayer"):
						(box.get_node("AnimationPlayer") as AnimationPlayer).play("clear")
					else:
						box.queue_free()
					combo += 1

	debug.text = "%s - %s (%d BPM)\nLL: %d  ML: %d  MR: %d  RR: %d  |  Active tiles: %d | Combo: %d" % [
		SongManager.currently_playing.title,
		SongManager.currently_playing.artist,
		SongManager.currently_playing.bpm,
		_count_true(SongManager.currently_playing.tiles_ll),
		_count_true(SongManager.currently_playing.tiles_ml),
		_count_true(SongManager.currently_playing.tiles_mr),
		_count_true(SongManager.currently_playing.tiles_rr),
		tiles.size(),
		combo
	]

func _spawn_tile(lane: Node3D, beats_ahead: float) -> void:
	var new_tile = base_tile.instantiate()
	if new_tile is not Node3D:
		new_tile.queue_free()
		return
	new_tile.position.z = -(beats_ahead * speed_multiplier)
	lane.add_child(new_tile as Node3D)
	tiles.append(new_tile as Node3D)
