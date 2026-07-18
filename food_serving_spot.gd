extends Node3D
class_name FoodServingSpot

@export var prepared_food_scene: PackedScene = preload("res://prepared_food.tscn")

@export var spot_name: String = ""

@onready var spawn_point: Marker3D = $SpawnPoint

var current_food: PreparedFood = null


func is_empty() -> bool:

	return current_food == null


func has_food() -> bool:

	return current_food != null


func get_food() -> PreparedFood:

	return current_food


func spawn_food(recipe: Dictionary) -> PreparedFood:

	if current_food != null:
		push_warning("FoodServingSpot '%s' sudah terisi." % spot_name)
		return current_food

	var food: PreparedFood = prepared_food_scene.instantiate()

	spawn_point.add_child(food)

	food.position = Vector3.ZERO
	food.rotation = Vector3.ZERO

	food.setup_recipe(recipe)
	food.set_expire_hours(4)
	current_food = food
	return food


func remove_food():

	if current_food == null:
		return

	current_food.queue_free()

	current_food = null


func take_food() -> PreparedFood:

	if current_food == null:
		return null

	var food = current_food

	current_food = null

	food.reparent(get_tree().current_scene)

	return food
