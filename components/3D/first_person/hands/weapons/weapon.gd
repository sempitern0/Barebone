@icon("res://components/3D/first_person/hands/weapons/weapon.svg")
class_name Weapon extends Node3D

const GroupName: StringName = &"weapons"

enum WeaponCategory {
	Pistol,
	Revolver,
	AssaultRifle,
	SubMachineGun,
	SniperRifle,
	Shotgun,
	GrenadeLauncher,
	RocketLauncher,
	Bow,
	CrossBow,
	Melee,
	MeleeBlunt,
	MeleeSharpen
}

@export var id: StringName
@export var weapon_name: StringName
@export_multiline var description: String
@export var category: WeaponCategory = WeaponCategory.Melee
@export var mesh: WeaponMesh
@export_category("Motion")
@export var sway: WeaponSwayResource
@export var bob: WeaponBobResource
@export var tilt: WeaponTiltResource
@export var impulse: WeaponImpulseResource
@export var recoil: WeaponRecoilResource
@export_category("Position")
@export var hand_position: Vector3
@export var hand_rotation: Vector3

var active: bool = true:
	set(value):
		active = value
		
		set_physics_process(active)
		set_process_unhandled_input(active)
		set_process_input(active)


func _enter_tree() -> void:
	add_to_group(GroupName)
	
	
func _ready() -> void:
	set_physics_process(active)
	set_process_unhandled_input(active)
	set_process_input(active)


#region Category
func is_pistol() -> bool:
	return category == WeaponCategory.Pistol

func is_revolver() -> bool:
	return category == WeaponCategory.Revolver
	
func is_assault_riffle() -> bool:
	return category == WeaponCategory.AssaultRifle
	
func is_submachine_gun() -> bool:
	return category == WeaponCategory.SubMachineGun
	
func is_sniper_rifle() -> bool:
	return category == WeaponCategory.SniperRifle
	
func is_shotgun() -> bool:
	return category == WeaponCategory.Shotgun

func is_rocket_launcher() -> bool:
	return category == WeaponCategory.RocketLauncher
	
func is_grenade_launcher() -> bool:
	return category == WeaponCategory.GrenadeLauncher

func is_melee() -> bool:
	return category == WeaponCategory.Melee
	
func is_melee_blunt() -> bool:
	return category == WeaponCategory.MeleeBlunt
	
func is_melee_sharpen() -> bool:
	return category == WeaponCategory.MeleeSharpen
#endregion
