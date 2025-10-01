class_name FirstPersonDebugUI extends Control

@export var actor: FirstPersonController
@export var speed_unit: OmniKitVelocityHelper.SpeedUnit = OmniKitVelocityHelper.SpeedUnit.KilometersPerHour
@onready var current_state_label: Label = %CurrentStateLabel
@onready var velocity_label: Label = %VelocityLabel
@onready var speed_label: Label = %SpeedLabel


func _unhandled_input(_event: InputEvent) -> void:
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.FirstPersonDebug):
		visible = !visible


func _ready() -> void:
	actor.ready.connect(
		func():
			display_motion_state(actor.motion_state_machine.current_state.name)
			actor.motion_state_machine.state_changed.connect(on_motion_state_changed)
			, CONNECT_ONE_SHOT)
			
	visibility_changed.connect(on_visibility_changed)


func _process(_delta: float) -> void:
	display_velocity()
	display_speed()


func display_velocity() -> void:
	var velocity = actor.velocity
	var velocity_snapped : Array[float] = [
		snappedf(velocity.x, 0.001),
		snappedf(velocity.y, 0.001),
		snappedf(velocity.z, 0.001)
	]
	
	velocity_label.text = "Velocity: (%s, %s, %s)" % [velocity_snapped[0], velocity_snapped[1], velocity_snapped[2]]


func display_speed() -> void:
	match speed_unit:
		OmniKitVelocityHelper.SpeedUnit.KilometersPerHour:
			speed_label.text = "Speed: %d km/h" % OmniKitVelocityHelper.current_speed_on_kilometers_per_hour(actor.velocity)
		OmniKitVelocityHelper.SpeedUnit.MilesPerHour:
			speed_label.text = "Speed: %d mp/h" % OmniKitVelocityHelper.current_speed_on_miles_per_hour(actor.velocity)


func display_motion_state(new_state: String) -> void:
	current_state_label.text = "Current state: %s" % new_state


func on_motion_state_changed(_from: MachineState, to: MachineState) -> void:
	display_motion_state(to.name)


func on_visibility_changed() -> void:
	set_process(visible)
