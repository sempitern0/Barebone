class_name MusicPlaylist extends Resource

enum Mode {
	Lineal,
	Random
}

@export var playlist_name: StringName
@export var mode: Mode = Mode.Lineal
@export var loop: bool = true
@export var tracks: Array[MusicTrack] = []


func is_lineal_mode() -> bool:
	return mode == Mode.Lineal
	
func is_random_mode() -> bool:
	return mode == Mode.Random
