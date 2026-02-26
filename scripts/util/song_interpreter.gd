extends Node

var song_data: Dictionary[String, String]

func load_song_from_file(path: String) -> void:
	if path.ends_with(".osz") or path.ends_with(".zip"):
		_parse_osz(path)
	else:
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file:
			parse_song_data(file.get_as_text())
			file.close()
		else:
			push_error("SongInterpreter: Cannot open file: " + path)

# osu! .osz parser

func _parse_osz(osz_path: String) -> void:
	var zip: ZIPReader = ZIPReader.new()
	var err: Error = zip.open(osz_path)
	if err != OK:
		push_error("SongInterpreter: Failed to open .osz archive: " + osz_path)
		return

	var osu_text: String = ""
	for entry in zip.get_files():
		if entry.ends_with(".osu"):
			var bytes: PackedByteArray = zip.read_file(entry)
			osu_text = bytes.get_string_from_utf8()
			break

	zip.close()

	if osu_text.is_empty():
		push_error("SongInterpreter: No .osu file found inside archive: " + osz_path)
		return

	parse_osu_data(osu_text)

# osu! file parser

func parse_osu_data(raw: String) -> void:
	var lines: PackedStringArray = raw.split("\n")
	
	var section: String = ""
	
	var title: String = "N/A"
	var artist: String = "N/A"
	var author: String = "N/A"
	var key_count: int = 4
	
	var timing_points: Array[Dictionary] = []
	
	var hit_objects: Array[Dictionary] = []
	
	for raw_line in lines:
		var line: String = raw_line.strip_edges()
		if line.is_empty() or line.begins_with("//"):
			continue
			
		if line.begins_with("[") and line.ends_with("]"):
			section = line.substr(1, line.length() - 2)
			continue
			
		match section:
			"Metadata":
				if line.begins_with("Title:"):
					title = line.substr(6).strip_edges()
				elif line.begins_with("Artist:"):
					artist = line.substr(7).strip_edges()
				elif line.begins_with("Creator:"):
					author = line.substr(8).strip_edges()
					
			"Difficulty":
				if line.begins_with("CircleSize:"):
					key_count = int(line.substr(11).strip_edges())
					
			"TimingPoints":
				var parts: PackedStringArray = line.split(",")
				if parts.size() >= 8:
					var uninherited: int = int(parts[6]) == 1
					if uninherited:
						timing_points.append({
							"time_ms": float(parts[0]),
							"beat_length": float(parts[1])
						})
						
			"HitObjects":
				var parts: PackedStringArray = line.split(",")
				if parts.size() >= 3:
					var x: int = int(parts[0])
					var time_ms: int = int(parts[2])
					var column: int = int(floor(float(x) * key_count / 512.0))
					column = clampi(column, 0, key_count - 1)
					hit_objects.append({ "time_ms": time_ms, "column": column })
					
	if timing_points.is_empty():
		push_error("SongInterpreter: No uninherited timing points found in .osu file.")
		return
		
	if hit_objects.is_empty():
		push_error("SongInterpreter: No hit objects found in .osu file.")
		return

	# FTB internal song creation
	var song: Song = Song.new()
	song.title = title
	song.artist = artist
	song.author = author
	song.year = 0

	var primary_beat_len: float = timing_points[0].beat_length
	song.bpm = int(round(60000.0 / primary_beat_len))

	const SUBDIVISIONS: int = 48

	var _get_beat_length: Callable = func(time_ms: float) -> float:
		var bl = timing_points[0].beat_length
		for tp in timing_points:
			if tp["time_ms"] <= time_ms:
				bl = tp["beat_length"]
			else:
				break
		return bl
		
	var t0: float = timing_points[0].time_ms
	
	var max_beat_index: int = 0
	var note_indices: Array[Dictionary] = []
	
	for ho in hit_objects:
		var t: float    = ho["time_ms"]
		var bl: float   = _get_beat_length.call(t)
		var beat_pos: float = (t - t0) / bl
		var beat_idx: int = int(round(beat_pos * SUBDIVISIONS))
		if beat_idx < 0:
			beat_idx = 0
		note_indices.append({ "beat": beat_idx, "column": ho["column"] })
		if beat_idx > max_beat_index:
			max_beat_index = beat_idx
			
	var size: int = max_beat_index + 1
	song.tiles_ll.resize(size)
	song.tiles_ml.resize(size)
	song.tiles_mr.resize(size)
	song.tiles_rr.resize(size)
	song.tiles_ll.fill(false)
	song.tiles_ml.fill(false)
	song.tiles_mr.fill(false)
	song.tiles_rr.fill(false)
	
	for ni in note_indices:
		var b: int = ni["beat"]
		match ni["column"]:
			0: song.tiles_ll[b] = true
			1: song.tiles_ml[b] = true
			2: song.tiles_mr[b] = true
			3: song.tiles_rr[b] = true

	SongManager.currently_playing = song
	print("Song Interpreter: Loaded osu! map: %s – %s  (%d BPM, %d notes)" % [
		song.artist, song.title, song.bpm, hit_objects.size()
	])
	
func parse_song_data(raw: String) -> void:
	var data_lines: PackedStringArray = raw.split("\n")
	for line in data_lines:
		line = line.trim_prefix("++").trim_suffix("++")
		var parts: PackedStringArray = line.split("++")
		if parts.size() < 2:
			continue
		song_data.set(parts[0], parts[1])
		
	var song: Song = Song.new()
	song.title = song_data.get("TITLE",  "N/A")
	song.artist = song_data.get("ARTIST", "N/A")
	song.author = song_data.get("AUTHOR", "N/A")
	song.year = song_data.get("YEAR",   1970)
	song.bpm = song_data.get("BPM",    120)
	
	var ll: String = (song_data.get("LL", "|-|") as String).trim_prefix("|").trim_suffix("|")
	var ml: String = (song_data.get("ML", "|-|") as String).trim_prefix("|").trim_suffix("|")
	var mr: String = (song_data.get("MR", "|-|") as String).trim_prefix("|").trim_suffix("|")
	var rr: String = (song_data.get("RR", "|-|") as String).trim_prefix("|").trim_suffix("|")
	
	for beat in ll:
		song.tiles_ll.append(beat == "x")
	for beat in ml:
		song.tiles_ml.append(beat == "x")
	for beat in mr:
		song.tiles_mr.append(beat == "x")
	for beat in rr:
		song.tiles_rr.append(beat == "x")
		
	SongManager.currently_playing = song
