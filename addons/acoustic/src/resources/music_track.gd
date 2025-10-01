class_name MusicTrack extends Resource

@export var track_name: StringName
@export var artist: StringName
@export var stream: AudioStream
@export var from_position: float = 0.0
@export_enum(&"Master", &"Music", &"SFX", &"EchoSFX", &"Voice", &"UI", &"Ambient") var bus: String = AcousticAudioManager.MusicBus


func _init(_stream: AudioStream, _name: StringName, _artist: StringName, _bus: StringName) -> void:
	stream = _stream
	track_name = _name
	artist = _artist
	bus = _bus
