## This node is used for setup the muzzle & barrel markers and a avoid wall clipping. 
## IMPORTANT: Don't assign this script into a MeshInstance3D, the meshes are childs on this setup.
## Also here is where the animation overridables can be customized for each weapon
@icon("res://components/3D/first_person/hands/weapons/weapon.svg")
class_name WeaponMesh extends Node3D

## Override when wall clipping is enabled to modify it without depending on the current world 3D
@export var use_camera_fov_override: bool = false
@export var camera_fov_override: float = 75.0
## The animation player for the weapon animations
@export var animation_player: AnimationPlayer
@export_category("FireArm")
## The muzzle emitter will spawn in the place this marker it's on the weapon mesh
@export var muzzle_marker: Marker3D
## When projectile mode it's enabled, the bullets will spawn in this marker position
@export var barrel_marker: Marker3D


func _ready() -> void:
	anti_wall_clipping()


func anti_wall_clipping() -> void:		
	for mesh_instance: MeshInstance3D in OmniKitNodeTraversal.find_nodes_of_type(self, MeshInstance3D.new()):
		apply_z_clip_on_mesh(mesh_instance)


func apply_z_clip_on_mesh(mesh_instance: MeshInstance3D) -> void:
	for surface_idx in range(mesh_instance.mesh.get_surface_count()):
		var material = mesh_instance.mesh.surface_get_material(surface_idx)
		if material is StandardMaterial3D:
			material.use_z_clip_scale = true
			material.z_clip_scale = 0.9
			material.use_fov_override = use_camera_fov_override
			material.fov_override = camera_fov_override

#region Animation overrides
## We return a boolean to know if this weapon has animation to wait on hands equip & unequip
func idle_animation() -> bool:
	return false


func walk_animation() -> bool:
	return false
	

func run_animation() -> bool:
	return false


func crouch_animation() -> bool:
	return false


func jump_animation() -> bool:
	return false


func reload_animation() -> bool:
	return false


func draw_animation() -> bool:
	return false
	

func store_animation() -> bool:
	return false
#endregion
