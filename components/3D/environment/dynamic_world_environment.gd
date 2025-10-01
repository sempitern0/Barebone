class_name DynamicWorldEnvironment extends WorldEnvironment

	
func _ready() -> void:
	OmniKitHardwareRequirements.apply_graphics_on_environment(self, SettingsManager.get_graphics_section(GameSettings.QualityPresetSetting))
	SettingsManager.updated_setting_section.connect(on_updated_setting_section)
	
	
func on_updated_setting_section(_section: String, key: String, value: Variant) -> void:
	match key:
		GameSettings.QualityPresetSetting:
			OmniKitHardwareRequirements.apply_graphics_on_environment(self, value)
			
		GameSettings.ScreenBrightnessSetting:
			if environment:
				environment.adjustment_brightness = value
				
		GameSettings.ScreenContrastSetting:
			if environment:
				environment.adjustment_contrast = value
				
		GameSettings.ScreenSaturationSetting:
			if environment:
				environment.adjustment_saturation = value
