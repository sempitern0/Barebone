class_name InputRemapper extends Control

var ui_remappers: Dictionary[StringName, InputActionKeybindingDisplay] = {}


func _ready() -> void:
	for keybinding_display: InputActionKeybindingDisplay in OmniKitNodeTraversal.find_nodes_of_custom_class(self, InputActionKeybindingDisplay):
		ui_remappers[keybinding_display.action] = keybinding_display
		keybinding_display.remapped.connect(on_remapped_input_action, CONNECT_DEFERRED)
	
	
func reset_to_default_keybindings() -> void:
	var default_input_map_actions: Dictionary = GameSettings.DefaultSettings[GameSettings.DefaultInputMapActionsSetting]
	
	if default_input_map_actions.size():
		SettingsManager.reset_keybinding_events_to_default()
		
	for input_action: StringName in default_input_map_actions:
		if ui_remappers.has(input_action):
			ui_remappers[input_action].init_keybinding()
			
	
## Manage the switch logic if the new event assigned already existed in another action
func on_remapped_input_action(
	remapped_action: StringName,
	new_event: InputEvent,
	previous_event: InputEvent,
	switched_keybind: bool
	) -> void:
	
	if switched_keybind:
		return
		
	var switched_with_existing_input: bool = false
	
	for existing_action: StringName in InputMap.get_actions()\
		.filter(func(input_action): return !input_action.contains("ui_") and input_action != remapped_action):
		
		if switched_with_existing_input:
			break
	
		var all_inputs_for_action: Array[InputEvent] = OmniKitInputHelper.get_all_inputs_for_action(existing_action)
		
		for existing_input: InputEvent in all_inputs_for_action:
			var new_event_key: String = OmniKitInputHelper.readable_key(new_event)
			var existing_event_key: String = OmniKitInputHelper.readable_key(existing_input)
			
			if ui_remappers.has(existing_action) and (new_event.is_match(existing_input) or \
				(not new_event_key.is_empty() and not existing_event_key.is_empty() and new_event_key == existing_event_key)):
				
				ui_remappers[existing_action].update_keybinding(previous_event, true)
				switched_with_existing_input = true
