class_name AerialCamera2D extends Camera2D

@export_group("Zoom")
@export var smooth_camera_zoom: bool = true
@export var smooth_camera_zoom_lerp: float = 6.0
@export var camera_zoom_in_perspective_step: float = 0.02
@export var camera_zoom_out_perspective_step: float = 0.02
@export var camera_max_zoom_in: float = 0.5
@export var camera_max_zoom_out: float = 2.0
@export_group("Panning")
@export var camera_pan_enabled: bool = true
@export var smooth_camera_pan: bool = false
@export var camera_pan_speed: float = 5.0
@export var camera_pan_lerp: float = 15.0
@export_group("Edge panning")
@export var edge_panning: bool = true
@export var edge_pan_speed: float = 5.0
@export var edge_size: float = 5.0
@export var edge_panning_mouse_modes: Array[Input.MouseMode] = [
	Input.MOUSE_MODE_CONFINED,
	Input.MOUSE_MODE_CONFINED_HIDDEN,
	Input.MOUSE_MODE_VISIBLE
]

var target_zoom: Vector2 = Vector2.ONE
var target_position: Vector2
var target_pan_position: Vector2
var panning: bool = false
var screen_size: Vector2
var screen_ratio: float
var last_mouse_position: Vector2
var direction: Vector2
var edge_panning_direction: Vector2 = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if panning:
			var next_position: Vector2 = event.relative * (camera_pan_speed / (zoom.length() * screen_ratio))
			
			if smooth_camera_pan:
				target_position -= next_position
			else:
				position -= next_position
				
			last_mouse_position = event.relative
		
	if OmniKitInputHelper.is_mouse_wheel_up(event):
		if smooth_camera_zoom:
			target_zoom += Vector2.ONE * camera_zoom_in_perspective_step
		else:
			zoom += Vector2.ONE * camera_zoom_in_perspective_step
			zoom = zoom.clamp(Vector2.ONE * camera_max_zoom_in, Vector2.ONE * camera_max_zoom_out)
			
	elif OmniKitInputHelper.is_mouse_wheel_down(event):
		if smooth_camera_zoom:
			target_zoom -= Vector2.ONE * camera_zoom_out_perspective_step
		else:
			zoom -= Vector2.ONE * camera_zoom_out_perspective_step
			zoom = zoom.clamp(Vector2.ONE * camera_max_zoom_in, Vector2.ONE * camera_max_zoom_out)


func _ready() -> void:
	screen_size = OmniKitWindowManager.screen_size()
	screen_ratio = OmniKitWindowManager.screen_ratio()
	
	target_zoom = zoom
	target_position = position

	OmniKitWindowManager.size_changed.connect(on_window_size_changed)


func _process(delta: float) -> void:
	if edge_panning:
		var mouse_position: Vector2 = get_viewport().get_mouse_position()
		edge_panning_direction = Vector2.ZERO
		
		if mouse_position.x < edge_size:
			edge_panning_direction.x = -1
		elif mouse_position.x > screen_size.x - edge_size:
			edge_panning_direction.x = 1
			
		if mouse_position.y < edge_size:
			edge_panning_direction.y = -1
		elif mouse_position.y > screen_size.y - edge_size:
			edge_panning_direction.y = 1
		
		var next_position: Vector2 = edge_panning_direction * edge_pan_speed * delta
		
		if smooth_camera_pan:
			target_position += next_position
		else:
			position += next_position
		
	panning = camera_pan_enabled and OmniKitInputHelper.action_pressed_and_exists(InputControls.Aim)
	
	if smooth_camera_pan:
		position = lerp(position, target_position, delta * camera_pan_lerp)
	
	if smooth_camera_zoom:
		zoom = lerp(zoom, target_zoom, delta * smooth_camera_zoom_lerp)
		zoom = zoom.clamp(Vector2.ONE * camera_max_zoom_in, Vector2.ONE * camera_max_zoom_out)


func on_window_size_changed() -> void:
	screen_size = OmniKitWindowManager.screen_size()
	screen_ratio = OmniKitWindowManager.screen_ratio()
