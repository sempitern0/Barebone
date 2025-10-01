@icon("res://components/3D/first_person/hands/weapons/bow/bow_weapon.svg")
class_name BowWeapon extends Weapon

signal fired

@export var arrow_scene: PackedScene
@export var fake_arrow_scene: PackedScene
@export var shoot_origin: Marker3D
@export var stringforce_position_limit: Marker3D
@export var stringforce_min: float = 3.0
@export var stringforce_max: float = 5.0
@export var stringforce_time: float = 1.0
@export var max_arrow_stack: int = 10
@export var arrows_per_shot: int = 1

enum BowStates {
	Neutral,
	Charging,
	Reload,
}

var current_arrow_scene: PackedScene
var current_fake_arrow: Node3D
var current_state: BowStates = BowStates.Neutral:
	set(new_state):
		if current_state != new_state:
			current_state = new_state
			
			set_physics_process(new_state == BowStates.Charging)
			set_process_unhandled_input(new_state != BowStates.Reload)
							

var current_stringforce: float = stringforce_min:
	set(value):
		current_stringforce = clampf(value, stringforce_min, stringforce_max)
		
var charge_time: float = 0.0


func _unhandled_input(_event: InputEvent) -> void:
	if OmniKitInputHelper.action_pressed_and_exists(InputControls.Shoot):
		current_state = BowStates.Charging
		
	if OmniKitInputHelper.action_just_released_and_exists(InputControls.Shoot):
		fire(current_stringforce)
		

func _ready() -> void:
	super._ready()
	set_physics_process(current_state == BowStates.Charging)
	
	if arrow_scene:
		current_arrow_scene = arrow_scene
		
	if fake_arrow_scene:
		current_fake_arrow = fake_arrow_scene.instantiate()
		shoot_origin.add_child(current_fake_arrow)
		current_fake_arrow.position = Vector3.ZERO
	
	fired.connect(on_arrow_fired)
	
	

func _physics_process(delta: float) -> void:
	charge_time += delta

	var charge_progress = minf(charge_time / stringforce_time, 1.0)
	current_stringforce = lerpf(stringforce_min, stringforce_max, charge_progress)


func fire(force: float) -> void:
	if current_fake_arrow.visible and current_fake_arrow:
		current_fake_arrow.hide()
			
		var arrow: Arrow = current_arrow_scene.instantiate() as Arrow
		get_tree().root.add_child(arrow)
		arrow.global_position = shoot_origin.global_position
		arrow.global_rotation = shoot_origin.global_rotation
		
		var camera = get_viewport().get_camera_3d()
		var travel_force: Vector3 = (Vector3.FORWARD.z * force) * shoot_origin.transform.basis.z
		
		if camera:
			travel_force = force * camera.project_ray_normal(OmniKitWindowManager.screen_center())
			
		arrow.apply_central_impulse(travel_force)
		fired.emit()


func on_arrow_fired() -> void:
	current_state = BowStates.Reload
	current_stringforce = stringforce_min
	charge_time = 0

	await mesh.reload_animation()
		
	if current_fake_arrow:
		current_fake_arrow.show()
		
	current_state = BowStates.Neutral
