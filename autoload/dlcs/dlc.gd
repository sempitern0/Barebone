class_name DLC extends RefCounted

var id: StringName
var name: StringName
var description: String
var version: String
var path: String
var loaded: bool = false

func _init(_id: StringName, _name: StringName, _description: String, _version: String) -> void:
	id = _id
	name = _name
	description = _description
	version = _version


func initialize() -> bool:
	return false
