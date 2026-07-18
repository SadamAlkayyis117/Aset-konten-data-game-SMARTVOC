extends CanvasLayer


@export var cafe_menu_item_scene: PackedScene

@onready var item_container = \
	$MenuBG/ScrollContainer/VboxContainer

@onready var close_button = \
	$MenuBG/Button

var serving_spot_ref = null
var cashier_ref = null

func _ready():

	close_button.pressed.connect(_on_close_pressed)

func open_menu(
	cashier,
	serving_spot
):

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	cashier_ref = cashier
	serving_spot_ref = serving_spot

	visible = true

	load_menu()

func load_menu():
	print("recipes size =", RecipeManager.recipes.size())

	# bersihkan item sebelumnya
	for child in item_container.get_children():
		child.queue_free()

	if RecipeManager.recipes.is_empty():
		return

	var recipe_dict = RecipeManager.recipes[0]
	print("recipe count =", recipe_dict.size())

	for recipe_id in recipe_dict.keys():
		var recipe = recipe_dict[recipe_id]
		# hanya tampilkan yang bisa dijual di cafe
		if !recipe.get("sell_in_cafe", false):
			continue

		# buat instance item
		if cafe_menu_item_scene == null:
			push_error("Cafe menu item scene belum di-set di inspector")
			return

		var item = cafe_menu_item_scene.instantiate()

		# beri nama instance agar mudah di-debug (opsional)
		item.name = str(recipe_id)

		# tambahkan ke tree dulu supaya _ready/onready di item dieksekusi
		item_container.add_child(item)

		# sekarang aman memanggil setup() dan connect signal
		# (gunakan call_deferred jika kamu ingin memastikan eksekusi di frame berikutnya)
		if item.has_method("setup"):
			item.setup(recipe_id, recipe)
		else:
			print("WARNING: item instance tidak punya method setup() -", item)

		# hubungkan sinyal buy_pressed jika ada
		if item.has_signal("buy_pressed"):
			item.buy_pressed.connect(_on_buy_pressed)
		else:
			# fallback: coba connect lewat nama node (jika implementasi berbeda)
			print("WARNING: item instance tidak punya signal 'buy_pressed' -", item)

func _on_buy_pressed(recipe_id:String):

	var recipe = RecipeManager.get_recipe(
		recipe_id
	)

	if recipe.is_empty():
		return

	var price = recipe.get(
		"cafe_price",
		10000
	)

	cashier_ref.process_order(
		recipe_id,
		price,
		serving_spot_ref
	)

	queue_free()

func _on_close_pressed():

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	queue_free()
