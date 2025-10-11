class_name FirstPersonController extends CharacterBody3D

const GroupName: StringName = &"player"

@export var head_stand_height: float = 1.7
@export var head_crouch_height: float = 0.8
@export_category("Motion")
@export var run: bool = true
@export var dash: bool = true
@export var air_dash: bool = true
@export var jump: bool = true
@export var crouch: bool = true
@export var crawl: bool = false
@export var slide: bool = true
@export var wall_run: bool = false
@export var wall_jump: bool = false
@export var wall_climb: bool = false
@export var surf: bool = false
@export var swim: bool = false
@export var stairs: bool = true
@export var ladder_climb: bool = false
@export_category("Camera effects")
@export var motion_tilt: bool = true
@export var headbob: bool = true
@export var fall_kick: bool = true

@onready var motion_state_machine: Machina = $MotionStateMachine
@onready var camera_controller: CameraController = $Head/CameraController
@onready var mouse_capture: MouseCaptureComponent = $MouseCaptureComponent
@onready var weapon_manager: WeaponManager = $WeaponManager

@onready var head: Node3D = $Head
@onready var motion_tilt_effect: MotionTilt = $Head/MotionTilt
@onready var head_bob_motion: HeadBob = $Head/HeadBob
@onready var fall_kick_effect: FallKick = $Head/FallKick
@onready var damage_kick: DirectionalDamageKick = $Head/DirectionalDamageKick
@onready var screen_shake: ScreenShake = $Head/ScreenShake

@onready var body_shape: CollisionShape3D = $BodyShape
@onready var crouch_shape: CollisionShape3D = $CrouchShape
@onready var ceil_detector: ShapeCast3D = $CeilDetector
@onready var interactor: RayCastInteractor3D = $Head/Eyes/Camera3D/RayCastInteractor3D
@onready var grabbable_interactor: GrabbableRayCastInteractor3D = $Head/Eyes/Camera3D/GrabbableRayCastInteractor3D
@onready var hand_grabber: Grabber3D = $Head/Eyes/Camera3D/HandGrabber
@onready var weapon_right_hand: FirstPersonWeaponHand = $Head/Eyes/Camera3D/WeaponRightHand
@onready var weapon_left_hand: FirstPersonWeaponHand = $Head/Eyes/Camera3D/WeaponLeftHand

var motion_input: OmniKitMotionInput =  OmniKitMotionInput.new(self)
var was_grounded: bool = false
var is_grounded: bool = false
var on_wall_only: bool = false
var last_wall_normal: Vector3 = Vector3.ZERO


func _enter_tree() -> void:
	Globals.player = self
	
	
func _ready() -> void:
	collision_layer = Globals.player_collision_layer
	
	head_bob_motion.enabled = headbob
	motion_tilt_effect.enabled = motion_tilt
	fall_kick_effect.enabled = fall_kick
	
	motion_state_machine.register_transition(WalkState, RunState, WalkToRunTransition.new())
	motion_state_machine.state_changed.connect(on_motion_state_changed)
	

func _process(_delta: float) -> void:
	motion_input.update()


func _physics_process(_delta: float) -> void:
	was_grounded = is_grounded
	is_grounded = is_on_floor()
	on_wall_only = is_on_wall_only()
	
	if on_wall_only:
		last_wall_normal = get_wall_normal()


func get_ground_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func is_falling() -> bool:
	if not is_grounded:
		var opposite_up_direction = OmniKitVectorHelper.up_direction_opposite_vector3(up_direction)
		
		var opposite_to_gravity_vector: bool = (opposite_up_direction.is_equal_approx(Vector3.DOWN) and velocity.y < 0) \
			or (opposite_up_direction.is_equal_approx(Vector3.UP) and velocity.y > 0) \
			or (opposite_up_direction.is_equal_approx(Vector3.LEFT) and velocity.x < 0) \
			or (opposite_up_direction.is_equal_approx(Vector3.RIGHT) and velocity.x > 0)
		
		return opposite_to_gravity_vector
		
	return false


func is_aiming() -> bool:
	if weapon_right_hand:
		return weapon_right_hand.is_aiming()
	elif weapon_left_hand:
		return weapon_left_hand.is_aiming()
	else:
		return false


func can_wall_jump() -> bool:
	if not wall_jump or not on_wall_only or last_wall_normal.is_zero_approx():
		return false
		
	if last_wall_normal.dot(head.global_basis.z) < 0:
		return false

	return true


func on_motion_state_changed(_from: MachineState, next: MachineState) -> void:
	if next is GroundState:
		if motion_tilt:
			motion_tilt_effect.enable()
		if headbob:
			head_bob_motion.enable()
		
		ceil_detector.enabled = next is CrouchState
	else:
		motion_tilt_effect.disable()
		head_bob_motion.disable()
		ceil_detector.enabled = false
