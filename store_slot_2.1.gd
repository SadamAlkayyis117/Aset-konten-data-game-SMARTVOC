extends Control
class_name StoreSlots

signal slot_clicked(slot)

var item_data
var ui_ref

@onready var icon = $Icon
@onready var name_label = $NameLabel
@onready var price_label = $PriceLabel
@onready var Stack_Label = $LabelStack

func setup(data, ui, quantity: int = 1):
    item_data = data
    ui_ref = ui

    name_label.text = data.item_name
    price_label.text = "Rp " + str(data.price)

    icon.texture = data.icon
    icon.expand = true
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

    # 🔥 STACK LABEL
    if quantity > 1:
        Stack_Label.text = str(quantity) + "x"
        Stack_Label.visible = true
    else:
        Stack_Label.visible = false

func _gui_input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            emit_signal("slot_clicked", self)
            ui_ref.select_item(item_data, self)
