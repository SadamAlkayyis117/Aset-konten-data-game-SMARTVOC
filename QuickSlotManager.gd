extends Node

var slots: Array = []  # Array[InventoryItems atau null]

func _ready():
    slots.resize(6)

func assign_item_to_slot(item_data: ItemData, slot_index: int) -> bool:
    if item_data.quick_use_size != 1:
        print("DEBUG: Hanya size 1 boleh masuk QuickSlot")
        return false

    if slot_index < 0 or slot_index >= 6:
        return false

    var inventory_item = InventoryItems.new()
    inventory_item.data = item_data
    slots[slot_index] = inventory_item

    print("DEBUG: QuickSlot slot", slot_index, "terisi:", item_data.item_name)

    return true

func get_slot_item(index: int):  # ← Fungsi baru yang hilang ini
    if index < 0 or index >= 6:
        return null
    var slot = slots[index]
    if slot is InventoryItems and slot.data != null:
        return slot.data
    return null

func get_all_slot_items() -> Array:
    var result: Array = []
    
    for slot in slots:
        if slot is InventoryItems and slot.data != null:
            result.append(slot.data)
        else:
            result.append(null)
    
    return result

func remove_item_from_slot(index: int):
    if index >= 0 and index < 6:
        print("DEBUG: QuickSlot slot", index, "dikosongkan manual")
        slots[index] = null
