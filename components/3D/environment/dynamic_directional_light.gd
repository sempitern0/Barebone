class_name DynamicDirectionalLight3D extends DirectionalLight3D


func _ready() -> void:
	OmniKitHardwareRequirements.apply_graphics_on_directional_light(self, SettingsManager.get_graphics_section(GameSettings.QualityPresetSetting))
	SettingsManager.updated_setting_section.connect(on_updated_setting_section)


func on_updated_setting_section(_section: String, key: String, value: Variant) -> void:
	if key == GameSettings.QualityPresetSetting:
		OmniKitHardwareRequirements.apply_graphics_on_directional_light(self, value)
