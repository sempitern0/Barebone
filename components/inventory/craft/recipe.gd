class_name ItemRecipe extends Resource

@export var id: StringName
@export var priority: int = 1
@export var item_requirements: Array[ItemAmount] = []
@export var final_item: Item


## Where [Item.id, amount]
func meet_requirements(items: Dictionary[StringName, int]) -> bool:
	for requirement: ItemAmount in item_requirements:
		if not items.has(requirement.item.id):
			return false
		
		if items[requirement.item.id] < requirement.amount:
			return false
	
	return true
