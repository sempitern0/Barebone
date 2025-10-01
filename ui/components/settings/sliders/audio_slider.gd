class_name AudioSlider extends SettingHSlider

@export_enum(&"Master", &"Music", &"SFX", &"EchoSFX", &"Voice", &"UI", &"Ambient") var target_bus: String = AcousticAudioManager.MusicBus


func _enter_tree() -> void:
	name = "%sAudioSlider" % target_bus
	
	min_value = 0.0
	max_value = 1.0
	step = 0.001
	

func _ready() -> void:
	super._ready()
	value = AcousticAudioManager.get_actual_volume_db_from_bus(target_bus)


func update_bus_volume(new_volume: float) -> void:
	if(target_bus == AcousticAudioManager.SFXBus):
		AcousticAudioManager.change_volume(AcousticAudioManager.EchoSFXBus, new_volume)
			
	AcousticAudioManager.change_volume(target_bus, new_volume)


func on_value_setting_changed(new_value: float) -> void:
	update_bus_volume(new_value)


func on_setting_changed(volume_changed: bool):
	if volume_changed:
		update_bus_volume(value)
		SettingsManager.update_audio_section(target_bus, value)
