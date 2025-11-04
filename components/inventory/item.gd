class_name Item extends Resource

enum MaterialType {
	Neutral,          ## Neutral non-categorized item
	Food,             ## Edible items, ingredients for consumption
	Stone,            ## Rocks, undifferentiated minerals, raw geological formations
	Metal,            ## Ores, ingots, or refined forms of common metals
	Wood,             ## Logs, planks, sticks, or other unworked timber
	Fabric,           ## Cloth, thread, woven materials, or fibers
	Leather,          ## Tanned hide, processed animal skin
	Gem,              ## Precious stones, cut crystals, or valuable minerals
	Liquid,           ## Water, oils, potions, or unclassified fluid substances
	Powder,           ## Dusts, crushed materials, or fine particulate substances
	Bone,             ## Skeletons, fragments of bone, or skeletal remains
	Scale,            ## From reptiles, fish, or other scaled creatures
	Hide,             ## Raw animal skin, unprocessed
	Glass,            ## Manufactured glass, shards, or vitreous materials
	Ore,              ## Raw, unprocessed metal ore (e.g., Iron Ore, Copper Ore)
	Crystal,          ## More defined than 'Gem', often for magical or energy purposes
	Plant,            ## Herbs, flowers, leaves, unrefined plant matter
	Fungus,           ## Mushrooms, molds, various fungi
	Slime,            ## Oozes, viscous bodily fluids
	Chitin,           ## Exoskeletons of insects, arachnids, or crustaceans
	Pearl,            ## From mollusks, unique aquatic gems
	Feather,          ## From birds or feathered creatures
	Ingot,            ## Refined metal bars (e.g., Iron Ingot, Steel Ingot)
	Potion,           ## Crafted magical or alchemical liquids (could be a sub-type of Liquid)
	Scroll,           ## Paper-based items with magical properties
	Component,        ## Generic crafting part, mechanism, or complex assembly (e.g., gears, springs)
	Alloy,            ## Blended metals (e.g., Bronze, Steel - more specific than 'Metal')
	Spirit,           ## Ethereal essences, captured souls, magical energy
	Chemical,         ## Acids, bases, unique manufactured compounds
	Resin,            ## Sticky plant exudates, sap
	DragonScale,      ## Specific, powerful scales
	MonsterPart,      ## Eyes, teeth, claws, hearts from various monsters
	ElementalEssence, ## Condensed elemental energy (e.g., Fire Essence, Water Essence)
	Vial,             ## Empty or full small containers, often for liquids
	RuneStone,        ## Stones imbued with magical symbols
	Obsidian,         ## Volcanic glass, often strong or magical
	MythicFabric,     ## Enchanted cloth, rare woven materials
	ArcaneDust        ## Dust with magical properties, often used for enchantments
}

enum Category {
	Neutral, ## A non-specific item (e.g., a quest item or one without immediate use).
	Weapon, ## Any object used for combat (swords, bows, spears, etc.).
	Armor, ## Items worn for protection, such as helmets, chestplates, and boots.
	Tool, ## Objects for interacting with the environment (axes for cutting trees, pickaxes for mining, etc.).
	Consumable, ## Items that are used up (health potions, food, elixirs, etc.).
	CraftingMaterial, ## Base materials for crafting other items (wood, metal, leather, etc.).
	Junk, ## Objects that can be sold or broken down for small amounts of resources.
	Quest, ## Items required to complete specific missions.
	Treasure, ## Items of great value (gems, gold coins, rare artifacts, etc.).
	Book, ## Scrolls, tomes, or books that can provide information or abilities.
	Special, ## A category for items with unique properties or special effects.
	Blueprint, ## Plans or recipes for crafting objects.
	Ammunition, ## Projectiles like arrows or bullets for ranged weapons.
}

@export var id: StringName
@export var name: StringName
@export var abbreviation: StringName
@export_multiline var description: String
@export var icon: Texture2D
@export var material_type: MaterialType = MaterialType.Neutral
@export var category: Category = Category.Neutral
@export var collectable: bool = true ## Can be picked up on the world
@export var stackable: bool = false
@export var single_use: bool = false
@export var can_be_dropped: bool = true
@export var size_in_inventory: int = 1
@export var max_stack_amount: int = 1
@export var amount: int = 0:
	set(new_amount):
		if stackable:
			amount = clampi(new_amount, 0, max_stack_amount)
		else:
			amount = clampi(new_amount, 0, 1)


func can_increase_amount(new_amount: int) -> bool:
	var overflow: int = overflow_amount(new_amount)
	var amount_to_increase: int = new_amount - overflow
	
	return stackable and (amount + amount_to_increase) <= max_stack_amount


func overflow_amount(new_amount: int) -> int:
	if stackable:
		return maxi(0, (amount + new_amount) - max_stack_amount)
	
	return 0
