class_name ItemAmount extends Resource

@export var item: Item
@export var amount: int = 1:
	set(new_amount):
		if item and item.stackable:
			amount = mini(amount + new_amount, item.max_stack_amount)
