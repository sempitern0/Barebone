@tool
class_name PlanetConfiguration extends Resource

@export_range(2, 2048, 2) var resolution: int = 256:
	set(value):
		resolution = value
		changed.emit()
@export var radius: float = 0.5:
	set(value):
		radius = value
		changed.emit()
@export var atmosphere: bool = true:
	set(value):
		atmosphere = value
		changed.emit()
