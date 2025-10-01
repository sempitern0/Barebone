@icon("res://components/3D/first_person/hands/hand.svg")
class_name FirstPersonWeaponHand extends Node3D

signal drawed_weapon(weapon: Weapon)
signal stored_weapon(weapon: Weapon)

## Node where the weapons will be added in the scene tree
@export var actor: FirstPersonController
@export var spawn_node: Node3D
@export var weapon_sway: WeaponSway
@export var weapon_bob: WeaponBob
@export var weapon_tilt: WeaponTilt
@export var weapon_impulse: WeaponImpulse
@export var weapon_recoil: WeaponRecoil

var camera_recoil_target_rotation: Vector3
var camera_current_recoil_rotation: Vector3
var current_weapon: Weapon:
	set(value):
		if value != current_weapon:
			current_weapon = value
			
			if is_node_ready():
				if current_weapon:
					enable_weapon_motion()
				else:
					disable_weapon_motion()
					

func _unhandled_input(_event: InputEvent) -> void:
	if is_firearm_weapon():
		if current_weapon.configuration.keep_pressed_to_aim:
			if OmniKitInputHelper.action_pressed_and_exists(InputControls.Aim):
				current_weapon.current_aim_state = FireArmWeapon.AimStates.Aim
			else:
				current_weapon.current_aim_state = FireArmWeapon.AimStates.Holded
		else:
			if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.Aim):
				if current_weapon.current_aim_state == FireArmWeapon.AimStates.Holded:
					current_weapon.current_aim_state = FireArmWeapon.AimStates.Aim
				else:
					current_weapon.current_aim_state = FireArmWeapon.AimStates.Holded


func _ready() -> void:
	if current_weapon:
		equip(current_weapon)
		enable_weapon_motion()
	else:
		disable_weapon_motion()


func _physics_process(delta: float) -> void:
	apply_camera_recoil(delta)
	aim(delta)


func equip(new_weapon: Weapon) -> void:
	unequip()
	
	var available_weapon: Weapon = weapon_by_id(new_weapon.id)
	
	if available_weapon == null:
		spawn_node.add_child(new_weapon)
		
	await get_tree().physics_frame
	
	current_weapon = available_weapon if available_weapon else new_weapon
	current_weapon.show()
	current_weapon.process_mode = Node.PROCESS_MODE_INHERIT
	current_weapon.active = true
	
	## TODO - THE ANIMATIONS SHOULD BE RESPONSIBLE TO ADJUST THE POSITION OF THE WEAPON IN THE HAND
	#if current_weapon.mesh:
		#await current_weapon.mesh.draw_animation()
	#
	current_weapon.position = current_weapon.hand_position
	current_weapon.rotation = current_weapon.hand_rotation
	
	drawed_weapon.emit(current_weapon)
	

func unequip() -> void:
	if current_weapon:
		current_weapon.active = false
		
		if current_weapon.mesh:
			await current_weapon.mesh.store_animation()
			
		current_weapon.hide()
		current_weapon.process_mode = Node.PROCESS_MODE_DISABLED
	
		stored_weapon.emit(current_weapon)
		current_weapon = null
		

func available_weapon_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(spawn_node.get_children()\
		.filter(func(child: Node): return child is Weapon)\
		.map(func(weapon: Weapon): return weapon.id)
		)
			
	return ids


func weapon_by_id(id: StringName) -> Weapon:
	var found_weapons: Array[Weapon] = []
	
	found_weapons.assign(spawn_node.get_children()\
		.filter(func(child: Node): return child is Weapon and child.id == id)
		)
	
	if found_weapons.size():
		return found_weapons.front()
	
	return null

#region Aim
func aim(delta: float) -> void:
	if weapon_can_aim():
		match current_weapon.current_aim_state:
			FireArmWeapon.AimStates.Aim:
				if current_weapon.configuration.center_weapon_on_aim:
					current_weapon.position = current_weapon.position.lerp(
						current_weapon.configuration.aim_hand_position, 
						current_weapon.configuration.aim_smoothing * delta
						)
				
				rotation = Vector3.ZERO
				
				actor.camera_controller.camera.fov = lerpf(
					actor.camera_controller.camera.fov, 
					current_weapon.configuration.fov_level_on_aim, 
					current_weapon.configuration.aim_smoothing * delta
				)
				
			FireArmWeapon.AimStates.Holded:
				actor.camera_controller.camera.fov = lerpf(
					actor.camera_controller.camera.fov, 
					actor.camera_controller.base_fov,
					current_weapon.configuration.aim_smoothing * delta
				)
				
				if current_weapon.configuration.center_weapon_on_aim:
					current_weapon.position = current_weapon.position.lerp(
						current_weapon.hand_position, 
						current_weapon.configuration.aim_smoothing * delta
					)
					
func weapon_can_aim() -> bool:
	return is_processing_unhandled_input() \
		and is_firearm_weapon() \
		and current_weapon.configuration.can_aim \
		and not actor.motion_state_machine.current_state is RunState \
		and not actor.motion_state_machine.current_state is SlideState


func is_aiming() -> bool:
	return is_firearm_weapon() and current_weapon.is_aiming()
#endregion


	

#region Recoil
func apply_camera_recoil(delta: float) -> void:
	if camera_recoil_can_be_applied():
		## Head recoil to affect on accuracy moving the current camera 3d
		camera_recoil_target_rotation = lerp(
			camera_recoil_target_rotation,
			Vector3.ZERO,
			current_weapon.configuration.camera_recoil_lerp_speed * delta
		)
		
		camera_current_recoil_rotation = lerp(
			camera_current_recoil_rotation, 
			camera_recoil_target_rotation, 
			current_weapon.configuration.camera_recoil_snap_amount * delta
		)
		
		actor.head.basis = Quaternion.from_euler(camera_current_recoil_rotation)


func add_camera_recoil() -> void:
	if camera_recoil_can_be_applied():
		var recoil_amount: Vector3 = current_weapon.configuration.camera_recoil_amount
		
		camera_recoil_target_rotation += Vector3(
			recoil_amount.x, 
			randf_range(-recoil_amount.y, recoil_amount.y),
			randf_range(-recoil_amount.z, recoil_amount.z),
		)


func camera_recoil_can_be_applied() -> bool:
	return is_firearm_weapon() \
		and current_weapon.configuration.camera_recoil_enabled \
		and actor.head

#endregion

func is_firearm_weapon() -> bool:
	return current_weapon and current_weapon is FireArmWeapon
	
	
func is_melee_weapon() -> bool:
	return current_weapon and current_weapon is MeleeWeapon


func is_bow_weapon() -> bool:
	return current_weapon and current_weapon is BowWeapon

#region Motion Enablers
func enable_weapon_motion() -> void:
	## As the hand now only have functions for firearm weapons
	## for optimization purposes when the weapon equipped is firearm
	set_physics_process(is_firearm_weapon())
	set_process_unhandled_input(is_firearm_weapon())
	
	if current_weapon:
		if current_weapon.sway:
			enable_weapon_sway()
		if current_weapon.bob:
			enable_weapon_bob()
		if current_weapon.tilt:
			enable_weapon_tilt()
		if current_weapon.impulse:
			enable_weapon_impulse()
		if current_weapon.recoil:
			enable_weapon_recoil()


func disable_weapon_motion() -> void:
	set_physics_process(false)
	set_process_unhandled_input(false)
	
	disable_weapon_sway()
	disable_weapon_bob()
	disable_weapon_tilt()
	disable_weapon_impulse()
	disable_weapon_recoil()
	

func enable_weapon_sway() -> void:
	if weapon_sway and current_weapon and current_weapon.sway:
		weapon_sway.configuration = current_weapon.sway
		weapon_sway.enable()


func disable_weapon_sway() -> void:
	if weapon_sway:
		weapon_sway.configuration = null
		weapon_sway.disable()
		
		
func enable_weapon_bob() -> void:
	if weapon_bob and current_weapon and current_weapon.bob:
		weapon_bob.configuration = current_weapon.bob
		weapon_bob.enable()


func disable_weapon_bob() -> void:
	if weapon_bob:
		weapon_bob.configuration = null
		weapon_bob.disable()


func enable_weapon_tilt() -> void:
	if weapon_tilt and current_weapon and current_weapon.tilt:
		weapon_tilt.configuration = current_weapon.tilt
		weapon_tilt.enable()


func disable_weapon_tilt() -> void:
	if weapon_tilt:
		weapon_tilt.configuration = null
		weapon_tilt.disable()


func enable_weapon_impulse() -> void:
	if weapon_impulse and current_weapon and current_weapon.impulse:
		weapon_impulse.configuration = current_weapon.impulse
		weapon_impulse.enable()


func disable_weapon_impulse() -> void:
	if weapon_impulse:
		weapon_impulse.configuration = null
		weapon_impulse.disable()
		
		
func enable_weapon_recoil() -> void:
	if weapon_recoil and current_weapon and current_weapon.recoil:
		weapon_recoil.configuration = current_weapon.recoil
		weapon_recoil.enable()


func disable_weapon_recoil() -> void:
	if weapon_recoil:
		weapon_recoil.configuration = null
		weapon_recoil.disable()

#endregion
