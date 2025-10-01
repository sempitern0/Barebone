class_name FpsLimitOptionButton extends OptionButton

@export var fps_limits: GameSetting

var fps_limit_by_option_button_id: Dictionary = {}

func _enter_tree() -> void:
	if fps_limits == null:
		if SettingsManager.active_settings.has(GameSettings.FpsLimitsSetting):
			fps_limits = SettingsManager.active_settings[GameSettings.FpsLimitsSetting]
	
	assert(fps_limits.field_type == TYPE_ARRAY and fps_limits.value().size() > 0, "FpsLimitsOptionButton: The game setting resource does not contain a value of type Array[int]")


func _ready() -> void:
	item_selected.connect(on_language_selected)
	
	var id: int = 0
	
	for fps_limit: int in fps_limits.value():
		if fps_limit == 0:
			add_item(tr("NO_FPS_LIMIT"), id)
		else:
			add_item(str(fps_limit), id)
			
		if fps_limit == Engine.max_fps:
			select(item_count - 1)
			
		fps_limit_by_option_button_id[id] = fps_limit
		id += 1


func on_language_selected(idx) -> void:
	var fps_limit: int = fps_limit_by_option_button_id[get_item_id(idx)]
	Engine.max_fps = fps_limit
	
	SettingsManager.update_graphics_section(GameSettings.MaxFpsSetting, fps_limit)
