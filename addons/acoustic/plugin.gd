@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton(AcousticAudioSettings.AudioManagerSingleton, "src/audio_manager.gd")
	add_autoload_singleton(AcousticAudioSettings.MusicManagerSingleton, "src/music_manager.gd")
	add_autoload_singleton(AcousticAudioSettings.SoundPoolSingleton, "src/sound_pool.gd")
	
	AcousticAudioSettings.setup_sound_pool_settings()
	
	add_custom_type(
		"AcousticSoundQueue", 
		"Node", 
		preload("src/components/queue/sound_queue.gd"),
		preload("src/components/queue/sound_queue.svg")
	)
	
	add_custom_type("ConsumableAudioStreamPlayer",
		 "AudioStreamPlayer",
		 preload("src/components/consumables/consumable_audio_stream_player.gd"),
		 null
	)
	
	add_custom_type("ConsumableAudioStreamPlayer2D",
		 "AudioStreamPlayer2D",
		 preload("src/components/consumables/consumable_audio_stream_player_2d.gd"),
		 null
	)
	
	add_custom_type("ConsumableAudioStreamPlayer3D",
		 "AudioStreamPlayer3D",
		 preload("src/components/consumables/consumable_audio_stream_player_3d.gd"),
		 null
	)
	
	
func _exit_tree() -> void:
	remove_custom_type("ConsumableAudioStreamPlayer3D")
	remove_custom_type("ConsumableAudioStreamPlayer2D")
	remove_custom_type("ConsumableAudioStreamPlayer")
	remove_custom_type("AcousticSoundQueue")
	
	remove_autoload_singleton(AcousticAudioSettings.SoundPoolSingleton)
	remove_autoload_singleton(AcousticAudioSettings.MusicManagerSingleton)
	remove_autoload_singleton(AcousticAudioSettings.AudioManagerSingleton)
