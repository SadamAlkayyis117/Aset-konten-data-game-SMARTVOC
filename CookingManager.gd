extends Node
class_name CookingManagers

signal cooking_started(cooker, recipe)
signal cooking_finished(cooker, recipe)
signal cooking_cancelled(cooker)

var is_busy: bool = false

var cooking_timer : SceneTreeTimer
var current_cooker = null
var current_container = null
var current_recipe: Dictionary = {}
var current_serving_spot = null


# =====================================================
# START COOKING
# =====================================================

func start_cooking(
	cooker,
	container,
	recipe: Dictionary,
	serving_spot
) -> bool:

	if is_busy:
		push_warning("CookingManager sedang memasak.")
		return false

	if recipe.is_empty():
		push_warning("Recipe kosong.")
		return false

	if serving_spot == null:
		push_warning("Serving Spot tidak ditemukan.")
		return false

	current_cooker = cooker
	current_container = container
	current_recipe = recipe
	current_serving_spot = serving_spot

	is_busy = true

	emit_signal(
		"cooking_started",
		current_cooker,
		current_recipe
	)

	print("START COOKING :", current_recipe.get("name", "Unknown"))
	_finish_after_delay()
	return true


# =====================================================
# FINISH COOKING
# =====================================================

func finish_cooking():

	if !is_busy:
		return

	print("FINISH COOKING :", current_recipe.get("name", "Unknown"))

	if current_serving_spot:

		current_serving_spot.spawn_food(
			current_recipe
		)

	emit_signal(
		"cooking_finished",
		current_cooker,
		current_recipe
	)

	_reset()


# =====================================================
# CANCEL
# =====================================================

func cancel_cooking():

	if !is_busy:
		return

	print("COOKING CANCELLED")

	emit_signal(
		"cooking_cancelled",
		current_cooker
	)

	_reset()


# =====================================================
# RESET
# =====================================================

func _reset():

	is_busy = false

	current_cooker = null
	current_container = null
	current_serving_spot = null

	current_recipe.clear()


# =====================================================
# GETTER
# =====================================================

func is_cooking() -> bool:

	return is_busy


func get_current_recipe() -> Dictionary:

	return current_recipe


func get_current_container():

	return current_container


func get_current_cooker():

	return current_cooker


func get_current_serving_spot():

	return current_serving_spot

func _finish_after_delay():

	await get_tree().create_timer(5.0).timeout

	if is_busy:
		finish_cooking()
