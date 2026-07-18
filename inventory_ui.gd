extends CanvasLayer

signal use_item_requested(item_data)
signal equip_item_requested(item_data)
signal drop_item_requested(item_data)
signal give_item_requested(item_data)
signal input_quickuse_requested(item_data)

var selected_slot: InventorySlot = null

@export var slot_scene: PackedScene

@onready var main_panel: Control = $MainPanel
@onready var slot_container = $MainPanel/Panel/ScrollContainer/SlotContainer
@onready var use_btn = $MainPanel/Panel/ItemOption/Use
@onready var equip_btn = $MainPanel/Panel/ItemOption/Equip
@onready var drop_btn = $MainPanel/Panel/ItemOption/Drop
@onready var give_btn = $MainPanel/Panel/ItemOption/Give
@onready var store_to_btn = $"MainPanel/Panel/ItemOption/Store to"
@onready var input_quickuse_btn = $MainPanel/Panel/ItemOption/InputQuickUse
@onready var option_panel = $MainPanel/Panel/ItemOption

@onready var quickuse_choice_panel: Panel = $MainPanel/QuickUseChoicePanel  # buat node Panel baru
@onready var quickuse_buttons: Array = [
	$MainPanel/QuickUseChoicePanel/Slot1, $MainPanel/QuickUseChoicePanel/Slot2,
	$MainPanel/QuickUseChoicePanel/Slot3, $MainPanel/QuickUseChoicePanel/Slot4,
	$MainPanel/QuickUseChoicePanel/Slot5, $MainPanel/QuickUseChoicePanel/CloseButton
]

func _ready():
	visible = false
	option_panel.visible = false
	quickuse_choice_panel.visible = false

	use_btn.pressed.connect(_on_use_pressed)
	equip_btn.pressed.connect(_on_equip_pressed)
	drop_btn.pressed.connect(_on_drop_pressed)
	give_btn.pressed.connect(_on_give_pressed)
	store_to_btn.pressed.connect(_on_store_to_pressed)
	input_quickuse_btn.pressed.connect(_on_input_quickuse_pressed)

	# FIX: connect ke inventory manager
	InventoryManager.inventory_updated.connect(_on_inventory_updated)

	for i in range(5):
		quickuse_buttons[i].pressed.connect(_on_quickuse_choice_selected.bind(i))
	quickuse_buttons[5].pressed.connect(_close_quickuse_choice)

func _on_inventory_updated():
	populate_inventory(InventoryManager.get_items())

func populate_inventory(items: Array):

	selected_slot = null

	for child in slot_container.get_children():
		child.queue_free()

	for inv_item in items:
		if inv_item.data != null:
			var slot = slot_scene.instantiate()
			slot_container.add_child(slot)

			# 🔥 KIRIM QUANTITY
			slot.set_item(inv_item.data, inv_item.quantity)

			slot.slot_clicked.connect(_on_slot_clicked)

	option_panel.visible = false
	quickuse_choice_panel.visible = false

	print("DEBUG: Inventory populated dengan", items.size(), "item")

func show_item_options(item: ItemData):
	if item == null:
		option_panel.visible = false
		return
	option_panel.visible = true
	use_btn.disabled = not item.is_usable
	equip_btn.disabled = not item.is_equippable
	give_btn.disabled = not item.is_giveable
	drop_btn.disabled = not item.is_droppable
	input_quickuse_btn.disabled = false  # semua ukuran boleh, cek di choice nanti

func _on_slot_clicked(slot: InventorySlot):
	if selected_slot == slot:
		selected_slot.deselect()
		selected_slot = null
		option_panel.visible = false
		return
	if selected_slot:
		selected_slot.deselect()
	selected_slot = slot
	selected_slot.select()
	show_item_options(slot.item_data)
	var slot_rect = slot.get_global_rect()
	option_panel.global_position = Vector2(
		slot_rect.position.x,
		slot_rect.position.y + slot_rect.size.y + 5
	)


# --- Tombol Input to QuickUse ---
func _on_input_quickuse_pressed():
	if not selected_slot:
		return
	var item = selected_slot.item_data
	option_panel.visible = false
	quickuse_choice_panel.global_position = get_viewport().get_mouse_position() + Vector2(20, 20)
	quickuse_choice_panel.visible = true
	print("DEBUG: Pilih Slot 1-4 untuk QuickUse")

func _on_quickuse_choice_selected(slot_index: int):
	if not selected_slot:
		return

	var item = selected_slot.item_data

	if QuickUseManager.assign_item_to_slot(item, slot_index):
		InventoryManager.remove_item(item.item_id, 1)
		quickuse_choice_panel.visible = false
		selected_slot = null

		print("DEBUG: Item di-input ke QuickUse slot", slot_index + 1)

func _close_quickuse_choice():
	quickuse_choice_panel.visible = false

# Tombol option lama
func _on_use_pressed():
	if selected_slot == null or selected_slot.item_data == null:
		return
	print("DEBUG UI: USE ditekan untuk", selected_slot.item_data.item_name)
	emit_signal("use_item_requested", selected_slot.item_data)
	option_panel.visible = false

func _on_equip_pressed():
	if selected_slot and selected_slot.item_data:
		emit_signal("equip_item_requested", selected_slot.item_data)
		option_panel.visible = false
		selected_slot = null

func _on_drop_pressed():
	if selected_slot and selected_slot.item_data:
		emit_signal("drop_item_requested", selected_slot.item_data)
		option_panel.visible = false
		selected_slot = null

func _on_give_pressed():
	if selected_slot and selected_slot.item_data:
		emit_signal("give_item_requested", selected_slot.item_data)
		InventoryManager.remove_item(selected_slot.item_data.item_id, 1)
		populate_inventory(InventoryManager.get_items())
		option_panel.visible = false
		selected_slot = null

func _on_store_to_pressed():
	if not selected_slot:
		return
	var item = selected_slot.item_data
	var player = get_tree().get_first_node_in_group("Player")
	if player.nearby_container == null:
		print("Tidak dekat kulkas")
		return
	var container = player.nearby_container
	if container.add_item(item):
		InventoryManager.remove_item(item.item_id, 1)
		populate_inventory(InventoryManager.get_items())
		print("Item disimpan ke kulkas")
	else:
		print("Kulkas penuh")
