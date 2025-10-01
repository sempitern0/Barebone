class_name WeaponImpulseResource extends Resource

@export var camera: bool = false

@export var jump_kick: float = 0.02
@export var jump_kick_power: float = 20.0
@export var jump_rotation: Vector2 = Vector2(0.1, 0.02)
@export var jump_rotation_power: float = 5.0
@export_group("Multipliers")
@export var multiplier_on_jump: float = 1.0
@export var multiplier_on_jump_after_run: float = 1.5
@export var multiplier_on_land: float = 1.0
@export var multiplier_on_land_after_run: float = 1.5
@export var multiplier_on_crouch: float = 0.5
