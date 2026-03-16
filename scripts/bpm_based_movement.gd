extends Node

@onready var trigger_line: Area3D = $TriggerLine
@onready var debug: Label = $"UI Container/DEBUG"
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var world_environment: WorldEnvironment = $WorldEnvironment

@export var base_tile: PackedScene
@export var lanes: Array[Node3D] = []

var bpm: float = 130
var tiles: Array[Node3D] = []
var speed: float
var speed_multiplier: float = 4.0

const TRIGGER_LINE_LOCAL_Z: float = 24.5
const LANE_BACK_LOCAL_Z: float = -25.5
var lookahead_beats: float = 8.0

var elapsed_time: float = 0.0
var beats_per_second: float = 0.0

var cursors: Array[int] = [0, 0, 0, 0]
var lane_patterns: Array = []
var lane_names: Array[String] = ["LL", "ML", "MR", "RR"]

var combo: int = 0

const SUBDIVISIONS: int = 48

var audio_delay: float = 0.0

func _ready() -> void:
	var song = SongManager.currently_playing
	bpm = song.bpm
	beats_per_second = bpm / 60.0
	speed = beats_per_second * speed_multiplier
	
	lookahead_beats = (TRIGGER_LINE_LOCAL_Z - LANE_BACK_LOCAL_Z) / speed_multiplier
	audio_delay = lookahead_beats / beats_per_second
	elapsed_time = - audio_delay
	
	audio_stream_player.stream = song.stream
	
	if song.bg:
		# Duplicate the resource chain so we're not editing shared/cached originals
		var env: Environment = world_environment.environment.duplicate()
		var sky: Sky = env.sky.duplicate()
		var sky_mat: PanoramaSkyMaterial = sky.sky_material.duplicate()

		sky_mat.panorama = ImageTexture.create_from_image(song.bg)
		sky.sky_material = sky_mat
		env.sky = sky
		world_environment.environment = env
		
	lane_patterns = [
		song.tiles_ll,
		song.tiles_ml,
		song.tiles_mr,
		song.tiles_rr,
	]

	print("Found %d / %d / %d / %d notes across 4 lanes." % [
		_count_notes(song.tiles_ll),
		_count_notes(song.tiles_ml),
		_count_notes(song.tiles_mr),
		_count_notes(song.tiles_rr),
	])
	
	await get_tree().create_timer(audio_delay - 0.5).timeout
	audio_stream_player.play()

func _count_notes(arr: Array[float]) -> int:
	var n: int = 0
	for v in arr:
		if v > 0.0: n += 1
	return n

func _process(delta: float) -> void:
	if audio_stream_player.playing:
		elapsed_time = audio_stream_player.get_playback_position() \
			+ AudioServer.get_time_since_last_mix() \
			- AudioServer.get_output_latency()
	else:
		elapsed_time += delta

	var current_sub: float = elapsed_time * beats_per_second * SUBDIVISIONS
	var lookahead_sub: float = current_sub + lookahead_beats * SUBDIVISIONS

	for i in 4:
		var pattern: Array[float] = lane_patterns[i]
		var cursor: int = cursors[i]
		while cursor < pattern.size():
			if pattern[cursor] <= 0.0:
				cursor += 1
				continue
			if cursor > lookahead_sub:
				break
			var beats_ahead: float = (cursor - current_sub) / SUBDIVISIONS
			var duration_beats: float = pattern[cursor]
			_spawn_tile(lanes[i], beats_ahead, duration_beats)
			cursor += 1
		cursors[i] = cursor

	for tile in tiles:
		if tile.is_queued_for_deletion():
			continue
		tile.position.z += speed * delta
		if tile.position.z > TRIGGER_LINE_LOCAL_Z + 1.0:
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
		_count_notes(SongManager.currently_playing.tiles_ll),
		_count_notes(SongManager.currently_playing.tiles_ml),
		_count_notes(SongManager.currently_playing.tiles_mr),
		_count_notes(SongManager.currently_playing.tiles_rr),
		tiles.size(),
		combo
	]

func _spawn_tile(lane: Node3D, beats_ahead: float, duration_beats: float) -> void:
	var new_tile = base_tile.instantiate()
	if new_tile is not Node3D:
		new_tile.queue_free()
		return
	var tile := new_tile as CSGBox3D
	var tile_z: float = duration_beats * speed_multiplier
	tile_z = maxf(tile_z, 0.05)
	tile.size.z = tile_z
	tile.position.z = TRIGGER_LINE_LOCAL_Z - beats_ahead * speed_multiplier
	lane.add_child(tile)
	tiles.append(tile)
