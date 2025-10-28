class_name ThirdPersonController extends CharacterBody3D

@export var skin: Node3D:
	set(value):
		skin = value
		
		if skin and is_node_ready():
			skin_model_forward = calculate_skin_model_forward(skin)
			
@export var skin_rotation_speed: float = 5.0

@onready var camera: Camera3D = %Camera3D
@onready var motion_state_machine: Machina = $MotionStateMachine

var motion_input: OmniKitMotionInput = OmniKitMotionInput.new(self)
var skin_model_forward: Vector3


func _ready() -> void:
	if skin:
		skin_model_forward = calculate_skin_model_forward(skin)
	
	
func _process(_delta: float) -> void:
	motion_input.update()


func get_ground_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func is_falling() -> bool:
	if not is_on_floor():
		var opposite_up_direction = OmniKitVectorHelper.up_direction_opposite_vector3(up_direction)
		
		var opposite_to_gravity_vector: bool = (opposite_up_direction.is_equal_approx(Vector3.DOWN) and velocity.y < 0) \
			or (opposite_up_direction.is_equal_approx(Vector3.UP) and velocity.y > 0) \
			or (opposite_up_direction.is_equal_approx(Vector3.LEFT) and velocity.x < 0) \
			or (opposite_up_direction.is_equal_approx(Vector3.RIGHT) and velocity.x > 0)
		
		return opposite_to_gravity_vector
		
	return false
	

func look_at_mouse(origin_camera: Camera3D) -> void:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var origin: Vector3 = origin_camera.project_ray_origin(mouse)
	var world_direction: Vector3 = origin_camera.project_ray_normal(mouse)

	if world_direction.y != 0:
		var distance: float = -origin.y / world_direction.y
		var look_position: Vector3 = origin + world_direction * distance
		
		look_at(Vector3(look_position.x, global_position.y, look_position.z))


func move_direction_based_on_camera(origin_camera: Camera3D, input_direction: Vector2) -> Vector3:
	var forward: Vector3 = origin_camera.global_basis.z
	var right: Vector3 = origin_camera.global_basis.x
	var move_direction = forward * input_direction.y + right * input_direction.x
	move_direction.y = 0
	move_direction = move_direction.normalized()
	
	return move_direction


func rotate_skin(target_direction: Vector3, delta: float = get_physics_process_delta_time()) -> void:
	if skin:
		if skin_model_forward == null or skin_model_forward.is_zero_approx():
			skin_model_forward = calculate_skin_model_forward(skin)
			
		var target_angle: float = skin_model_forward.signed_angle_to(target_direction, Vector3.UP)
		
		if skin_rotation_speed > 0:
			skin.global_rotation.y = lerp_angle(
				skin.global_rotation.y, 
				target_angle, 
				delta * skin_rotation_speed)
		else:
			skin.global_rotation.y = target_angle

## This return the vector to rotate the body to the correct direction when
## moving the character or rotate into.
func calculate_skin_model_forward(target_skin: Node3D, use_global_transform: bool = false) -> Vector3:
	var target_transform: Transform3D = target_skin.global_transform if use_global_transform else target_skin.transform
	var forward: Vector3 = target_transform.basis.z.normalized()
	
	if forward.dot(Vector3.FORWARD) > 0.0:
		forward *= -1.0
			
	return forward
	
	
func detect_run() -> bool:
	return is_on_floor() \
		and not motion_input.input_direction.is_zero_approx() \
		and OmniKitInputHelper.action_pressed_and_exists(InputControls.RunAction)
