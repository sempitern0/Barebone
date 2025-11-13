extends Node

## This is false to default to avoid reading .pck files when you know your game does not have dlcs available
const LoadDLCs: bool = false 
const Prefix: String = "dlc_"
const Suffix: String = ".pck"
const EntryScript: String = "dlc.gd"
const BaseDir: String = "res://dlcs"

var loaded_dlcs: Array[DLC] = []


func _ready() -> void:
	if LoadDLCs:
		load_dlcs(directory())
	else:
		queue_free()


func load_dlcs(base_directory: String) -> void:
	var regex = RegEx.new()
	var error: Error = regex.compile("^%s.*\\%s$" % [Prefix, Suffix])
	
	if error != OK:
		Log.error("DLCManager: The regex to find dlc files raised an error %d %s" % [error, error_string(error)])
		return
		
	var dlc_file_paths: Array[String] = OmniKitFileHelper.get_files_recursive(base_directory, regex)
	
	for dlc_path: String in dlc_file_paths:
		var loaded: bool = ProjectSettings.load_resource_pack(dlc_path)
		
		if loaded:
			Log.info("DLCManager: The dlc %s has been loaded succesfully!" % dlc_path)
			## TODO - FIND A WAY TO LOAD THE DLCS AND MAP TO DLC CLASS IN A SAFER WAY
			var dlc: DLC = DLC.new(&"id", &"dlc", "content_dlc", "0.0.1")
			dlc.path = dlc_path
			loaded_dlcs.append(dlc)
		else:
			Log.error("DLCManager: The dlc %s could not be loaded" % dlc_path)


func directory() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path(BaseDir)
		
	return OS.get_executable_path().get_base_dir().path_join(BaseDir.trim_prefix("res://"))
