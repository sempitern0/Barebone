class_name MutedAudioCheckbox extends SettingCheckbox


func _ready() -> void:
	super._ready()
	button_pressed = AcousticAudioManager.all_buses_are_muted()
	

func on_setting_changed(enabled: bool) -> void:
	if(enabled):
		AcousticAudioManager.mute_all_buses()
	else:
		AcousticAudioManager.unmute_all_buses()
		
	SettingsManager.update_audio_section(GameSettings.MutedAudioSetting, enabled)
