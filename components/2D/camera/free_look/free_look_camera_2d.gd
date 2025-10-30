class_name FreeLookCamera2D extends Camera2D


@export var speed: float
	#set(value):
		#speed = clampf(value, min_speed, max_speed)
@export var min_speed: float
@export var max_speed: float
@export var speed_increase_per_step: float = 0.1
@export var toggle_activation_key: Key = KEY_TAB
@export var move_forward_key: Key = KEY_W
@export var move_back_key: Key = KEY_S
@export var move_left_key: Key = KEY_A
@export var move_right_key: Key = KEY_D
@export var increment_speed_key: MouseButton = MOUSE_BUTTON_WHEEL_UP
@export var decrement_speed_key: MouseButton = MOUSE_BUTTON_WHEEL_DOWN

var motion: Vector2 = Vector2.ZERO
var view_motion: Vector2


func _input(event):
	if event is InputEventKey:
		var motion_value := int(event.pressed) # translate bool into 1 or 0
		
		match event.keycode:
			move_forward_key:
				motion.y = -motion_value
			move_back_key:
				motion.y = motion_value
			move_right_key:
				motion.x = motion_value
			move_left_key:
				motion.x = -motion_value
				
	if OmniKitInputHelper.is_mouse_wheel_up(event):
		zoom += Vector2.ONE * 0.2
		zoom.x = maxf(0, zoom.x)
		zoom.y = maxf(0, zoom.y)
	elif OmniKitInputHelper.is_mouse_wheel_down(event):
		zoom -= Vector2.ONE * 0.2
		zoom.x = maxf(0, zoom.x)
		zoom.y = maxf(0, zoom.y)


func _process(delta: float) -> void:
	position += motion * speed * delta
