class_name SettingValueLabel extends Label

@export var setting: GameSetting
@export var show_decimal: bool = false


func _ready() -> void:
	assert(setting != null, "SettingValueLabel: The %s checkbox does not have a GameSetting resource linked" % name)
	
	if show_decimal:
		text = str(SettingsManager.get_section(setting.section, setting.key))
	else:
		text = str(int(SettingsManager.get_section(setting.section, setting.key)))
	
	SettingsManager.updated_setting_section.connect(on_updated_setting_section)
	

func on_updated_setting_section(section: String, key: String, value: Variant) -> void:
	if section == setting.section and key == setting.key:
		text = str(value if show_decimal else int(value))
