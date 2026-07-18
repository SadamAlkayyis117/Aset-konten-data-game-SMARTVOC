extends Control

@onready var icon = $Icon
var item_data
var stored_items: Array = []
var slot_index: int

func set_item(data):
    item_data = data

    if data and data.icon:
        icon.texture = data.icon
        icon.visible = true
        icon.expand = true
        icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    else:
        icon.texture = null
        icon.visible = false


func is_empty() -> bool:
    return stored_items.is_empty()


func _drop_data(at_position: Vector2, data):

    if typeof(data) != TYPE_DICTIONARY:
        return

    if not data.has("item"):
        return

    var item_data: ItemData = data["item"]

    if not is_empty():
        return

    var inventory_item = InventoryItems.new()
    inventory_item.data = item_data

    QuickSlotManager.assign_item_to_slot(inventory_item, slot_index)

    InventoryManager.remove_item(item_data.item_id, 1)

    set_item(item_data)
