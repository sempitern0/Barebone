class_name FireArmWeapon extends Weapon

signal fired(target_hitscan: OmniKitRaycastResult)
signal reload_started
signal reload_finished
signal out_of_ammo
signal aimed
signal aim_finished

@export var configuration: FireArmWeaponConfiguration
@export var muzzle_flash_scene: PackedScene
@export var debug_hit: bool = false


enum CombatStates {
	Neutral,
	Fire,
	Reload,
}

enum AimStates {
	Aim,
	Holded
}


var current_combat_state: CombatStates = CombatStates.Neutral
var current_aim_state: AimStates = AimStates.Holded:
	set(value):
		if value != current_aim_state:
			current_aim_state = value
			
			if current_aim_state == AimStates.Aim:
				aimed.emit()
				
			if current_aim_state == AimStates.Holded:
				aim_finished.emit()
			
var original_weapon_position: Vector3
var original_weapon_rotation: Vector3

var fire_timer: float = 0.0
var fire_impulse_timer: float = 0.0

## This variable is useful to force this weapon to not shoot
## Usually when the player enters a state (e.g Run) and we want to lock the shoot
var lock_shot: bool = false


func _ready() -> void:
	super._ready()
	original_weapon_position = position
	original_weapon_rotation = rotation
	
	
func _physics_process(delta: float) -> void:
	if (fire_timer < configuration.fire.fire_rate):
		fire_timer += delta
	
	if OmniKitInputHelper.action_just_pressed_and_exists(InputControls.Shoot):
		match configuration.fire.burst_type:
			configuration.fire.BurstTypes.Single:
				shoot(hitscan())
					
			configuration.fire.BurstTypes.BurstFire:
				for i in range(configuration.fire.number_of_shoots):
					shoot(hitscan(), configuration.fire.number_of_shoots == 1)
						
			configuration.fire.BurstTypes.ThreeRoundBurst:
				for i in range(3):
					await Globals.wait(configuration.fire.fire_rate)
					shoot(hitscan(), false)
						
			configuration.fire.BurstTypes.FiveRoundBurst:
				for i in range(5):
					await Globals.wait(configuration.fire.fire_rate)
					shoot(hitscan(), false)
					
	elif OmniKitInputHelper.action_pressed_and_exists(InputControls.Shoot):
		match configuration.fire.burst_type:
			configuration.fire.BurstTypes.Automatic:
				shoot(hitscan())
			configuration.fire.BurstTypes.SemiAutomatic:
				shoot(hitscan())


func shoot(target_hitscan: OmniKitRaycastResult, use_fire_timer: bool = true) -> void:
	if can_shoot(use_fire_timer):
		current_combat_state = CombatStates.Fire
		configuration.ammo.current_ammunition -= configuration.fire.bullets_per_shoot
		configuration.ammo.current_magazine -= configuration.fire.bullets_per_shoot
		fire_timer = 0.0
		
		spawn_debug_collision(target_hitscan)
		muzzle_effect()
		spawn_bullets(target_hitscan)
		spawn_bullet_trace()
		hitscan_physic_collision(target_hitscan)
		
		if configuration.fire.auto_reload_on_empty_magazine and \
			configuration.ammo.magazine_empty():
				
			reload()
			
		fired.emit(target_hitscan)
		GlobalEvents.weapon_fired.emit(self, target_hitscan)


func hitscan_physic_collision(target_hitscan: OmniKitRaycastResult) -> void:
	if not configuration.projectile and target_hitscan.collided():
		var collider = target_hitscan.collider
		var adjusted_position = target_hitscan.position
		
		if collider is RigidBody3D:
			collider.apply_impulse(
				configuration.bullet.impact_force * OmniKitCamera3DHelper.forward_direction(get_viewport().get_camera_3d()), 
				-adjusted_position
				)


func reload() -> void:
	if configuration.ammo.infinite_mode:
		reload_started.emit()
		reload_finished.emit()
		return
		
	if configuration.ammo.can_reload() and not is_reloading():
		current_combat_state = CombatStates.Reload
		
		reload_started.emit()
		
		var ammo_needed = configuration.ammo.magazine_size - configuration.ammo.current_magazine
		
		## If there is more ammunition available than the current cartridge
		if configuration.ammo.current_ammunition >= ammo_needed:
			configuration.ammo.current_magazine = ammo_needed
			configuration.ammo.current_ammunition -= ammo_needed
			
		else: ## If the available ammunition is less than the ammunition needed to reload, the remaining ammunition is taken.
			configuration.ammo.current_magazine = configuration.ammo.current_ammunition
			configuration.ammo.current_ammunition = 0
		
		await mesh.reload_animation()
			
		current_combat_state = CombatStates.Neutral
		reload_finished.emit()
#
##region Hitscan
func hitscan() -> OmniKitRaycastResult:
	var camera: Camera3D = get_viewport().get_camera_3d()
	
	if camera:
		var screen_center: Vector2i = OmniKitWindowManager.screen_center()
		var origin = camera.project_ray_origin(screen_center)
		var to: Vector3 = origin + camera.project_ray_normal(screen_center) * configuration.fire.fire_range
		
		return create_hitscan(origin, to)
		
	return OmniKitRaycastResult.new({})


func create_hitscan(origin: Vector3, to: Vector3) -> OmniKitRaycastResult:
	var hitscan_ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		origin, 
		to,
		Globals.world_collision_layer | Globals.enemies_collision_layer | Globals.interactables_collision_layer | Globals.grabbables_collision_layer
	)
	
	## TODO - MAYBE WE NEED TO HIT AREAS IN THE FUTURE ALSO
	hitscan_ray_query.collide_with_areas = true 
	hitscan_ray_query.collide_with_bodies = true
	
	return OmniKitRaycastResult.new(get_world_3d().direct_space_state.intersect_ray(hitscan_ray_query))


func spawn_bullets(target_hitscan: OmniKitRaycastResult) -> void:
	if configuration.fire.bullets_per_shoot == 1:
		spawn_bullet(target_hitscan)
	else:
		for i in range(configuration.fire.bullets_per_shoot):
			var camera: Camera3D = get_viewport().get_camera_3d()
			
			var spread_direction: Vector3 = OmniKitCamera3DHelper.forward_direction(camera) \
				.rotated(
					OmniKitVectorHelper.generate_3d_random_direction(), 
					deg_to_rad(randf_range(-configuration.fire.bullet_spread_degrees, 
					configuration.fire.bullet_spread_degrees))
					)
					
			var spreaded_hitscan_origin: Vector3 = camera.project_ray_origin(OmniKitWindowManager.screen_center()) + spread_direction
			var spreaded_hitscan_to: Vector3 = camera.project_ray_normal(OmniKitWindowManager.screen_center()) + spread_direction * configuration.fire.fire_range
			
			spawn_bullet(create_hitscan(spreaded_hitscan_origin, spreaded_hitscan_to))


func spawn_bullet(target_hitscan: OmniKitRaycastResult) -> void:
	if configuration.bullet.scene:
		var bullet: Bullet
		
		if configuration.hitscan:
			if configuration.spawn_bullets_on_empty_hitscan and target_hitscan.collider == null:
				bullet = configuration.bullet.scene.instantiate() as Bullet
			
		elif configuration.projectile:
			bullet = configuration.bullet.scene.instantiate() as Bullet
			
		if bullet:
			bullet.setup(self)
			mesh.barrel_marker.add_child(bullet)
			
	
func spawn_bullet_trace() -> void:
	if configuration.bullet.trace_scene and OmniKitMathHelper.chance(configuration.bullet.trace_display_chance):
		var trace: BulletTrace = configuration.bullet.trace_scene.instantiate() as BulletTrace
		trace.alive_time = configuration.bullet.trace_alive_time
		mesh.barrel_marker.add_child(trace)
		trace.global_transform = mesh.barrel_marker.global_transform


func muzzle_effect() -> void:
	if muzzle_flash_scene and configuration.muzzle_texture \
		and mesh.muzzle_marker \
		and mesh.muzzle_marker.get_child_count() == 0:
		var muzzle: MuzzleFlash = muzzle_flash_scene.instantiate() as MuzzleFlash
		muzzle.setup_from_weapon_configuration(configuration)
		mesh.muzzle_marker.add_child(muzzle)


func spawn_debug_collision(target_hitscan: OmniKitRaycastResult) -> void:
	if debug_hit and target_hitscan.position:
		var debug_mesh = OmniKitGeometryHelper.create_sphere_mesh(0.1, 0.05)
		var material: StandardMaterial3D = StandardMaterial3D.new()
		material.albedo_color = Color.RED
		debug_mesh.set_surface_override_material(0, material)
		target_hitscan.collider.add_child(debug_mesh)
		debug_mesh.global_position = target_hitscan.position


func can_shoot(use_fire_timer: bool = true) -> bool:
	if lock_shot:
		return false
		
	if not active:
		return false
		
	if use_fire_timer and fire_timer < configuration.fire.fire_rate:
		return false
		
	if is_reloading():
		return false
		
	if not configuration.ammo.has_ammunition_to_shoot():
		out_of_ammo.emit()
		return false
		
	return true
	
	
func is_aiming() -> bool:
	return current_aim_state == AimStates.Aim


func is_reloading() -> bool:
	return current_combat_state == CombatStates.Reload
