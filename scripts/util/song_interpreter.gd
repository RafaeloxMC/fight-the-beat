extends Node

var song_data: Dictionary[String, String]

# BELOW IS AN EXAMPLE SONG SAVE FILE
# ++TITLE++Super Taxi Sim Theme++
# ++ARTIST++xvcf++
# ++AUTHOR++xvcf++
# ++YEAR++2025++
# ++BPM++120++
# ++LL++|-x-x-x-x-x-x-x-x-x-x-x-x-|++
# ++ML++|-x-----x-----x-----x-----|++
# ++MR++|-----x-----------x-------|++
# ++RR++|-----------x-------------|++

func parse_song_data(raw: String) -> void:
	var data_lines: PackedStringArray = raw.split("\n")
	for line in data_lines:
		line = line.trim_prefix("++").trim_suffix("++")
		print("Key: " + line.split("++")[0] + " - Value: " + line.split("++")[1])
		song_data.set(line.split("++")[0], line.split("++")[1])
	var song = Song.new()
	song.title = song_data.get("TITLE", "N/A")
	song.artist = song_data.get("ARTIST", "N/A")
	song.author = song_data.get("AUTHOR", "N/A")
	song.year = song_data.get("YEAR", 1970)
	song.bpm = song_data.get("BPM", 120)
	SongManager.currently_playing = song
