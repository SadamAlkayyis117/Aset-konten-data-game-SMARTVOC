extends Node3D
class_name PreparedFood

var last_eat_time := 0.0
@export var recipe_id : String = ""
var recipe_data : Dictionary = {}
var expire_game_minutes : float = -1
var quality : float = 100
var carrier: CharacterBody3D = null
var is_taken := false
var servings_left := 4
var max_servings := 4

@onready var mesh_root = $MeshRoot
@onready var plate = $MeshRoot/Piring
@onready var bowl = $MeshRoot/Mangkok
@onready var cup = $MeshRoot/CupMinum
@onready var food_plate = $MeshRoot/Piring/FoodPlate
@onready var food_bowl = $MeshRoot/Mangkok/FoodBowl
@onready var food_cup = $MeshRoot/CupMinum/FoodCup

@onready var area = $Area3D

func _ready():

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):

	if body.is_in_group("player"):

		carrier = body

		body.set_interactable(self)

func _on_body_exited(body):

	if body == carrier and not is_taken:

		body.clear_interactable(self)

		carrier = null


func interact(player):

	if is_taken:
		return

	pick_up()


func pick_up():

	if carrier == null:
		return

	if is_taken:
		return

	is_taken = true

	carrier.start_food_pickup()
	carrier.current_carried_item = self
	carrier.food_carrying = true


func drop():

	if not is_taken:
		return

	is_taken = false

	if carrier:

		carrier.start_food_drop()
		carrier.current_carried_item = null
		carrier.food_carrying = false

func setup_recipe(recipe : Dictionary):

	recipe_data = recipe

	food_plate.visible = false
	food_bowl.visible = false
	food_cup.visible = false

	match recipe["plate_type"]:

		"plate":

			plate.visible = true
			bowl.visible = false
			cup.visible = false

			food_plate.visible = true

			if recipe.has("food_texture"):
				var tex = load(recipe["food_texture"])
				var mat = food_plate.material_override.duplicate()
				food_plate.material_override = mat
				mat.set_shader_parameter(
					"food_texture",
					tex
				)

		"bowl":

			plate.visible = false
			bowl.visible = true
			cup.visible = false

			food_bowl.visible = true

			if recipe.has("food_texture"):
				var tex = load(recipe["food_texture"])
				var mat = food_bowl.material_override.duplicate()
				food_bowl.material_override = mat
				mat.set_shader_parameter(
					"food_texture",
					tex
				)

		"cup":

			plate.visible = false
			bowl.visible = false
			cup.visible = true

			food_cup.visible = true

			if recipe.has("food_texture"):
				var tex = load(recipe["food_texture"])
				var mat = food_cup.material_override.duplicate()
				food_cup.material_override = mat
				mat.set_shader_parameter(
					"food_texture",
					tex
				)

	update_food_visual()

func set_expire_hours(hours : float):
	expire_game_minutes = TimeManager.current_time_minutes + (hours * 60.0)

func _process(_delta):

	if expire_game_minutes < 0:
		return

	var now = TimeManager.current_time_minutes

	# lewat tengah malam
	if expire_game_minutes >= 1440:

		var target = expire_game_minutes - 1440

		if TimeManager.total_day_count > 1:

			if now >= target:
				queue_free()

	else:

		if now >= expire_game_minutes:
			queue_free()

func update_food_visual():

	var ratio = float(servings_left) / float(max_servings)

	if food_plate.visible and food_plate.material_override:

		food_plate.material_override.set_shader_parameter(
			"eat_amount",
			ratio
		)

	if food_bowl.visible and food_bowl.material_override:

		food_bowl.material_override.set_shader_parameter(
			"eat_amount",
			ratio
		)

	if food_cup.visible and food_cup.material_override:

		food_cup.material_override.set_shader_parameter(
			"eat_amount",
			ratio
		)

func consume_portion():

	servings_left -= 1

	if servings_left < 0:
		servings_left = 0

	update_food_visual()

	print(
		"Makanan tersisa ",
		servings_left,
		"/",
		max_servings
	)

	if servings_left <= 0:

		if carrier:
			carrier.current_carried_item = null
			carrier.food_carrying = false
			carrier.dining_eating = false

		queue_free()

func eat(player):

	var now = Time.get_ticks_msec() / 1000.0

	if now - last_eat_time < 1.0:
		return

	last_eat_time = now

	# EFFECT DARI RECIPE
	if recipe_data.has("hunger_restore"):
		NeedsManager.hunger = clamp(
			NeedsManager.hunger + recipe_data["hunger_restore"],
			0,
			100
		)

	if recipe_data.has("thirst_restore"):
		NeedsManager.thirsty = clamp(
			NeedsManager.thirsty + recipe_data["thirst_restore"],
			0,
			100
		)

	if recipe_data.has("mood_restore"):
		NeedsManager.mood = clamp(
			NeedsManager.mood + recipe_data["mood_restore"],
			0,
			100
		)
	
	if recipe_data.has("bladder_restore"):
		NeedsManager.bladder = clamp(
			NeedsManager.bladder + recipe_data["bladder_restore"],
			0,
			100
		)

	consume_portion()
