extends CanvasLayer

signal use_pressed(item_node, item_data)
signal store_pressed(item_node, item_data)
signal canceled

@onready var item_name_label: Label = $Control/ItemName
@onready var use_button: Button = $Control/UseButton
@onready var store_button: Button = $Control/StoreButton
@onready var close_button: Button = $Control/CloseButton

var current_item_node: Node = null
var current_item_data: ItemData = null

func _ready():
    print("DEBUG: Popup _ready() dipanggil")
    print("DEBUG: Popup layer saat ini:", layer)  # ← ini aman, karena self adalah CanvasLayer
    print("DEBUG: Child nodes di popup:")
    for child in get_children():
        print(" - ", child.name)
    
    if use_button:
        use_button.pressed.connect(_on_use_pressed)
        print("DEBUG: UseButton connected")
    if store_button:
        store_button.pressed.connect(_on_store_pressed)
        print("DEBUG: StoreButton connected")
    if close_button:
        close_button.pressed.connect(_on_close_pressed)
        print("DEBUG: CloseButton connected")
    
    if item_name_label:
        print("DEBUG: ItemNameLabel ditemukan!")
    else:
        print("ERROR: ItemNameLabel masih null di _ready()!")
    
    visible = false

# DEBUG UTAMA: cek setiap klik mouse di popup root
func _gui_input(event):
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            print("DEBUG: KLIK KIRI di popup ROOT pada posisi:", event.position)
            print("DEBUG: Apakah popup visible?", visible)
            print("DEBUG: Apakah mouse mode visible?", Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE)
            #accept_event()  # biar tidak lolos ke bawah
        elif not event.pressed:
            print("DEBUG: Lepas klik di popup ROOT")

# DEBUG: cek kalau tombol benar-benar ditekan
func _on_use_pressed():
    print("DEBUG: UseButton ditekan! (signal pressed berhasil)")
    if current_item_node and current_item_data:
        emit_signal("use_pressed", current_item_node, current_item_data)
    hide_popup()

func _on_store_pressed():
    print("DEBUG: StoreButton ditekan! (signal pressed berhasil)")
    if current_item_node and current_item_data:
        emit_signal("store_pressed", current_item_node, current_item_data)
    hide_popup()

func _on_close_pressed():
    print("DEBUG: CloseButton ditekan! (signal pressed berhasil)")
    emit_signal("canceled")
    hide_popup()

func show_popup(item_node: Node, item_data: ItemData):
    if not is_instance_valid(item_name_label):
        print("ERROR: ItemNameLabel tidak ditemukan di popup!")
        return
    
    current_item_node = item_node
    current_item_data = item_data
    
    item_name_label.text = item_data.item_name
    if store_button:
        store_button.visible = item_data.is_storable
    
    visible = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    print("DEBUG: Popup ditampilkan, mouse visible")

func hide_popup():
    visible = false
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    current_item_node = null
    current_item_data = null
    print("DEBUG: Popup disembunyikan")
