extends Node

var recipes : Array = []

func _ready():

	load_recipes()

func load_recipes():

	var path = "res://RecipeDatabase.json"

	if not FileAccess.file_exists(path):

		push_error("Recipe database tidak ditemukan")
		return

	var file = FileAccess.open(path, FileAccess.READ)

	var json_text = file.get_as_text()

	var result = JSON.parse_string(json_text)

	if result == null:

		push_error("Recipe JSON gagal dibaca")
		return

	recipes = result

	print("Recipe Loaded :", recipes.size())

func get_recipe(recipe_id : String) -> Dictionary:

	if recipes.is_empty():
		return {}

	var recipe_dict = recipes[0]

	if recipe_dict.has(recipe_id):
		return recipe_dict[recipe_id]

	return {}

func get_available_recipes(fridge_items : Array) -> Array:

	var valid_recipes : Array = []

	if recipes.is_empty():
		return valid_recipes

	var recipe_dict = recipes[0]

	for recipe_id in recipe_dict.keys():

		if can_cook(recipe_id, fridge_items):
			valid_recipes.append(recipe_id)

	return valid_recipes

func can_cook(recipe_id : String, fridge_items : Array) -> bool:

	var recipe = get_recipe(recipe_id)

	if recipe.is_empty():
		return false

	if not recipe.has("ingredients"):
		return false

	var ingredients = recipe["ingredients"]

	var available : Dictionary = {}

	for item in fridge_items:

		if item == null:
			continue

		if item.ingredient_id.is_empty():
			continue

		var ingredient_id = item.ingredient_id

		if not available.has(ingredient_id):
			available[ingredient_id] = 0

		available[ingredient_id] += 1

	for ingredient in ingredients.keys():

		var needed = ingredients[ingredient]

		if not available.has(ingredient):
			return false

		if available[ingredient] < needed:
			return false

	return true

func get_random_available_recipe(
	fridge_items : Array,
	allowed_plate_types : Array = []
) -> Dictionary:

	var available = get_available_recipes(fridge_items)

	var filtered := []

	for recipe_id in available:

		var recipe = get_recipe(recipe_id)

		if allowed_plate_types.is_empty():
			filtered.append(recipe_id)
		elif recipe.has("plate_type") and recipe["plate_type"] in allowed_plate_types:
			filtered.append(recipe_id)

	if filtered.is_empty():
		return {}

	var recipe_id = filtered.pick_random()

	var recipe = get_recipe(recipe_id).duplicate()

	recipe["recipe_id"] = recipe_id

	return recipe
