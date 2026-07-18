extends Node3D
class_name SwimCafeCashier

@export var cafe_menu_scene: PackedScene
@export var serving_spot: FoodServingSpotSwim

@onready var interact_area = $InteractArea

var current_player = null

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

func interact(player):

	current_player = player

	var menu = cafe_menu_scene.instantiate()

	get_tree().current_scene.add_child(menu)

	menu.open_menu(
		self,
		serving_spot
	)

func process_order(
	recipe_id:String,
	price:int,
	serving_spot_ref:FoodServingSpotSwim
):

	if current_player == null:
		return

	current_player.open_wallet_payment(
		price,
		"Beli " + RecipeManager.get_recipe(recipe_id)["name"],
		func(success):

			if success:

				var recipe = RecipeManager.get_recipe(
					recipe_id
				)

				serving_spot_ref.spawn_food(
					recipe
				)

				print(
					"✅ Pesanan berhasil : ",
					recipe["name"]
				)
	)
