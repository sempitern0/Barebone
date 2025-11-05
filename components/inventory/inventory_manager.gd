## Add this as an autoload through the inventory_manager.tscn
extends Node

signal added_item(item: Item, amount: int)
signal removed_item(item: Item)
signal item_pickup(item: Item, amount: int)
signal item_rejected_for_addition(item: Item, reason: String)

@export_range(1, 9999, 1) var max_slots: int = 10
@export var use_weight: bool = false
@export_range(1, 99999, 1) var max_weight: float = 100.0

## Array[Item]
var inventory: Dictionary[StringName, Array] = {}


func add_item(new_item: Item, amount: int = 1) -> void:
	var remaining_slots: int = remaining_free_slots()

	if inventory.has(new_item.id):
		if inventory[new_item.id].size() > 1:
			inventory[new_item.id].sort_custom(func(a: Item, b: Item): return a.amount < b.amount) # ascending order
			
		for item: Item in inventory[new_item.id]:
			var overflow_amount: int = item.overflow_amount(amount)
			
			if item.can_increase_amount(amount):
				item.amount += amount
				added_item.emit(item, amount)
				
				if overflow_amount > 0 and remaining_slots > 0:
					var overflow_item: Item = new_item.duplicate()
					overflow_item.amount = overflow_amount
					inventory[new_item.id].append(overflow_item)
					call_deferred("emit_signal", "added_item", overflow_item, overflow_item.amount)
					
				break
	else:
		if remaining_slots == 0:
			item_rejected_for_addition.emit(new_item, "INVENTORY_NO_SLOTS_AVAILABLE")
			return
			
		inventory[new_item.id] = [new_item]
		var new_overflow_amount: int = new_item.overflow_amount(amount)
		new_item.amount += amount
		added_item.emit(new_item, amount)
		
		if new_overflow_amount > 0:
			var overflow_item: Item = new_item.duplicate()
			overflow_item.amount = new_overflow_amount
			inventory[new_item.id].append(overflow_item)
			call_deferred("emit_signal", "added_item", overflow_item, overflow_item.amount)
	
	
func pickup_item(target_item: Item, amount: int = 1) -> Item:
	var item_to_pickup: Item = null
	
	if inventory.get(target_item.id, []).size():
		inventory[target_item.id].sort_custom(func(a: Item, b: Item): return a.amount < b.amount) # ascending order
		
		for item: Item in inventory[target_item.id]:
			if item.amount >= amount:
				item.amount -= amount
				item_to_pickup = item
				item_pickup.emit(item, amount)
				
				if item.amount == 0:
					remove_item(item)
				
				break
	
	return item_to_pickup


func remove_item(item: Item) -> void:
	if inventory.has(item.id):
		var item_index: int = inventory[item.id].find(item)
		
		if item_index != -1:
			removed_item.emit(inventory[item.id][item_index])
			inventory[item.id].remove_at(item_index)
			
			if inventory[item.id].is_empty():
				inventory.erase(item.id)
	
	
func remaining_free_slots() -> int:
	var occupied_slots: int = 0
	
	for id: StringName in inventory.keys():
		occupied_slots += inventory[id].size()
		
	return maxi(0, max_slots - occupied_slots)


func remaining_weight() -> float:
	var total_weight: float = 0.0
	
	for id: StringName in inventory.keys():
		total_weight += inventory[id].reduce(func(accum: float, item: Item): return accum + item.weight(), 0.0)
		
	return maxf(0, max_weight - total_weight)
