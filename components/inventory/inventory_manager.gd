## Add this as an autoload through the inventory_manager.tscn
extends Node

signal item_rejected_for_addition(item: Item, reason: String)
signal added_item(item: Item, amount: int)
signal removed_item(item: Item)
signal item_pickup(item: Item, amount: int)

@export_range(1, 1000, 1) var max_slots: int = 10

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
	

func remove_item(item: Item) -> void:
	if inventory.has(item.id):
		var item_index: int = inventory[item.id].find(item)
		
		if item_index != -1:
			removed_item.emit(inventory[item.id][item_index])
			inventory[item.id].remove_at(item_index)
	
	
func pickup_item(id: StringName, amount: int = 1) -> void:
	if inventory.get(id, []).size():
		inventory[id].sort_custom(func(a: Item, b: Item): return a.amount < b.amount) # ascending order
		
		for item: Item in inventory[id]:
			if item.amount >= amount:
				item.amount -= amount
				item_pickup.emit(item, amount)
				
				if (item.amount - amount) <= 0:
					remove_item(item)
				
				break


func remaining_free_slots() -> int:
	var occupied_slots: int = 0
	
	for id: StringName in inventory.keys():
		occupied_slots += inventory[id].size()
		
	return maxi(0, max_slots - occupied_slots)
