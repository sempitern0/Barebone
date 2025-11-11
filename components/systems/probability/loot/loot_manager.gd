@icon("res://components/systems/probability/loot/loot.svg")
extends Node

## A set of global loot tables that need to be globally accessible in order to be re-used
var loot_tables: Dictionary[StringName, LootTable] = {}


func add_loot_table(id: StringName, loot_table: LootTable) -> void:
	loot_tables[id] = loot_table


func get_tables(ids: Array[StringName]) -> Array[LootTable]:
	var result: Array[LootTable] = []
	
	for id: StringName in ids.filter(func(target_id: StringName): return loot_tables.has(target_id)):
		result.append(get_table(id))
	
	return result


func get_table(id: StringName) -> LootTable:
	return loot_tables.get(id, null)
