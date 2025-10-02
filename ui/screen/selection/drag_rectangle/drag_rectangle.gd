## Create a CanvasLayer and add a NinePatchRect as a child with the desired texture to display as rectangle
class_name DragRectangle extends CanvasLayer

signal drag_started
signal drag_ended(rectangle: Rect2)

## The mininum size of the rectangle to be displayed on the screen
@export var min_drag_squared: int = 164
@export var rectangle_ui: NinePatchRect

var _drag_rectangle_area: Rect2


func _unhandled_input(event: InputEvent) -> void:
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.Shoot):
		_drag_rectangle_area.position = get_viewport().get_mouse_position()
		rectangle_ui.position = _drag_rectangle_area.position
		drag_started.emit()
		
	if OmniKitInputHelper.action_pressed_and_exists(InputControls.Shoot):
		set_process(true)
	
	elif OmniKitInputHelper.action_released_and_exists(event, InputControls.Shoot):
		rectangle_ui.hide()
		set_process(false)
		drag_ended.emit(_drag_rectangle_area)


func _ready() -> void:
	set_process(false)
	rectangle_ui.hide()


func _process(_delta: float) -> void:
	draw_rectangle_selection_area()


func draw_rectangle_selection_area() -> void:
	_drag_rectangle_area.size = get_viewport().get_mouse_position() - _drag_rectangle_area.position
	## Update the patch rect on each frame 
	rectangle_ui.visible = _drag_rectangle_area.size.length_squared() > min_drag_squared
	rectangle_ui.size = _drag_rectangle_area.size.abs()
	rectangle_ui.scale.x = -1 if _drag_rectangle_area.size.x < 0 else 1
	rectangle_ui.scale.y = -1 if _drag_rectangle_area.size.y < 0 else 1
