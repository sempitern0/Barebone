class_name WeaponDatabase

#region Weapon IDs
## EXAMPLE
#const IdentifierPistol9MM: StringName = &"9mm"
#endregion

#region Projectile IDs

#endregion


#region Weapons
## EXAMPLE
#const IdentifierPistol9MMScene: PackedScene = preload("res://scenes/weapons/models/gameready_colt_python_revolver/colt_python_revolver.tscn")
#endregion

#region Projectiles

#endregion


static var available_weapons: Dictionary[StringName, PackedScene] = {
	## EXAMPLE
	#IdentifierPistol9MM: IdentifierPistol9MMScene,
}

static var available_projectiles: Dictionary[StringName, PackedScene] = {
	## EXAMPLE
	#IdentifierPistol9MM: IdentifierPistol9MMScene,
}


static func get_weapon_scene(id: StringName) -> PackedScene:
	assert(weapon_exists(id), "WeaponDatabase: The weapon with id %s does not exists, weapon cannot be retrieved from the database" % id)
	
	return available_weapons.get(id)


static func get_weapon(id: StringName) -> Weapon:
	return get_weapon_scene(id).instantiate() as Weapon


static func weapon_exists(id: StringName) -> bool:
	return available_weapons.has(id)


static func get_projectile_scene(id: StringName) -> PackedScene:
	assert(projectile_exists(id), "WeaponDatabase: The projectile with id %s does not exists, projectile cannot be retrieved from the database" % id)
	
	return available_weapons.get(id)


static func get_projectile(id: StringName) -> Arrow:
	return get_projectile_scene(id).instantiate() as Arrow


static func projectile_exists(id: StringName) -> bool:
	return available_weapons.has(id)
