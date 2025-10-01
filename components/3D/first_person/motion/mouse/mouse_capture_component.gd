@icon("res://components/3D/first_person/motion/mouse/mouse_capture.svg")
class_name MouseCaptureComponent extends Node

@export var capture_mouse_on_ready: bool = true

@onready var root_node: Window = get_tree().root

var mouse_input: Vector2 = Vector2.ZERO
var twist_input: float
var pitch_input: float
var mouse_sensitivity: float = 3.0
var invert_x_axis: bool = false
var invert_y_axis: bool = false
var controller_joystick_sensitivity: float = 5.0


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			show_mouse_cursor()
		NOTIFICATION_UNPAUSED:
			capture_mouse()


func _unhandled_key_input(_event: InputEvent) -> void:
	if OmniKitInputHelper.action_just_pressed_and_exists(&"ui_cancel"):
		switch_mouse_capture_mode()
		
		
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and OmniKitInputHelper.is_mouse_captured():
		var motion: InputEventMouseMotion = event.xformed_by(root_node.get_final_transform())
		mouse_input += motion.relative
		
		var mouse_sens: float = mouse_sensitivity / 1000 # radians/pixel, 3 becomes 0.003
		twist_input = -mouse_input.x * mouse_sens ## Giro
		pitch_input = -mouse_input.y * mouse_sens ## Cabeceo
		
		if invert_x_axis:
			twist_input *= -1
		if invert_y_axis:
			pitch_input *= -1

	
func _ready() -> void:
	if capture_mouse_on_ready:
		capture_mouse()
		
	mouse_sensitivity = SettingsManager.get_accessibility_section(GameSettings.MouseSensivitySetting)
	controller_joystick_sensitivity = SettingsManager.get_accessibility_section(GameSettings.ControllerSensivitySetting)
	invert_x_axis = SettingsManager.get_accessibility_section(GameSettings.InvertXAxisSetting)
	invert_y_axis = SettingsManager.get_accessibility_section(GameSettings.InvertYAxisSetting)


func _process(_delta: float) -> void:
	mouse_input = Vector2.ZERO
	
	
func capture_mouse() -> void:
	OmniKitInputHelper.capture_mouse()
	set_process(true)


func show_mouse_cursor() -> void:
	set_process(false)
	OmniKitInputHelper.show_mouse_cursor()
	mouse_input = Vector2.ZERO
	

func switch_mouse_capture_mode() -> void:
	if OmniKitInputHelper.is_mouse_visible():
		capture_mouse()
	else:
		show_mouse_cursor()


func on_setting_section_updated(_section: String, key: String, value: Variant) -> void:
	match key:
		GameSettings.MouseSensivitySetting:
			mouse_sensitivity = value
		GameSettings.ControllerSensivitySetting:
			controller_joystick_sensitivity = value
		GameSettings.InvertXAxisSetting:
			invert_x_axis = value
		GameSettings.InvertYAxisSetting:
			invert_y_axis = value
