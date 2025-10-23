class_name DamageNumberLabel3D extends Label3D

@export var time_alive: float = 2.5
## Randomize the up direction when spawn this label
@export var up_direction_amount: float = 0.5:
	set(value):
		up_direction_amount = maxf(0.0, value)
@export var horizontal_displace_amount: float = 0.5:
	set(value):
		horizontal_displace_amount = maxf(0.0, value)
@export var horizontal_displacement_chance: float = 50.0
@export_range(0.0, 180.0, 0.01, "radians_as_degrees") var up_spread_angle: float = deg_to_rad(5.0)

@onready var alive_timer: Timer = $AliveTimer

var tween: Tween


func _ready() -> void:
	if not is_instance_valid(alive_timer):
		alive_timer = OmniKitTimeHelper.create_idle_timer(time_alive, false, true)
		alive_timer.name = "AliveTimer"
		add_child(alive_timer)
		alive_timer.timeout.connect(on_alive_timer_timeout)


func display(amount: String) -> void:
	if tween == null or (tween and not tween.is_running()):	
		adjust_font_size_to_camera_distance()
			
		text = amount
		alive_timer.start(time_alive)
		
		tween = create_tween()\
			.set_parallel()\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		
		## TODO - THE COLOR, OUTLINE AND OTHER DETAILS DEPENDS ON THE TYPE ON DAMAGE RECEIVED
		## AND THE BOSS DEFENSES AGAINS IT
		tween.tween_property(self, "modulate:a", 0.0, time_alive)
		tween.tween_property(self, "outline_modulate:a", 0.0, time_alive)
		tween.tween_property(self, "position", _calculate_up_direction() , time_alive)


func adjust_font_size_to_camera_distance() -> void:
	var current_camera: Camera3D = get_viewport().get_camera_3d()
	
	if current_camera:
		var distance_to_camera: float = OmniKitNodePositioner.global_distance_to_v3(self, current_camera)
		
		if OmniKitMathHelper.decimal_value_is_between(distance_to_camera, 8.0, 12.0):
			font_size = ceili(font_size * 2)
		elif OmniKitMathHelper.decimal_value_is_between(distance_to_camera, 12.1, 25.0):
			font_size = ceili(font_size * 4)
		elif OmniKitMathHelper.decimal_value_is_between(distance_to_camera, 25.1, 35.0):
			font_size = ceili(font_size * 6)
		elif OmniKitMathHelper.decimal_value_is_between(distance_to_camera, 35.1, 50.0):
			font_size = ceili(font_size * 8)
		elif distance_to_camera > 50.1:
			font_size = ceili(font_size * 10)
		else:
			font_size = 64
		

func _calculate_up_direction() -> Vector3:
	var final_position: Vector3 =  position + (Vector3.UP * up_direction_amount)
	
	if OmniKitMathHelper.chance(horizontal_displacement_chance / 100.0):
		var spread_angle: float = up_spread_angle
		final_position += horizontal_displace_amount * [Vector3.LEFT, Vector3.RIGHT]\
			.pick_random()\
			.rotated(Vector3.UP, randf_range(-spread_angle, spread_angle))
		
	return final_position


func on_alive_timer_timeout() -> void:
	queue_free()
