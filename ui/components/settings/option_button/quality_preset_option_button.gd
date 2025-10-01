class_name QualityPresetOptionButton extends OptionButton

var QualityPresetKeys: Dictionary = {
	OmniKitHardwareRequirements.QualityPreset.Low: "QUALITY_LOW",
	OmniKitHardwareRequirements.QualityPreset.Medium: "QUALITY_MEDIUM",
	OmniKitHardwareRequirements.QualityPreset.High: "QUALITY_HIGH",
	OmniKitHardwareRequirements.QualityPreset.Ultra: "QUALITY_ULTRA",
}


var quality_preset_by_option_button_id: Dictionary = {}


func _ready() -> void:
	item_selected.connect(on_language_selected)
	
	var id: int = 0
	
	for quality_preset: OmniKitHardwareRequirements.QualityPreset in QualityPresetKeys:
		add_item(tr(QualityPresetKeys[quality_preset]), id)
		
		if quality_preset == SettingsManager.get_graphics_section(GameSettings.QualityPresetSetting):
			select(item_count - 1)
			
		quality_preset_by_option_button_id[id] = quality_preset
		id += 1


func on_language_selected(idx) -> void:
	var selected_graphic_preset = quality_preset_by_option_button_id[get_item_id(idx)]
	SettingsManager.update_graphics_section(GameSettings.QualityPresetSetting, selected_graphic_preset)
