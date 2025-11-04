class_name InventorySlotBasedGrid extends Control

@onready var grid_container: GridContainer = $GridContainer

var item_1: Item
var item_2: Item
var item_3: Item

func _unhandled_input(event: InputEvent) -> void:
	if OmniKitInputHelper.numeric_key_pressed(event):
		match OmniKitInputHelper.readable_key(event):
			"1":
				if item_1 == null:
					item_1 = Item.new()
					item_1.stackable = true
					item_1.max_stack_amount = 5
					item_1.id = &"bayas"
					item_1.name = "Bayas"
					
				InventoryManager.add_item(item_1)
			"2":
				if item_2 == null:
					item_2 = Item.new()
					item_2.stackable = true
					item_2.max_stack_amount = 3
					item_2.id = &"stone"
					item_2.name = "Stone"
					
				InventoryManager.add_item(item_2, 2)

			"3":
				if item_3 == null:
					item_3 = Item.new()
					item_3.stackable = true
					item_3.max_stack_amount = 10
					item_3.id = &"wood"
					item_3.name = "Wood"
					
				InventoryManager.add_item(item_3, 3)
	
	
func _enter_tree() -> void:
	assert(get_tree().root.has_node("InventoryManager"), "InventorySlotBasedGrid: The InventoryManager singleton is not loaded or cannot be accessed.")
		
	
	
func _ready() -> void:
	for slot in InventoryManager.max_slots:
		var button: Button = Button.new()
		button.custom_minimum_size = Vector2.ONE * 256
		grid_container.add_child(button)
		
	InventoryManager.added_item.connect(on_added_item)
		

func on_added_item(item: Item, amount: int) -> void:
	var empty_button: Button = null
	var item_added: bool = false
	
	for button: Button in grid_container.get_children():
		if button.has_meta(&"item"):
			var linked_item: Item = button.get_meta(&"item")
			
			if linked_item == item:
				button.text = item.name + " " +  str(item.amount)
				item_added = true
				break
		else:
			if empty_button == null:
				empty_button = button
			
	if empty_button and not item_added:
		empty_button.set_meta(&"item", item)
		empty_button.text = item.name + " " +  str(item.amount)
