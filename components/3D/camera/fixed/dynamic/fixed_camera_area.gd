## Area that trigger the changes between dynamic fixed cameras
class_name FixedCameraArea3D extends Area3D

@export var camera: DynamicFixedCamera3D
@export var target: Node3D


func _ready() -> void:
	monitorable = false
	monitoring = true
	collision_mask = Globals.player_collision_layer
	collision_layer = 0
	priority = 1
	
	body_entered.connect(on_player_entered)
	
	
func on_player_entered(body: CharacterBody3D) -> void:
	if camera:
		var previous_camera: Camera3D = get_viewport().get_camera_3d()

		if previous_camera is DynamicFixedCamera3D and previous_camera != camera:
			previous_camera.call_deferred("deactivate")
			camera.set_deferred("target", body)
			camera.call_deferred("activate")
