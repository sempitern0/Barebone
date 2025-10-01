class_name FireArmWeaponConfiguration extends Resource

@export_range(0, 100, 0.1) var durability: float = 95.0
@export_range(0, 100, 0.1) var accuracy: float = 90.0
@export var lock_shot_when_running: bool = true
## When enabled the hitscan it's active for this weapon projected on the distance defined by the variable fire_range
@export var hitscan: bool = true
## When enabled a projectile it's spawned on the barrel marker of the weapon mesh that can interat with the physic world. 
@export var projectile: bool = false
## When projectile and this variable is enabled and the weapon shoot but the hitscan collision it's empty, the bullets are spawned on the limit of this weapon fire range where the hitscan it's pointing at
@export var spawn_bullets_on_empty_hitscan: bool = true
## When enabled, if the hitscan does not collide with anything a bullet it's spawned on the fire range limit as rigid body
#@export var spawn_bullets_on_fire_range_limit: bool = false
@export_group("Fire")
@export var ammo: FireArmWeaponAmmo
@export var bullet: FireArmWeaponBullet
@export var fire: FireArmWeaponFire
@export_group("Aim")
@export var can_aim: bool = true
@export var keep_pressed_to_aim: bool = true
@export var center_weapon_on_aim: bool = true
@export_range(0.0, 179.0, 0.1) var fov_level_on_aim: float = 65.0
@export var aim_hand_position: Vector3 = Vector3.ZERO
@export var aim_smoothing: float = 8.0
@export_group("Camera recoil")
@export var camera_recoil_enabled: bool = true
@export var camera_recoil_amount: Vector3 = Vector3.ZERO
@export var camera_recoil_lerp_speed: float = 8.0
@export var camera_recoil_snap_amount: float = 6.0
@export_group("Muzzle flash")
@export var muzzle_texture: Texture2D
@export var muzzle_lifetime: float = 0.03
@export var muzzle_min_size: Vector2 = Vector2(0.05, 0.05)
@export var muzzle_max_size: Vector2 = Vector2(0.35, 0.35)
@export var muzzle_emit_on_ready: bool = true
@export var muzzle_spawn_light: bool = true
@export var muzzle_light_lifetime: float = 0.01
@export_range(0, 16, 0.1) var muzzle_min_light_energy: float = 1.0
@export_range(0, 16, 0.1) var muzzle_max_light_energy: float = 1.0
@export var muzzle_light_color: Color = Color("FFD700")
