class_name InputActionKeybindingDisplay extends HBoxContainer

signal remapped(target_action: StringName, new_event: InputEvent, previous_event: InputEvent, switched_keybind: bool)

@export var action: StringName = &""
@export var keyboard: bool = true
@export var gamepad: bool = false

@onready var action_label: Label = %ActionLabel
@onready var input_key_button: Button = %InputKeyButton

enum KeybindingStates {
	Neutral,
	WaitingForInput
}

var keyboard_keybinding: InputEvent = null
var gamepad_keybinding: InputEvent = null
var current_state: KeybindingStates = KeybindingStates.Neutral:
	set(new_state):
		if current_state != new_state:
			current_state = new_state
			change_remapping_text(current_state)
			set_process_input(is_remapping())
			

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		if not is_node_ready():
			await ready
		
		display_keybindings()


func _input(event: InputEvent) -> void:
	if OmniKitInputHelper.action_just_pressed_and_exists(&"ui_cancel"):
		accept_event()
		current_state = KeybindingStates.Neutral
		return
		
	if keyboard_keybinding and event is InputEventKey:
		accept_event()
		
		if event is InputEventMouseButton and event.pressed:
			event = OmniKitInputHelper.double_click_to_single(event)
		elif OmniKitInputHelper.any_key_modifier_is_pressed() and event.pressed:
		## Important line to accept modifiers when this are keep pressed
			return
				
		update_keybinding(event)
		current_state = KeybindingStates.Neutral


func _ready() -> void:
	set_process_input(is_remapping())
	init_keybinding(action)
	
	input_key_button.pressed.connect(on_input_key_button_pressed)


func init_keybinding(target_action: StringName = action) -> void:
	var actions: Array[InputEvent] = InputMap.action_get_events(target_action)
	
	for current_action: InputEvent in actions:
		if keyboard and keyboard_keybinding == null and current_action is InputEventKey:
			keyboard_keybinding = current_action
		elif gamepad and gamepad_keybinding == null and OmniKitInputHelper.is_gamepad_input(current_action):
			gamepad_keybinding = current_action
	
	display_keybindings()
	
	
func display_keybindings() -> void:
	if not action.is_empty():
		action_label.text = tr(action.to_upper())
		
		if keyboard:
			input_key_button.text = keyboard_keybinding.as_text()
		elif gamepad:
			input_key_button.text = gamepad_keybinding.as_text()
			
		input_key_button.text = input_key_button.text.replace("(Physical)", "").strip_edges()


func update_keybinding(new_event: InputEvent, switched_keybind: bool = false) -> void:
	var previous_event: InputEvent = keyboard_keybinding
	
	if gamepad_keybinding:
		previous_event = gamepad_keybinding
	
	if keyboard_keybinding and new_event is InputEventKey:
		InputMap.action_erase_event(action, keyboard_keybinding)
		InputMap.action_add_event(action, new_event)
		keyboard_keybinding = new_event
		
	elif gamepad_keybinding and OmniKitInputHelper.is_controller_button(new_event):
		InputMap.action_erase_event(action, gamepad_keybinding)
		InputMap.action_add_event(action, new_event)
		gamepad_keybinding = new_event
	
	display_keybindings()
	SettingsManager.create_keybinding_events_for_action(action)

	remapped.emit(action, new_event, previous_event, switched_keybind)


func change_remapping_text(state: KeybindingStates) -> void:
	match state:
		KeybindingStates.Neutral:
			display_keybindings()
		KeybindingStates.WaitingForInput:
			input_key_button.text = tr("WAITING_FOR_INPUT")
	

func is_remapping() -> bool:
	return current_state == KeybindingStates.WaitingForInput


func on_input_key_button_pressed() -> void:
	current_state = KeybindingStates.WaitingForInput
