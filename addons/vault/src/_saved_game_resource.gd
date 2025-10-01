### CLASS FOR INTERNAL USE - DO NOT EXTEND OR USE IT DIRECTLY ###
class_name _VaultSavedGameResource extends Resource

@export var data: Dictionary

func _init(saved_game: VaultSavedGame) -> void:
	data = saved_game.data
