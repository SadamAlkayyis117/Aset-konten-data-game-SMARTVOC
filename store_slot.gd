extends Control
class_name StoreSlot

signal slot_clicked(slot)

var item_data
var ui_ref
var is_static := false

@onready var icon = $Icon
@onready var name_label = $NameLabel
@onready var price_label = $PriceLabel
@onready var stack_label = $LabelStack

func _ready():

	custom_minimum_size = Vector2(72, 72)
	size = Vector2(72, 72)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

func setup(
	data,
	ui,
	static_mode = false,
	quantity = 1
):

	item_data = data
	ui_ref = ui
	is_static = static_mode

	icon.texture = data.icon
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# ===================================
	# STACK LABEL
	# ===================================

	if quantity > 1:

		stack_label.text = str(quantity) + "x"

		stack_label.visible = true

	else:

		stack_label.visible = false

	# ===================================
	# MODE STATIC (KULKAS)
	# ===================================

	if is_static:

		name_label.visible = false
		price_label.visible = false

	else:

		name_label.text = data.item_name
		price_label.text = "Rp " + str(data.price)


func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("slot_clicked", self)
			ui_ref.select_item(item_data, self)
