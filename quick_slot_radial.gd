extends CanvasLayer

signal radial_item_selected(item_data)

@export var slot_count: int = 6
var active_slot: int = -1

@onready var radial_control: Control = $RadialControl
@onready var slots_container = $RadialControl/Slots

var radial_slots: Array = []  # isi QuickUseSlot node

func _ready():
    hide()
    _cache_slots()

func _cache_slots():
    radial_slots.clear()
    for child in slots_container.get_children():
        if child is QuickUseSlot:
            radial_slots.append(child)
            child.slot_used.connect(_on_slot_used)

func _on_slot_used(item_data):
    print("DEBUG: Menggunakan item dari radial:", item_data.item_name)
    close_radial()
    radial_item_selected.emit(item_data)

func open_radial():
    visible = true
    active_slot = -1

    var viewport = get_viewport()
    radial_control.global_position = viewport.get_visible_rect().size / 2 - radial_control.size / 2

    _update_slots_from_manager()

    # ⛔ Reset semua selection saat buka
    for slot in radial_slots:
        slot.deselect()
        slot.modulate = Color(1,1,1)

func close_radial():
    visible = false

func _update_slots_from_manager():
    var slot_items = QuickSlotManager.get_all_slot_items()

    for i in range(radial_slots.size()):
        if i < slot_items.size():
            var data = slot_items[i]

            if data != null:
                if radial_slots[i].item_data != data:
                    radial_slots[i].set_item(data)
            else:
                radial_slots[i].clear()

func _input(event):
    if not visible:
        return

    if event is InputEventMouseMotion:
        _update_selected_slot_from_mouse()

func _update_selected_slot_from_mouse():
    var mouse_pos = get_viewport().get_mouse_position() - radial_control.global_position
    var center = radial_control.size / 2
    var dir = mouse_pos - center
    var distance = dir.length()
    
    # Deselect semua dulu
    for slot in radial_slots:
        slot.deselect()
    
    # Hanya select kalau mouse di dalam radius slot (misal radius = 150 dari export var kamu)
    if distance <= 1:  # ganti dengan @export var radius kalau ada
        var angle = atan2(dir.y, dir.x) + PI/2
        if angle < 0:
            angle += TAU
        var index = int(round(angle / (TAU / slot_count))) % slot_count
        
        if index >= 0 and index < radial_slots.size():
            active_slot = index
            radial_slots[index].select()
            for i in range(radial_slots.size()):
                if i == index:
                    radial_slots[i].modulate = Color(1.2,1.2,1.2)
                else:
                    radial_slots[i].modulate = Color(1,1,1)
    else:
        active_slot = -1  # tidak select kalau mouse di luar
