extends Control
class_name QuickUseSlot

signal slot_used(item_data)

var item_data: ItemData = null
var slot_index: int = -1

@onready var icon: TextureRect = $Icon
@onready var selection: Control = $Selection


func set_item(data: ItemData):
    item_data = data
    if data and icon:
        icon.texture = data.icon
        icon.visible = true
      
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        icon.expand = true
        icon.position = Vector2.ZERO
        icon.anchor_right = 1.0
        icon.anchor_bottom = 1.0
        icon.offset_right = 0
        icon.offset_bottom = 0
        icon.custom_minimum_size = get_size()  # size slot root
        if icon.custom_minimum_size == Vector2.ZERO:
            icon.custom_minimum_size = Vector2(64, 64)  # default kalau 0
      
        print("DEBUG: Icon set untuk", data.item_name, "size:", icon.custom_minimum_size)
    else:
        icon.texture = null
        icon.visible = false


func clear():
    item_data = null
    icon.texture = null
    icon.visible = false


func has_item() -> bool:
    return item_data != null


func is_empty() -> bool:
    return item_data == null


func _gui_input(event):
    if event is InputEventMouseMotion:
        if has_item():
            select()  # highlight saat hover
        else:
            deselect()
    
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            if has_item():
                select()  # highlight saat klik
                slot_used.emit(item_data)
            else:
                deselect()


func select():
    selection.visible = true


func deselect():
    selection.visible = false
