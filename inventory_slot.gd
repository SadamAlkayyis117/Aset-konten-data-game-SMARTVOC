extends Control
class_name InventorySlot

signal slot_clicked(slot)

var item_data: ItemData = null
var is_selected := false
var drag_start_pos: Vector2
var slot_index: int

@onready var icon = $Icon
@onready var selection = $Selection
@onready var Stack_Label = $LabelStack

func _ready():
	custom_minimum_size = Vector2(64, 64)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER


func set_item(data: ItemData, quantity: int = 1):
	item_data = data

	if data:
		icon.texture = data.icon
		icon.visible = true
		icon.expand = true
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		# 🔥 STACK LABEL
		if quantity > 1:
			Stack_Label.text = str(quantity) + "x"
			Stack_Label.visible = true
		else:
			Stack_Label.visible = false
	else:
		icon.texture = null
		icon.visible = false
		Stack_Label.visible = false


func _gui_input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT:

			if event.pressed:
				drag_start_pos = event.position
			else:
				# klik biasa
				if (event.position - drag_start_pos).length() < 10:
					emit_signal("slot_clicked", self)


func _get_drag_data(_at_position: Vector2):

	if item_data == null:
		return null

	var preview = TextureRect.new()
	preview.texture = item_data.icon
	preview.size = Vector2(64, 64)
	preview.modulate.a = 0.7
	set_drag_preview(preview)

	return {
		"item": item_data,
		"from": "inventory",
		"size": item_data.quick_use_size
	}

func _can_drop_data(_at_position: Vector2, data):
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("item"):
		return false
	return data["from"] == "inventory"

func is_empty() -> bool:
	return item_data == null

func _drop_data(_at_position: Vector2, data):

	if typeof(data) != TYPE_DICTIONARY:
		return

	if not data.has("item"):
		return

	var item_data: ItemData = data["item"]

	# Jika slot kosong → isi (untuk future swap system)
	if is_empty():
		set_item(item_data)
		return

func select():
	is_selected = true
	selection.visible = true

func deselect():
	is_selected = false
	selection.visible = false
