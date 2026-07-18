extends Node3D
class_name StaticContainer

@export var max_slots : int = 50

var items : Array = []

@onready var interact_area = $InteractArea
@export var starter_ingredients : Array[ItemData]

var ui_scene : PackedScene
var current_ui = null

func _ready():
	
	ui_scene = preload("res://scroll_container_ui.tscn")

	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):

	if body.is_in_group("Player"):
		body.nearby_container = self
		body.set_interactable(self)

func _on_body_exited(body):

	if body.is_in_group("Player"):
		body.nearby_container = null

func open_container(player):
	if current_ui != null:
		return

	current_ui = ui_scene.instantiate()
	get_tree().root.add_child(current_ui)
	current_ui.setup_static(self, player)  # ← ubah ke setup_static

func add_item(item_data: ItemData) -> bool:

	if items.size() >= max_slots:
		print("Kulkas penuh")
		return false

	items.append(item_data)
	return true

func remove_item(item_data: ItemData) -> bool:

	if item_data in items:
		items.erase(item_data)
		return true

	return false

func get_ingredient_count(ingredient_id:String) -> int:

	var count := 0

	for item in items:

		if item.ingredient_id == ingredient_id:
			count += 1

	return count

func has_ingredient(ingredient_id:String, amount:int = 1) -> bool:

	return get_ingredient_count(ingredient_id) >= amount

func consume_ingredient(ingredient_id:String, amount:int) -> bool:

	if get_ingredient_count(ingredient_id) < amount:
		return false

	var removed := 0

	for i in range(items.size() - 1, -1, -1):

		if items[i].ingredient_id == ingredient_id:

			items.remove_at(i)

			removed += 1

			if removed >= amount:
				break

	return true

func print_ingredients():

	var result := {}

	for item in items:

		if item.ingredient_id == "":
			continue

		if !result.has(item.ingredient_id):
			result[item.ingredient_id] = 0

		result[item.ingredient_id] += 1

	print(result)

func generate_starter_stock():

	items.clear()

	for item in starter_ingredients:

		var amount = randi_range(2, 8)

		for i in range(amount):

			add_item(item)

	print("Starter stock generated")

	print_ingredients()

func initialize_new_game():

	generate_starter_stock()

	print("=== NEW GAME STOCK ===")

	print("ITEMS =", items.size())

	print_ingredients()

func is_empty_fridge() -> bool:

	for item in items:

		if item.ingredient_id != "":
			return false

	return true

func consume_recipe(recipe: Dictionary) -> bool:

	if not recipe.has("ingredients"):
		return false

	var ingredients = recipe["ingredients"]

	# cek dulu semua tersedia

	for ingredient_id in ingredients.keys():

		var amount = ingredients[ingredient_id]

		if not has_ingredient(ingredient_id, amount):
			return false

	# baru konsumsi

	for ingredient_id in ingredients.keys():

		var amount = ingredients[ingredient_id]

		consume_ingredient(ingredient_id, amount)

	print("BAHAN DIKURANGI")

	print_ingredients()

	return true
