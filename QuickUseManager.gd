extends Node
class_name QuickUseManagers

signal quickuse_updated

const MAX_SLOTS := 5

var slots: Array = []   # menyimpan ItemData atau null


func _ready():
    slots.resize(MAX_SLOTS)
    for i in range(MAX_SLOTS):
        slots[i] = null


# ===============================
# ASSIGN ITEM (REPLACE SYSTEM)
# ===============================
func assign_item_to_slot(item: ItemData, slot_index: int) -> bool:
    if slot_index < 0 or slot_index >= MAX_SLOTS:
        return false

    # Jangan boleh duplicate
    remove_item(item.item_id)

    var replaced_item = slots[slot_index]
    slots[slot_index] = item

    # Kalau ada item terganti → balikin ke inventory
    if replaced_item:
        InventoryManager.add_item(replaced_item, 1)

    emit_signal("quickuse_updated")
    return true


# ===============================
# REMOVE ITEM
# ===============================
func remove_item(item_id: String):
    for i in range(MAX_SLOTS):
        if slots[i] and slots[i].item_id == item_id:
            slots[i] = null

    emit_signal("quickuse_updated")


# ===============================
# GET SLOT ITEM
# ===============================
func get_slot_item(index: int) -> ItemData:
    if index < 0 or index >= MAX_SLOTS:
        return null
    return slots[index]


func get_all_slots() -> Array:
    return slots

func use_item(item_id: String) -> void:
    for i in range(MAX_SLOTS):
        var item = slots[i]
        if item and item.item_id == item_id:
            NeedsManager.apply_item_effect(item)
            if item.max_durability <= 1:
                slots[i] = null
                emit_signal("quickuse_updated")
            return
