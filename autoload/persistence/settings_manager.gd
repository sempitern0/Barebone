extends Node

signal reset_to_default_settings(path: String)
signal created_settings(path: String)
signal loaded_settings(path: String)
signal removed_settings(path: String)
signal updated_setting_section(section: String, key: String, value: Variant)

const KeybindingSeparator: String = "|"
const InputEventSeparator: String = ":"
enum ConfigFileFormat {
	Ini,
	Cfg
}

## From the OS.get_user_data_dir(), fill this parameter with the path you desire
## Example 'settings/1.0.0/config'
@export var settings_file_path: String = "settings":
	set(value):
		if value != settings_file_path:
			settings_file_path = value
			config_file_path = OS.get_user_data_dir() + "/%s.%s" % [
				settings_file_path.trim_prefix("/").trim_suffix("/"),  
				OmniKitEnumHelper.value_to_str(ConfigFileFormat, file_format).to_lower()
				]
## The file format of the config file .cfg or .ini
@export var file_format: ConfigFileFormat = ConfigFileFormat.Ini
@export var use_encription: bool = false
@export var include_ui_keybindings: bool = false
## When disabled, the settings needs to be manually loaded
@export var load_on_start: bool = true
@export var settings: Array[GameSetting] = []

var config_file_api: ConfigFile = ConfigFile.new()
var config_file_path: String

var active_settings: Dictionary[StringName, GameSetting] = {}

var viewport_start_size: Vector2i = Vector2i(
	ProjectSettings.get_setting(&"display/window/size/viewport_width"),
	ProjectSettings.get_setting(&"display/window/size/viewport_height")
)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_settings()
	
		
func _enter_tree() -> void:
	updated_setting_section.connect(on_updated_setting_section)
	config_file_path = OS.get_user_data_dir() + "/%s.%s" % [settings_file_path.trim_prefix("/").trim_suffix("/"),  OmniKitEnumHelper.value_to_str(ConfigFileFormat, file_format).to_lower()]
	
	for setting: GameSetting in settings.filter(func(setting): return setting != null):
		active_settings[setting.key] = setting
	
	created_settings.connect(on_created_settings)
	loaded_settings.connect(on_loaded_settings)
	removed_settings.connect(on_removed_settings)
	
	
func _ready() -> void:
	if load_on_start:
		prepare_settings()
	
#region Generic
func save_settings(path: String = config_file_path) -> void:
	var error: Error = config_file_api.save_encrypted_pass(path, _encription_key()) if use_encription else config_file_api.save(path)
	
	if error != OK:
		push_error("SettingsManager: An error %d ocurred trying to save the settings on file %s " % [error_string(error), path])
		

func reset_to_factory_settings(path: String = config_file_path) -> void:
	config_file_api.clear()
	
	remove_settings_file(path)
	create_settings(path)
	load_settings(path)
	
	reset_to_default_settings.emit(path)


func prepare_settings() -> void:
	if(FileAccess.file_exists(config_file_path)):
		load_settings()
	else:
		create_settings(config_file_path)


func load_settings(path: String = config_file_path) -> void:
	var error: Error = config_file_api.load_encrypted_pass(path, _encription_key()) if use_encription else config_file_api.load(path) 
	
	if error != OK:
		push_error("SettingsManager: An error %d ocurred trying to load the settings from path %s " % [error_string(error), path])
		return
	
	for setting: GameSetting in active_settings.values():
		var config_value: Variant = config_file_api.get_value(setting.section, setting.key, null)
		
		if config_value == null: ## The setting is created if it does not exists.
			update_setting_section(setting.section, setting.key, setting.default_value())
		else:
			setting.update_value(config_value)
		
			
	load_audio()
	load_graphics()
	load_localization()
	load_keybindings()
	
	loaded_settings.emit(path)


func remove_settings_file(path: String = config_file_path) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		
	removed_settings.emit(path)
	
#endregion


#region Creation
func create_settings(path: String = config_file_path) -> void:
	for setting: GameSetting in settings.filter(func(setting): return setting != null):
		setting.reset_to_default()
		
		## Some settings default values can be retrieved from the game engine for a better experience
		match setting.key:
			GameSettings.QualityPresetSetting:
				setting.update_value(OmniKitHardwareRequirements.auto_discover_graphics_quality())
			GameSettings.VsyncSetting:
				setting.update_value(DisplayServer.window_get_vsync_mode())
			GameSettings.WindowDisplayBorderlessSetting:
				setting.update_value(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS))
			GameSettings.WindowResolutionSetting:
				setting.update_value(viewport_start_size)
			GameSettings.IntegerScalingSetting:
				setting.update_value(true if ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer" else false)
			GameSettings.CurrentLanguageSetting, GameSettings.VoicesLanguageSetting, GameSettings.SubtitlesLanguageSetting:
				setting.update_value(TranslationServer.get_locale())
				
		update_setting_section(setting.section, setting.key, setting.value())
		
	create_audio_section()
	create_keybindings_section()
	save_settings(path)
	
	created_settings.emit(path)


func create_audio_section() -> void:
	for bus: String in AcousticAudioManager.enumerate_available_buses():
		update_audio_section(bus, AcousticAudioManager.get_default_volume_for_bus(bus))
	
	var buses_are_muted: bool = false

	if active_settings.has(GameSettings.MutedAudioSetting):
		buses_are_muted = active_settings[GameSettings.MutedAudioSetting].value()

	update_audio_section(GameSettings.MutedAudioSetting, buses_are_muted)

	if(buses_are_muted):
		AcousticAudioManager.mute_all_buses()
	else:
		AcousticAudioManager.unmute_all_buses()
		

func create_keybindings_section() -> void:
	_get_input_map_actions().map(create_keybinding_events_for_action)
	update_keybindings_section(GameSettings.DefaultInputMapActionsSetting, GameSettings.DefaultSettings[GameSettings.DefaultInputMapActionsSetting])
#endregion


func reset_keybinding_events_to_default() -> void:
	var default_keybindings: Dictionary = GameSettings.DefaultSettings[GameSettings.DefaultInputMapActionsSetting]
	
	for input_action: StringName in default_keybindings:
		InputMap.action_erase_events(input_action)
		
		for event: InputEvent in default_keybindings[input_action]:
			InputMap.action_add_event(input_action, event)
	
	create_keybindings_section()


func create_keybinding_events_for_action(action: StringName) -> Array[String]:
	var keybinding_events: Array[String] = []
	var all_inputs_for_action: Array[InputEvent] = OmniKitInputHelper.get_all_inputs_for_action(action)
	## We save the default input map actions to allow players reset to factory default
	GameSettings.DefaultSettings[GameSettings.DefaultInputMapActionsSetting][action] = all_inputs_for_action
	
	for input_event: InputEvent in all_inputs_for_action:
		if input_event is InputEventKey:
			keybinding_events.append("InputEventKey:%s" %  OmniKitStringHelper.remove_whitespaces(OmniKitInputHelper.readable_key(input_event)))
			
		if input_event is InputEventMouseButton:
			var mouse_button_text: String = ""
			
			match(input_event.button_index):
				MOUSE_BUTTON_LEFT:
					mouse_button_text = "LMB"
				MOUSE_BUTTON_RIGHT:
					mouse_button_text = "RMB"
				MOUSE_BUTTON_MIDDLE:
					mouse_button_text = "MMB"
				MOUSE_BUTTON_WHEEL_DOWN:
					mouse_button_text = "WheelDown"
				MOUSE_BUTTON_WHEEL_UP:
					mouse_button_text = "WheelUp"
				MOUSE_BUTTON_WHEEL_RIGHT:
					mouse_button_text = "WheelRight"
				MOUSE_BUTTON_WHEEL_LEFT:
					mouse_button_text = "WheelLeft"
					
			keybinding_events.append("InputEventMouseButton%s%d%s%s" % [InputEventSeparator, input_event.button_index, InputEventSeparator, mouse_button_text])
		
		if input_event is InputEventJoypadMotion:
			var joypadAxis: String = ""
			
			match(input_event.axis):
				JOY_AXIS_LEFT_X:
					joypadAxis = "Left Stick %s" % "Left" if input_event.axis_value < 0 else "Right"
				JOY_AXIS_LEFT_Y:
					joypadAxis = "Left Stick %s" % "Up" if input_event.axis_value < 0 else "Down"
				JOY_AXIS_RIGHT_X:
					joypadAxis = "Right Stick %s" % "Left" if input_event.axis_value < 0 else "Right"
				JOY_AXIS_RIGHT_Y:
					joypadAxis = "Right Stick %s" % "Up" if input_event.axis_value < 0 else "Down"
				JOY_AXIS_TRIGGER_LEFT:
					joypadAxis = "Left Trigger"
				JOY_AXIS_TRIGGER_RIGHT:
					joypadAxis = "Right trigger"
			
			keybinding_events.append("InputEventJoypadMotion%s%d%s%d%s%s" % [InputEventSeparator, input_event.axis, InputEventSeparator, input_event.axis_value, InputEventSeparator, joypadAxis])
			
		if input_event is InputEventJoypadButton:
			var joypadButton: String = ""
			
			if(OmniKitGamepadControllerManager.current_controller_is_xbox() or OmniKitGamepadControllerManager.current_controller_is_generic()):
				joypadButton = "%s Button" % OmniKitGamepadControllerManager.XboxButtonLabels[input_event.button_index]
			
			elif OmniKitGamepadControllerManager.current_controller_is_switch() or OmniKitGamepadControllerManager.current_controller_is_switch_joycon():
				joypadButton = "%s Button" % OmniKitGamepadControllerManager.SwitchButtonLabels[input_event.button_index]
			
			elif OmniKitGamepadControllerManager.current_controller_is_playstation():
				joypadButton = "%s Button" % OmniKitGamepadControllerManager.PlaystationButtonLabels[input_event.button_index]
				
			keybinding_events.append("InputEventJoypadButton%s%d%s%s" % [InputEventSeparator, input_event.button_index, InputEventSeparator, joypadButton])
	
	update_keybindings_section(action, KeybindingSeparator.join(keybinding_events))
	
	return keybinding_events


#region Load
func load_audio() -> void:
	var muted_buses: bool = get_audio_section(GameSettings.MutedAudioSetting)
	
	for bus in config_file_api.get_section_keys(GameSettings.AudioSection):
		if bus in AcousticAudioManager.enumerate_available_buses():
			AcousticAudioManager.change_volume(bus, get_audio_section(bus))
			AcousticAudioManager.mute_bus(bus, muted_buses)
		
@warning_ignore("int_as_enum_without_cast")
func load_graphics() -> void:
	var viewport: Viewport = get_viewport()
	var window: Window = get_window()
	
	for section_key: String in config_file_api.get_section_keys(GameSettings.GraphicsSection):
		var config_value = get_graphics_section(section_key)
		
		match section_key:
			GameSettings.MaxFpsSetting:
				Engine.max_fps = config_value
			GameSettings.CurrentMonitorSetting:
				if config_value < DisplayServer.get_screen_count():
					window.current_screen = config_value
				else:
					window.current_screen = GameSettings.DefaultSettings[GameSettings.CurrentMonitorSetting]
			GameSettings.WindowDisplaySetting:
				DisplayServer.window_set_mode(config_value)
			GameSettings.WindowDisplayBorderlessSetting:
				DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, bool(config_value))
			GameSettings.WindowResolutionSetting:
				DisplayServer.window_set_size(config_value)
			GameSettings.IntegerScalingSetting:
				@warning_ignore("int_as_enum_without_cast")
				get_tree().root.content_scale_stretch = int(config_value)
			GameSettings.Antialiasing3DSetting:
				viewport.msaa_3d = config_value
				
				if viewport.msaa_3d == Viewport.MSAA_DISABLED:
					RenderingServer.viewport_set_screen_space_aa(viewport.get_viewport_rid(), RenderingServer.VIEWPORT_SCREEN_SPACE_AA_FXAA)
				else:
					RenderingServer.viewport_set_screen_space_aa(viewport.get_viewport_rid(), RenderingServer.VIEWPORT_SCREEN_SPACE_AA_DISABLED)
					
			GameSettings.Scaling3DMode:
				viewport.scaling_3d_mode = config_value
			GameSettings.Scaling3DValue:
				if viewport.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR:
					viewport.scaling_3d_scale = config_value
			GameSettings.Scaling3DFSRValue:
				if viewport.scaling_3d_mode != Viewport.SCALING_3D_MODE_BILINEAR:
					viewport.scaling_3d_scale = config_value
			GameSettings.VsyncSetting:
				DisplayServer.window_set_vsync_mode(config_value)
		
		updated_setting_section.emit(GameSettings.GraphicsSection, section_key, config_value)
		

func load_localization() -> void:
	for section_key: String in config_file_api.get_section_keys(GameSettings.LocalizationSection):
		var config_value = get_localization_section(section_key)
		
		match section_key:
			GameSettings.CurrentLanguageSetting:
				TranslationServer.set_locale(config_value)
				
		updated_setting_section.emit(GameSettings.LocalizationSection, section_key, config_value)
		

func load_keybindings() -> void:
	var current_input_map_actions: Array[StringName] =_get_input_map_actions()
	
	GameSettings.DefaultSettings[GameSettings.DefaultInputMapActionsSetting] = get_keybindings_section(GameSettings.DefaultInputMapActionsSetting)
	
	for action: String in config_file_api.get_section_keys(GameSettings.KeybindingsSection):
		## Update default action values to take into account new input maps loaded from the last project update
		if action == GameSettings.DefaultInputMapActionsSetting:
			for default_action: StringName in GameSettings.DefaultSettings[GameSettings.DefaultInputMapActionsSetting]:
				if not InputMap.has_action(default_action) or InputMap.action_get_events(default_action).is_empty():
					GameSettings.DefaultSettings[GameSettings.DefaultInputMapActionsSetting].erase(default_action)
			
			continue
			
		var keybinding: String = get_keybindings_section(action)
		
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
		else:
			config_file_api.set_value(GameSettings.KeybindingsSection, action, null)
			
		current_input_map_actions.erase(action)
		
		if keybinding.contains(KeybindingSeparator):
			for value: String in keybinding.split(KeybindingSeparator):
				_add_keybinding_event(action, value.split(InputEventSeparator))
		else:
			_add_keybinding_event(action, keybinding.split(InputEventSeparator))
			
	if current_input_map_actions.size():
		current_input_map_actions.map(create_keybinding_events_for_action)
	
#endregion

#region Section Getters
func get_section(section: String, key: String) -> Variant:
	return config_file_api.get_value(section, key)
	

func get_audio_section(key: String) -> Variant:
	return get_section(GameSettings.AudioSection, key)


func get_keybindings_section(key: String) -> Variant:
	return get_section(GameSettings.KeybindingsSection, key)


func get_graphics_section(key: String) -> Variant:
	return get_section(GameSettings.GraphicsSection, key)


func get_accessibility_section(key: String) -> Variant:
	return get_section(GameSettings.AccessibilitySection, key)


func get_controls_section(key: String) -> Variant:
	return get_section(GameSettings.ControlsSection, key)


func get_localization_section(key: String) -> Variant:
	return get_section(GameSettings.LocalizationSection, key)
	
	
func get_analytics_section(key: String) -> Variant:
	return get_section(GameSettings.AnalyticsSection, key)

#endregion
	
#region Section updaters
func update_setting_section(section:String, key: String, value: Variant) -> void:
	config_file_api.set_value(section, key, value)
	updated_setting_section.emit(section, key, value)


func update_audio_section(key: String, value: Variant) -> void:
	update_setting_section(GameSettings.AudioSection, key, value)
	

func update_keybindings_section(key: String, value: Variant) -> void:
	update_setting_section(GameSettings.KeybindingsSection, key, value)
	

func update_graphics_section(key: String, value: Variant) -> void:
	update_setting_section(GameSettings.GraphicsSection, key, value)

	
func update_accessibility_section(key: String, value: Variant) -> void:
	update_setting_section(GameSettings.AccessibilitySection, key, value)
	

func update_controls_section(key: String, value: Variant) -> void:
	update_setting_section(GameSettings.ControlsSection, key, value)
	

func update_analytics_section(key: String, value: Variant) -> void:
	update_setting_section(GameSettings.AnalyticsSection, key, value)


func update_localization_section(key: String, value: Variant) -> void:
	update_setting_section(GameSettings.LocalizationSection, key, value)

#endregion

#region Private functions
func _add_keybinding_event(action: String, keybinding_type: Array[String] = []):
	if not InputMap.has_action(action):
		return
		
	var keybinding_modifiers_regex = RegEx.new()
	keybinding_modifiers_regex.compile(r"\b(Shift|Ctrl|Alt)\+\b")
	
	match keybinding_type[0]:
		"InputEventKey":
			var input_event_key = InputEventKey.new()
			input_event_key.keycode = OS.find_keycode_from_string(OmniKitStringHelper.str_replace(keybinding_type[1].strip_edges(), keybinding_modifiers_regex, func(_text: String): return ""))
			input_event_key.alt_pressed = not OmniKitStringHelper.equals_ignore_case(keybinding_type[1], "alt") and keybinding_type[1].containsn("alt")
			input_event_key.ctrl_pressed = not OmniKitStringHelper.equals_ignore_case(keybinding_type[1], "ctrl") and keybinding_type[1].containsn("ctrl")
			input_event_key.shift_pressed = not OmniKitStringHelper.equals_ignore_case(keybinding_type[1], "shift") and keybinding_type[1].containsn("shift")
			input_event_key.meta_pressed =  keybinding_type[1].containsn("meta")
			
			InputMap.action_add_event(action, input_event_key)
		"InputEventMouseButton":
			var input_event_mouse_button = InputEventMouseButton.new()
			input_event_mouse_button.button_index = int(keybinding_type[1])
			
			InputMap.action_add_event(action, input_event_mouse_button)
		"InputEventJoypadMotion":
			var input_event_joypad_motion = InputEventJoypadMotion.new()
			input_event_joypad_motion.axis = int(keybinding_type[1])
			input_event_joypad_motion.axis_value = float(keybinding_type[2])
			
			InputMap.action_add_event(action, input_event_joypad_motion)
		"InputEventJoypadButton":
			var input_event_joypad_button = InputEventJoypadButton.new()
			input_event_joypad_button.button_index = int(keybinding_type[1])
			
			InputMap.action_add_event(action, input_event_joypad_button)
	

func _get_input_map_actions() -> Array[StringName]:
	return InputMap.get_actions() if include_ui_keybindings else InputMap.get_actions().filter(func(action): return !action.contains("ui_"))


func _encription_key() -> StringName:
	return (&"%s%s" % [ProjectSettings.get_setting("application/config/name"), ProjectSettings.get_setting("application/config/description")]).sha256_text()


#region Signal callbacks
func on_created_settings(path: String) -> void:
	print_rich("[b]SettingsManager:[/b] [color=green]Created[/color] a new settings file on [color=yellow][i]%s[/i][/color]" % path)
	
func on_loaded_settings(path: String) -> void:
	print_rich("[b]SettingsManager:[/b] [color=green]Loaded[/color] existing settings file from [color=yellow][i]%s[/i][/color]" % path)

	
func on_removed_settings(path: String) -> void:
	print_rich("[b]SettingsManager:[/b] [color=red]Removed[/color] settings file from [color=yellow][i]%s[/i][/color]" % path)

	
func on_updated_setting_section(_section: String, _key: String, _value: Variant) -> void:
	save_settings(config_file_path)
#endregion
