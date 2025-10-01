extends Node

@export var current_save_mode: SaveModes = SaveModes.JsonMode
@export var encrypted_key: StringName 
@export var default_path: String = "%s/saves" % OS.get_user_data_dir()

enum SaveModes {
	ResourceMode,
	JsonMode
}

var current_saved_game: VaultSavedGame
var list_of_saved_games: Dictionary[String, VaultSavedGame] = {}


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if current_saved_game:
			save_game(current_saved_game)


func _ready() -> void:
	read_user_saved_games()


func create_new_save(file_name: String, file_path: String = default_path) -> VaultSavedGame:
	return VaultSavedGame.new(file_name, default_path)


func make_current(saved_game: VaultSavedGame) -> void:
	current_saved_game = saved_game


func save_game(saved_game: VaultSavedGame, save_mode: SaveModes = current_save_mode, _encrypted_key: StringName = encrypted_key) -> void:
	var save_strategy: VaultSaveStrategy
	var file_path: String = saved_game.data.core.file_path
	var file_name: String = saved_game.data.core.file_name
	
	match save_mode:
		SaveModes.ResourceMode:
			save_strategy = VaultSaveStrategyResource.new(file_path, file_name, _encrypted_key)
		SaveModes.JsonMode:
			save_strategy = VaultSaveStrategyJson.new(file_path, file_name, _encrypted_key)
	
	save_strategy.save_file(saved_game)
	read_user_saved_games()
	


func load_game(file_path: String, file_name: String, _encrypted_key: StringName = encrypted_key) -> VaultSavedGame:
	var save_strategy: VaultSaveStrategy
	save_strategy = VaultSaveStrategyResource.new(file_path, file_name, _encrypted_key)
	
	var saved_game: VaultSavedGame = save_strategy.load_file()
	
	if saved_game == null:
		save_strategy = VaultSaveStrategyJson.new(file_path, file_name, _encrypted_key)
	
	return save_strategy.load_file()


func delete_game(saved_game: VaultSavedGame) -> bool:
	var save_strategy: VaultSaveStrategy
	var file_path: String = saved_game.data.core.file_path
	var file_name: String = saved_game.data.core.file_name
	
	match saved_game.data.core.extension:
		SaveModes.ResourceMode:
			save_strategy = VaultSaveStrategyResource.new(file_path, file_name)
		SaveModes.JsonMode:
			save_strategy = VaultSaveStrategyJson.new(file_path, file_name)
		
	return save_strategy.delete_file()


func read_user_saved_games(path: String = default_path, save_mode: SaveModes = current_save_mode,  _encrypted_key: StringName = encrypted_key) -> void:
	var save_directory_creation_error: Error = DirAccess.make_dir_absolute(default_path)
	
	if save_directory_creation_error not in [OK, ERR_ALREADY_EXISTS]:
		printerr(error_string(save_directory_creation_error))
		push_error("VaultSaveManager: An error %s with code %d happened when reading user saved games" % [error_string(save_directory_creation_error), save_directory_creation_error])
		return
		
	var save_directory: DirAccess = DirAccess.open(default_path)
	var save_directory_open_error: Error = DirAccess.get_open_error()
	
	if save_directory_open_error != OK:
		push_error("VaultSaveManager: An error %s ocurred trying to open the save directory folder in path %s " % [error_string(save_directory_open_error), default_path])
		return
		
	save_directory.list_dir_begin()
	var file_name: String = save_directory.get_next()
	
	list_of_saved_games.clear()
	
	while not file_name.is_empty():
		if not save_directory.current_is_dir() and file_name.get_extension() in ["json", "res", "tres"]:
			var saved_game: VaultSavedGame = load_game(path, file_name, _encrypted_key)
			
			if saved_game:
				list_of_saved_games[saved_game.data.core.file_name] = saved_game
		
		file_name = save_directory.get_next()
				
	save_directory.list_dir_end()
