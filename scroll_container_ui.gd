extends CanvasLayer
class_name StoreContainerUI

var container_ref
var player_ref
var is_static := false
var selected_item_data = null
var selected_slot = null

@onready var item_option_panel = $Panel/ItemOption
@onready var selected_name_label = $Panel/ItemOption/NameLabel
@onready var selected_price_label = $Panel/ItemOption/PriceLabel
@onready var store_button = $Panel/ItemOption/StoretoBtn
@onready var take_button = $Panel/ItemOption/TaketoBtn
@onready var close_button = $Panel/CloseButton
@onready var item_grid = $Panel/ItemGrid

var slot_scene = preload("res://StoreSlot.tscn")


func setup(container, player):
	container_ref = container
	player_ref = player
	is_static = false
	item_option_panel.visible = false
	if player_ref:
		player_ref.set_input_locked(true, true)
	store_button.pressed.connect(_on_store_to_pressed)
	take_button.pressed.connect(_on_take_to_pressed)
	close_button.pressed.connect(close)
	populate_items()

func setup_static(container, player):
	container_ref = container
	player_ref = player
	is_static = true
	item_option_panel.visible = false
	if player_ref:
		player_ref.set_input_locked(true, true)
	store_button.pressed.connect(_on_store_to_pressed)
	take_button.pressed.connect(_on_take_to_pressed)
	close_button.pressed.connect(close)
	populate_items()

func populate_items():

	for child in item_grid.get_children():
		child.queue_free()

	var item_list

	if is_static:
		item_list = container_ref.items
	else:
		item_list = container_ref.items_for_sale

	if item_list == null or item_list.is_empty():
		print("DEBUG: Item list kosong atau null di container", container_ref)
		return

	# ===================================
	# GROUP ITEM MENJADI STACK
	# ===================================

	var grouped := {}

	for item in item_list:

		if item == null:
			continue

		var key = item.item_id

		if !grouped.has(key):

			grouped[key] = {
				"data": item,
				"quantity": 0
			}

		grouped[key]["quantity"] += 1

	# ===================================
	# BUAT SLOT
	# ===================================

	for entry in grouped.values():

		var slot = slot_scene.instantiate()

		item_grid.add_child(slot)

		slot.setup(
			entry["data"],
			self,
			is_static,
			entry["quantity"]
		)

		slot.slot_clicked.connect(_on_slot_clicked)

		if is_static:

			var name_node = slot.get_node_or_null("NameLabel")
			var price_node = slot.get_node_or_null("PriceLabel")

			if name_node:
				name_node.visible = false

			if price_node:
				price_node.visible = false


func _on_slot_clicked(slot):
	select_item(slot.item_data, slot)


func create_store_slot(item_data):
	var slot = slot_scene.instantiate()
	item_grid.add_child(slot)
	slot.setup(item_data, self, false)


func create_static_slot(item_data):
	var slot = slot_scene.instantiate()
	item_grid.add_child(slot)
	slot.setup(item_data, self, true)


func select_item(item_data, slot):
	selected_item_data = item_data
	selected_slot = slot

	if not is_static:
		selected_name_label.text = item_data.item_name
		selected_price_label.text = "Rp " + str(item_data.price)

	item_option_panel.visible = true


func _on_store_to_pressed():

	if selected_item_data == null:
		return

	if not player_ref.has_backpack:
		print("Tidak pakai tas.")
		return


	if InventoryManager.add_item(selected_item_data):

		if is_static:
			container_ref.remove_item(selected_item_data)
			populate_items()

			print("Item dipindah dari kulkas ke inventory (OWNED)")
		else:
			StoreTransactionManager.register_unpaid_inventory(selected_item_data)
			print("Item masuk tas (UNPAID)")


func _on_take_to_pressed():

	if selected_item_data == null:
		return

	if player_ref.right_hand_attachment.get_child_count() > 0 and player_ref.left_hand_attachment.get_child_count() > 0:
		print("Tangan penuh.")
		return


	# =========================
	# ITEM DARI KULKAS
	# =========================
	if is_static:

		player_ref._use_item(null, selected_item_data, "owned")

		container_ref.remove_item(selected_item_data)

		populate_items() # refresh UI

		print("Item diambil dari kulkas (OWNED)")
		return


	# =========================
	# ITEM DARI STORE
	# =========================
	player_ref._use_item(null, selected_item_data, "store")

	StoreTransactionManager.register_unpaid_hand(selected_item_data)

	print("Item dipegang (UNPAID)")


func close():
	if player_ref:
		player_ref.set_input_locked(false)
	if container_ref:
		container_ref.current_ui = null
	queue_free()
