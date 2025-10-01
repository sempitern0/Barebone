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

var motion_input: OmniKitMotionInput =  OmniKitMotionInput.new(self)
var was_grounded: bool = false
var is_grounded: bool = false


func _enter_tree() -> void:
	Globals.player = self
	
	
func _ready() -> void:
	collision_layer = Globals.player_collision_layer
	
	#head_bob_motion.enabled = headbob
	#motion_tilt_effect.enabled = motion_tilt
	#fall_kick_effect.enabled = fall_kick
	#
	#motion_state_machine.register_transition(WalkState, RunState, WalkToRunTransition.new())
	#motion_state_machine.state_changed.connect(on_motion_state_changed)
	#

func _process(_delta: float) -> void:
	motion_input.update()
