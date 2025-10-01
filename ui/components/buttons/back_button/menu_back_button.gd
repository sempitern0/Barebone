## Usage: This button can attach a control node on the linked menu parameter
## When this button is pressed, hides this menu and emits the signal "returned back"
@icon("res://ui/components/buttons/back_button/back_button.svg")
class_name MenuBackButton extends Button

signal returned_back

@export var previous_menu: Control
@export var linked_menu: Control
@export var back_input_action: StringName = &"ui_cancel"


var is_enabled: bool = true


func _unhandled_input(_event: InputEvent) -> void:
	if is_enabled and \
		visible and \
		not back_input_action.is_empty() and \
		OmniKitInputHelper.action_just_pressed_and_exists(back_input_action):
			
		go_back()
		

func _ready() -> void:
	pressed.connect(on_pressed)


func enable() -> void:
	is_enabled = true


func disable() -> void:
	is_enabled = false


func go_back() -> void:
	if linked_menu and is_enabled and visible:
		linked_menu.hide()
		
		if previous_menu:
			previous_menu.show()
			
		returned_back.emit()

	
func on_pressed() -> void:
	go_back()
