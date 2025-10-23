class_name Enemy extends CharacterBody3D

@export var animation_player: AnimationPlayer
@export var navigation_agent: NavigationAgent3D
@export var hurtbox: Hurtbox3D
@export var motion_state_machine: Machina

@export var idle_animation: StringName
@export var walk_animation: StringName

@onready var debug_state_label: Label3D = $DebugStateLabel
@onready var floor_aligment_raycast: RayCast3D = $FloorAligmentRaycast


func _enter_tree() -> void:
	collision_layer = Globals.enemies_collision_layer
	collision_mask = Globals.world_collision_layer | Globals.player_collision_layer | Globals.enemies_collision_layer | Globals.grabbables_collision_layer


func _ready() -> void:
	motion_state_machine.register_transition(
		EnemyIdleState, 
		EnemyWalkState, 
		EnemyIdleToWalkTransition.new()
	)
	
	if OS.is_debug_build():
		debug_state_label.text = motion_state_machine.current_state.name
		motion_state_machine.state_changed.connect(on_state_changed)
		

func align_transform_with_floor() -> Transform3D:
	if floor_aligment_raycast and floor_aligment_raycast.is_colliding():
		var floor_normal: Vector3 = floor_aligment_raycast.get_collision_normal()
		var xform: Transform3D = global_transform
		xform.basis.y = floor_normal
		xform.basis.x = -xform.basis.z.cross(floor_normal)
		xform.basis = xform.basis.orthonormalized()
		
		return xform
		
	return global_transform
		

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


func get_random_navigation_point_in_radius(origin: Vector3, radius: float) -> Vector3:
	var random_offset = Vector3(
		randf_range(-radius, radius),
		0.0,
		randf_range(-radius, radius)
	)
	
	if random_offset.length() > radius:
		random_offset = random_offset.normalized() * radius
	
	return calculate_navigation_position(origin + random_offset)


func calculate_navigation_position(target_position: Vector3) -> Vector3:
	return NavigationServer3D\
		.map_get_closest_point(get_world_3d().navigation_map, target_position)
	

func play_animation(anim_name: StringName) -> void:
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	

func play_idle_animation() -> void:
	play_animation(idle_animation)


func play_walk_animation() -> void:
	play_animation(walk_animation)


func on_state_changed(_from_state: MachineState, to_state: MachineState) -> void:
	debug_state_label.text = to_state.name
