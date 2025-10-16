## This node usually is placed in the center of the scenario we want to move around with panning
## and place the camera upwards relative to this node position
## SETUP: AerialCamera (Only update the position) 
##                    -> CameraRotation (Node3D, apply desired rotation(xy) here) 
##						-> CameraZoomPivot(Node3D, Set position.z to manage the camera elevation)
##						   -> Camera3D (This script never touches the camera transform directly)
@icon("res://components/3D/camera/aerial/aerial_camera.svg")
class_name AerialCamera extends Node3D

signal changed_movement_mode(new_mode: MovementMode)

@export var camera: Camera3D
@export var camera_rotation_pivot: Node3D
@export var camera_zoom_pivot: Node3D

## For a true isometric projection use arctan(1 / sqrt(2) ) = 35.264º.
## The configuration 45º- 45º rule leads to a dimetric projection.
@export_range(-180, 0, 0.01, "degrees") var vertical_rotation_angle: float = -35.264:
	set(value):
		vertical_rotation_angle = value
		if camera_rotation_pivot and is_node_ready():
			camera_rotation_pivot.rotation_degrees.x = vertical_rotation_angle
@export_range(-180, 180.0, 0.01, "degrees") var min_vertical_rotation_angle: float = -1.0:
	set(value):
		min_vertical_rotation_angle = value
		
		if camera_rotation_pivot and is_node_ready():
			camera_rotation_pivot.rotation_degrees.x = clampf(
				camera_rotation_pivot.rotation_degrees.x, 
				min_vertical_rotation_angle, 
				max_vertical_rotation_angle
				)
@export_range(-180, 180.0, 0.01, "degrees") var max_vertical_rotation_angle: float = -89.0:
	set(value):
		max_vertical_rotation_angle = value
		camera_rotation_pivot.rotation_degrees.x = clampf(
			camera_rotation_pivot.rotation_degrees.x, 
			min_vertical_rotation_angle, 
			max_vertical_rotation_angle
			)

@export var movement_mode: MovementMode = MovementMode.Free:
	set(value):
		if value != movement_mode:
			movement_mode = value
			set_process(not is_locked)
			changed_movement_mode.emit(movement_mode)
@export_category("Movement")
@export var movement_speed: float = 0.3
@export var smooth_movement: bool = true
@export var smooth_movement_lerp: float = 8.0
@export_category("Rotation")
@export var rotation_speed: float = 5.0
@export var smooth_rotation: bool = true
@export var smooth_rotation_lerp: float = 6.0
@export_category("Drag")
@export var smooth_drag: bool = true
## When enabled, drag speed dynamically scales based on the current zoom level.
## The camera pans faster when zoomed out and slower when zoomed in.
@export var zoom_based_drag_speed: bool = true
@export var smooth_drag_lerp: float = 6.0
@export var drag_speed: float = 0.03
@export_category("Edge panning")
## Moves the camera when the mouse cursor reaches the viewport borders.
## Useful for RTS-style navigation.
@export var edge_panning: bool = true
## Mouse modes that allow edge panning detection.
@export var edge_panning_mouse_modes: Array[Input.MouseMode] = [
	Input.MOUSE_MODE_CONFINED,
	Input.MOUSE_MODE_CONFINED_HIDDEN,
	Input.MOUSE_MODE_VISIBLE
]

## Margin (in pixels) from the viewport borders to trigger edge panning.
@export var edge_size: float = 5.0
## Movement speed applied while edge panning.
@export var scroll_speed: float = 0.25
@export_category("Zoom")
@export var smooth_zoom: bool = true
@export var smooth_zoom_lerp: float = 6.0
@export var zoom_in_perspective_step: float = 2.0
@export var zoom_out_perspective_step: float = 2.0
@export var min_zoom_position_z: float = 15
@export var max_zoom_position_z: float = 9.0
## Optional curve that modifies vertical tilt dynamically as the camera zooms.
## Leave empty to keep tilt constant during zoom.
@export var perspective_zoom_curve: Curve
@export_category("Ortographic zoom")
@export var zoom_in_ortographic_step: float = 2.5
@export var zoom_out_ortographic_step: float = 2.5
@export var min_zoom_size: float = 10.0
@export var max_zoom_size: float = 30.0


enum MovementMode {
	Free, ## Responds to input direction (WASD or stick)
	Drag ## Moves following mouse drag motion
}

var screen_size: Vector2
var screen_ratio: float
var dragging: bool = false
var rotating: bool = false

## Panning camera drag
var right_vector: Vector3
var forward_vector: Vector3

var is_locked: bool = false:
	set(value):
		is_locked = value
		set_process_input(not is_locked)
		set_process(not is_locked)


var mouse_sensitivity: float = 0.05
var invert_x_axis: bool = false
var invert_y_axis: bool = false

### This values are used for the linear interpolation in the _process
var target_position: Vector3 
var target_rotation: float 
var target_zoom: float 


func _input(event: InputEvent) -> void:
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomInCamera) or \
		OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomOutCamera):
			
		match camera.projection:
			Camera3D.ProjectionType.PROJECTION_ORTHOGONAL:
				if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomInCamera):
					target_zoom -= zoom_in_ortographic_step
					
				elif OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomOutCamera):
					target_zoom += zoom_in_ortographic_step
					
				target_zoom = clampf(target_zoom, max_zoom_size, min_zoom_size)
				
				if not smooth_zoom:
					camera.size = target_zoom
				
			Camera3D.ProjectionType.PROJECTION_PERSPECTIVE:
				if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomInCamera):
					target_zoom -= zoom_in_perspective_step
					
				elif OmniKitInputHelper.action_just_pressed_and_exists(InputControls.ZoomOutCamera):
					target_zoom += zoom_out_perspective_step
					
				target_zoom = clampf(target_zoom, max_zoom_position_z, min_zoom_position_z)
				
				if not smooth_zoom:
					camera_zoom_pivot.position.z = target_zoom
					
	
	if event is InputEventMouseMotion:
		if dragging:
			drag_camera_movement(event.relative)
	
		if rotating:
			rotate_camera(event.relative, rotation_speed, mouse_sensitivity)
				

func _ready() -> void:
	if camera == null:
		camera = OmniKitNodeTraversal.first_node_of_type(self, Camera3D.new())
	
	OmniKitInputHelper.show_mouse_cursor()
	camera_rotation_pivot.rotation_degrees.x = vertical_rotation_angle

	screen_size = OmniKitWindowManager.screen_size()
	screen_ratio = OmniKitWindowManager.screen_ratio()
	
	set_process(not is_locked)
	set_process_input(not is_locked)
	
	target_position = position
	target_rotation = camera_rotation_pivot.rotation.y
	
	match camera.projection:
		Camera3D.ProjectionType.PROJECTION_ORTHOGONAL:
			target_zoom = camera.size
					
		Camera3D.ProjectionType.PROJECTION_PERSPECTIVE:
			target_zoom = camera_zoom_pivot.position.z
			
	mouse_sensitivity = SettingsManager.get_accessibility_section(GameSettings.MouseSensivitySetting)
	invert_x_axis = SettingsManager.get_accessibility_section(GameSettings.InvertXAxisSetting)
	invert_y_axis = SettingsManager.get_accessibility_section(GameSettings.InvertYAxisSetting)
	
	SettingsManager.updated_setting_section.connect(on_setting_section_updated)
	OmniKitWindowManager.size_changed.connect(on_window_size_changed)


func _process(delta: float) -> void:
	rotating = OmniKitInputHelper.action_pressed_and_exists(InputControls.RotateAerialCamera)
	dragging = movement_mode_is_drag() and OmniKitInputHelper.action_pressed_and_exists(InputControls.DragAerialCamera)
	
	if edge_panning and Input.mouse_mode in edge_panning_mouse_modes:
		edge_panning_movement(scroll_speed)
	
	if movement_mode_is_free():
		camera_movement(
			Input.get_vector(InputControls.MoveLeft, InputControls.MoveRight, InputControls.MoveForward, InputControls.MoveBack), 
			delta
			)
	
	elif movement_mode_is_drag():
		if smooth_drag:
			position = position.lerp(target_position, delta * smooth_drag_lerp)
		else:
			position = target_position
	
	if smooth_rotation:
		camera_rotation_pivot.rotation.y = lerp(camera_rotation_pivot.rotation.y, target_rotation, delta * smooth_rotation_lerp)
		
	if smooth_zoom:
		match camera.projection:
			Camera3D.ProjectionType.PROJECTION_ORTHOGONAL:
				camera.size = lerp(camera.size, target_zoom, delta * smooth_zoom_lerp)
			Camera3D.ProjectionType.PROJECTION_PERSPECTIVE:
				camera_zoom_pivot.position.z = lerpf(camera_zoom_pivot.position.z, target_zoom, delta * smooth_zoom_lerp)

		if perspective_zoom_curve:
			camera_rotation_pivot.rotation_degrees.x = lerpf(
				camera_rotation_pivot.rotation_degrees.x,
				perspective_zoom_curve.sample(camera_zoom_pivot.position.z), 
				delta * smooth_zoom_lerp
				)
			
			camera_rotation_pivot.rotation_degrees.x = clampf(
				camera_rotation_pivot.rotation_degrees.x, 
				max_vertical_rotation_angle, 
				min_vertical_rotation_angle)


func camera_movement(direction: Vector2, delta: float = get_process_delta_time()) -> void:
	var movement_direction: Vector3 = (camera_rotation_pivot.transform.basis * Vector3(direction.x, 0, direction.y)).normalized()
	movement_direction.y = 0
	
	target_position += movement_speed * movement_direction
	
	if smooth_movement:
		position = position.lerp(target_position, delta * smooth_movement_lerp)
	else:
		position = target_position


func drag_camera_movement(mouse_relative: Vector2) -> void:
	if invert_x_axis:
		mouse_relative.x = -mouse_relative.x
	if invert_y_axis:
		mouse_relative.y = -mouse_relative.y
		
	var offset: Vector3 = camera.global_position - global_position
	right_vector =  Basis(Vector3.UP, camera_rotation_pivot.global_rotation.y).x
	forward_vector = Vector3(offset.x, 0, offset.z).normalized()
	
	if zoom_based_drag_speed:
		var zoom_factor: float = remap(camera_zoom_pivot.position.z, max_zoom_position_z, min_zoom_position_z, 0.5, 1.5)
		
		target_position += right_vector * -mouse_relative.x * (drag_speed * zoom_factor) \
			+ forward_vector * -mouse_relative.y * (drag_speed * zoom_factor) / screen_ratio;
	else:
		target_position += right_vector * -mouse_relative.x * drag_speed \
			+ forward_vector * -mouse_relative.y * drag_speed  / screen_ratio;


func edge_panning_movement(speed: float = scroll_speed) -> void:
	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	var scroll_direction: Vector3 = Vector3.ZERO
	
	if mouse_position.x < edge_size:
		scroll_direction.x = -1
	elif mouse_position.x > screen_size.x - edge_size:
		scroll_direction.x = 1
		
	if mouse_position.y < edge_size:
		scroll_direction.z = -1
	elif mouse_position.y > screen_size.y - edge_size:
		scroll_direction.z = 1
		
	var movement_direction: Vector3 = (Basis(Vector3.UP, camera_rotation_pivot.global_rotation.y) * scroll_direction).normalized()
	target_position += movement_direction * speed


func rotate_camera(mouse_relative: Vector2, speed: float = rotation_speed, mouse_sens: float = mouse_sensitivity) -> void:
	if invert_x_axis:
		mouse_relative.x = -mouse_relative.x
	if invert_y_axis:
		mouse_relative.y = -mouse_relative.y

	if smooth_rotation:
		target_rotation += -mouse_relative.x * (mouse_sens / 1000) * speed
	else:
		camera_rotation_pivot.rotate_y(-mouse_relative.x * (mouse_sens / 1000) * speed)
	

func lock() -> void:
	is_locked = true
	
	
func unlock() -> void:
	is_locked = false
	
	
func movement_mode_is_free() -> bool:
	return movement_mode == MovementMode.Free


func movement_mode_is_drag() -> bool:
	return movement_mode == MovementMode.Drag


func on_window_size_changed() -> void:
	screen_size = OmniKitWindowManager.screen_size()
	screen_ratio = OmniKitWindowManager.screen_ratio()


func on_setting_section_updated(_section: String, key: String, value: Variant) -> void:
	match key:
		GameSettings.MouseSensivitySetting:
			mouse_sensitivity = value
		#GameSettings.ControllerSensivitySetting:
			#controller_joystick_sensitivity = value
		GameSettings.InvertXAxisSetting:
			invert_x_axis = value
		GameSettings.InvertYAxisSetting:
			invert_y_axis = value
