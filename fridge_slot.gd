extends Control
class_name FridgeSlot

signal slot_clicked(slot)

var item_data
var ui_ref

@onready var icon = $Icon

func setup(data, ui):
    item_data = data
    ui_ref = ui

    icon.texture = data.icon
    icon.expand = true
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    icon.custom_minimum_size = Vector2(64, 64)
    icon.size = Vector2(64, 64)
    mouse_filter = Control.MOUSE_FILTER_STOP  # ← tambah ini!


func _gui_input(event):
    print("FRIDGE SLOT: _gui_input dipanggil! Event:", event.as_text())
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:
            print("FRIDGE SLOT: Klik kiri ditekan di slot", item_data.item_name if item_data else "kosong")
            emit_signal("slot_clicked", self)
            if ui_ref:
                ui_ref.select_item(item_data, self)
            else:
                print("FRIDGE SLOT: ui_ref NULL!")
