extends CanvasLayer
class_name FridgeContainerUI

var container_ref
var player_ref
var is_static := false
var selected_item_data = null
var selected_slot = null

@onready var item_option_panel = $Panel/ItemOption
@onready var store_button = $Panel/ItemOption/StoretoBtn
@onready var take_button = $Panel/ItemOption/TaketoBtn
@onready var close_button = $Panel/CloseButton
@onready var item_grid = $Panel/ItemGrid

var slot_scene = preload("res://fridge_slot.tscn")


func setup(container, player):
    container_ref = container
    player_ref = player
    is_static = false

    item_option_panel.visible = false

    store_button.pressed.connect(_on_store_to_pressed)
    take_button.pressed.connect(_on_take_to_pressed)
    close_button.pressed.connect(close)

    populate_items()  # ← tambah ini! atau panggil populate_static_items() kalau static

func setup_static(container, player):
    container_ref = container
    player_ref = player
    is_static = true

    item_option_panel.visible = false

    store_button.pressed.connect(_on_store_to_pressed)
    take_button.pressed.connect(_on_take_to_pressed)
    close_button.pressed.connect(close)

    populate_static_items()  # ← tambah ini kalau pakai mode static

func populate_items():
    for child in item_grid.get_children():
        child.queue_free()
    
    for item in container_ref.items:
        create_static_slot(item)
    
    # Paksa mouse filter di grid dan slot
    item_grid.mouse_filter = Control.MOUSE_FILTER_STOP
    for slot in item_grid.get_children():
        slot.mouse_filter = Control.MOUSE_FILTER_STOP

func populate_static_items():
    for item in container_ref.items:
        create_static_slot(item)
    item_grid.mouse_filter = Control.MOUSE_FILTER_STOP
    print("FRIDGE UI: ItemGrid mouse_filter dipaksa STOP →", item_grid.mouse_filter)

func create_static_slot(item_data):
    var slot = slot_scene.instantiate()
    item_grid.add_child(slot)
    slot.setup(item_data, self)
    
    # Paksa mouse filter STOP di root slot
    slot.mouse_filter = Control.MOUSE_FILTER_STOP
    print("FRIDGE UI: Slot dibuat, mouse_filter:", slot.mouse_filter)
    
    # Pastikan icon ignore
    var icon = slot.get_node("Icon")
    if icon:
        icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    slot.slot_clicked.connect(_on_slot_clicked)

func _on_slot_clicked(slot):
    select_item(slot.item_data, slot)

func select_item(item_data, slot):
    selected_item_data = item_data
    selected_slot = slot

    item_option_panel.visible = true


func _on_store_to_pressed():
    if selected_item_data == null:
        return

    if not player_ref.has_backpack:
        print("Tidak pakai tas.")
        return

    if InventoryManager.add_item(selected_item_data):
        StoreTransactionManager.register_unpaid_inventory(selected_item_data)
        print("Item masuk tas (UNPAID)")


func _on_take_to_pressed():
    if selected_item_data == null:
        return

    if player_ref.right_hand_equip_point.get_child_count() > 0 and player_ref.left_hand_equip_point.get_child_count() > 0:
        print("Tangan penuh.")
        return

    player_ref._use_item(null, selected_item_data, "store")
    StoreTransactionManager.register_unpaid_hand(selected_item_data)
    print("Item dipegang (UNPAID)")


func close():
    if player_ref:
        player_ref.input_locked = false
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if container_ref:
        container_ref.current_ui = null

    queue_free()
