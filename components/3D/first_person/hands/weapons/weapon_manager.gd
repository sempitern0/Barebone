@icon("res://components/3D/first_person/hands/weapons/weapon_manager.svg")
class_name WeaponManager extends Node

@export var actor: FirstPersonController
@export var camera_controller: CameraController
## This is a node that holds a Camera3D and where the weapon recoil will be applied to simulate the kick on each shoot that affects accuracy. 
@export var camera_recoil_node: Node3D
## The node that represents a right hand to hold a weapon
@export var right_hand: FirstPersonWeaponHand 
## The node that represents a left hand to hold a weapon
@export var left_hand: FirstPersonWeaponHand 

## The left hand has priority when equipping weapons when this is true.
var left_handed: bool = false


func _ready() -> void:
	left_handed = SettingsManager.get_accessibility_section(GameSettings.LeftHandedSetting)
	
	_connect_hand_signals()
	
	actor.ready.connect(
		func():
			actor.motion_state_machine.state_changed.connect(on_motion_state_changed)
			, CONNECT_ONE_SHOT)
	
	SettingsManager.updated_setting_section.connect(on_updated_settings)


func equip_weapon_from_id(id: StringName) -> void:
	equip_weapon(WeaponDatabase.get_weapon(id))


func equip_weapon(weapon: Weapon) -> void:
	if left_handed and left_hand:
		equip_on_left_hand(weapon)
	elif right_hand:
		equip_on_right_hand(weapon)

	
func equip_on_right_hand(weapon: Weapon) -> void:
	if right_hand:
		right_hand.equip(weapon)


func unequip_right_hand() -> void:
	if right_hand:
		right_hand.unequip()

## TODO - ALTER THE HAND POSITION OF THE WEAPON TO TRANSFORM THE X POSITION INTO NEGATIVE -X
func equip_on_left_hand(weapon: Weapon) -> void:
	if left_hand:
		left_hand.equip(weapon)


func unequip_left_hand() -> void:
	if left_hand:
		left_hand.unequip()


func unequip_weapons() -> void:
	unequip_right_hand()
	unequip_left_hand()
	
#region Weapon motion
func enable_weapon_motion_both_hands() -> void:
	enable_weapon_motion_right_hand()
	enable_weapon_motion_left_hand()
	

func disable_weapon_motion_both_hands() -> void:
	disable_weapon_motion_right_hand()
	disable_weapon_motion_left_hand()
	
	
func enable_weapon_motion_right_hand() -> void:
	if right_hand:
		right_hand.enable_weapon_motion()
		
		
func enable_weapon_motion_left_hand() -> void:
	if left_hand:
		left_hand.enable_weapon_motion()


func disable_weapon_motion_right_hand() -> void:
	if right_hand:
		right_hand.disable_weapon_motion()
	
		
func disable_weapon_motion_left_hand() -> void:
	if left_hand:
		left_hand.disable_weapon_motion()
		
		
	
func enable_weapon_bob_both_hands() -> void:
	enable_weapon_bob_right_hand()
	enable_weapon_bob_left_hand()


func disable_weapon_bob_both_hands() -> void:
	disable_weapon_bob_right_hand()
	disable_weapon_bob_left_hand()
	
	
func enable_weapon_bob_right_hand() -> void:
	if right_hand:
		right_hand.enable_weapon_bob()
	
	
func enable_weapon_bob_left_hand() -> void:
	if left_hand:
		left_hand.enable_weapon_bob()
	

func disable_weapon_bob_right_hand() -> void:
	if right_hand:
		right_hand.disable_weapon_bob()
	
	
func disable_weapon_bob_left_hand() -> void:
	if left_hand:
		left_hand.disable_weapon_bob()
	
#endregion
	
func _connect_hand_signals() -> void:
	if right_hand:
		right_hand.drawed_weapon.connect(on_drawed_weapon.bind(right_hand))
		right_hand.stored_weapon.connect(on_stored_weapon.bind(right_hand))
		
	if left_hand:
		left_hand.drawed_weapon.connect(on_drawed_weapon.bind(left_hand))
		left_hand.stored_weapon.connect(on_stored_weapon.bind(left_hand))


#region Signal callbacks
func on_drawed_weapon(weapon: Weapon, hand: FirstPersonWeaponHand) -> void:
	if weapon is FireArmWeapon:
		if not weapon.fired.is_connected(on_weapon_fired.bind(weapon, hand)):
			weapon.fired.connect(on_weapon_fired.bind(weapon, hand))


func on_stored_weapon(weapon: Weapon, hand: FirstPersonWeaponHand) -> void:
	if weapon is FireArmWeapon and weapon.fired.is_connected(on_weapon_fired.bind(weapon, hand)):
		weapon.fired.disconnect(on_weapon_fired.bind(weapon, hand))
		
		
func on_weapon_fired(_hitscan: OmniKitRaycastResult, _weapon: FireArmWeapon, hand: FirstPersonWeaponHand) -> void:
	hand.weapon_recoil.add()
	hand.add_camera_recoil()


func on_motion_state_changed(_from: MachineState, to: MachineState) -> void:
	if to is RunState:
		if right_hand.is_firearm_weapon():
			right_hand.current_weapon.lock_shot = right_hand.current_weapon.configuration.lock_shot_when_running
		if left_hand.is_firearm_weapon():
			left_hand.current_weapon.lock_shot = left_hand.current_weapon.configuration.lock_shot_when_running
	else:
		if right_hand.is_firearm_weapon():
			right_hand.current_weapon.lock_shot =  false
		if left_hand.is_firearm_weapon():
			left_hand.current_weapon.lock_shot = false
			
	if to is SlideState or to is AirState:
		if right_hand.current_weapon:
			right_hand.disable_weapon_bob()
		if left_hand.current_weapon:
			left_hand.disable_weapon_bob()
	else:
		if right_hand.current_weapon and not right_hand.current_weapon is BowWeapon:
			right_hand.enable_weapon_bob()
		if left_hand.current_weapon and not right_hand.current_weapon is BowWeapon:
			left_hand.enable_weapon_bob()


func on_updated_settings(_section: String, key: String, value: Variant) -> void:
	if key == GameSettings.LeftHandedSetting:
		left_handed = value
#endregion
