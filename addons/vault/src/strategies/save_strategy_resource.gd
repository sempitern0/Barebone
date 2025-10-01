class_name VaultSaveStrategyResource extends VaultSaveStrategy


func load_file() -> VaultSavedGame:
	if save_exists():
		var saved_file: _VaultSavedGameResource = ResourceLoader.load(save_path(), "", ResourceLoader.CACHE_MODE_IGNORE)
		
		return VaultSavedGame.new(
			save_file_path, 
			save_filename, 
			saved_file.data, 
			false
		)

	return null


func save_file(saved_game: VaultSavedGame) -> bool:
	saved_game.data.core.extension = extension_on_save()
	
	var save_game_resource: _VaultSavedGameResource = _VaultSavedGameResource.new(saved_game)
	var error: Error = ResourceSaver.save(save_game_resource, save_path())

	if error != OK:
		push_error("VaultSaveStrategyResource: An error happened trying to save the file %s with code %s" % [save_filename, error_string(error)])
		return false
		
	return true
	

func delete_file() -> bool:
	if save_exists():
		var error: Error = DirAccess.remove_absolute(save_path())
		
		if error != OK:
			push_error("VaultSaveStrategyResource: An error happened trying to delete the file %s with code %s" % [save_filename, error_string(error)])
			return false
			
	return true


func extension_on_save() -> String:
	return "tres" if OS.is_debug_build() else "res"


func save_exists() -> bool:
	return ResourceLoader.exists(save_path())
	
