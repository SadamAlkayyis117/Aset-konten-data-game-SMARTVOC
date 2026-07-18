extends Node3D

@export var serving_spot: FoodServingSpot
@onready var interact_area = $InteractArea

func _ready():
	interact_area.body_entered.connect(
		_on_body_entered
	)
	interact_area.body_exited.connect(
		_on_body_exited
	)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.set_interactable(self)

func _on_body_exited(body):
	if body.is_in_group("Player"):
		body.clear_interactable(self)

func interact(_player):

	if serving_spot.current_food != null:
		return

	var recipe = RecipeManager.get_recipe(
		"coffee"
	)

	serving_spot.spawn_food(recipe)
