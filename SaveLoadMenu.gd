extends CanvasLayer

enum Mode { LOAD, SAVE }
@export var mode : Mode = Mode.LOAD

var parent_menu: Node = null

@onready var slot_buttons := [
    $"Root/SaveloadBG/ScrollContainer/SlotContainer/Slot 1",
    $"Root/SaveloadBG/ScrollContainer/SlotContainer/Slot 2",
    $"Root/SaveloadBG/ScrollContainer/SlotContainer/Slot 3",
    $"Root/SaveloadBG/ScrollContainer/SlotContainer/Slot 4",
    $"Root/SaveloadBG/ScrollContainer/SlotContainer/Slot 5",
    $"Root/SaveloadBG/ScrollContainer/SlotContainer/Slot 6"
]

@onready var slot_info = $"Root/SaveloadBG/Slotinfo"
@onready var btn_load = $"Root/SaveloadBG/ButtonLoad"
@onready var btn_save = $"Root/SaveloadBG/ButtonSave"
@onready var btn_back = $"Root/SaveloadBG/ButtonBack"

var selected_slot := -1

func _ready():
    self.name = "SaveLoadMenu"
    process_mode = Node.PROCESS_MODE_ALWAYS # PENTING: Menu tidak boleh ikut freeze
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    # Matikan TimeManager hanya jika di dalam game (bukan main menu)
    if is_instance_valid(TimeManager) and not GM.is_opening:
        TimeManager.set_process(false)
    
    _toggle_touch_ui(false)

    # Bersihkan koneksi lama
    if btn_load.pressed.is_connected(_on_load_pressed): btn_load.pressed.disconnect(_on_load_pressed)
    if btn_save.pressed.is_connected(_on_save_pressed): btn_save.pressed.disconnect(_on_save_pressed)
    if btn_back.pressed.is_connected(_on_back_pressed): btn_back.pressed.disconnect(_on_back_pressed)
    
    btn_load.pressed.connect(_on_load_pressed)
    btn_save.pressed.connect(_on_save_pressed)
    btn_back.pressed.connect(_on_back_pressed)

    # --- FORCE MODE BERDASARKAN LOKASI ---
    # Jika di Main Menu, paksa Load Mode. Jika di Game, biarkan (biasanya Save)
    if is_instance_valid(GM) and GM.is_opening:
        mode = Mode.LOAD
    
    _refresh_slots()

func _refresh_slots():
    if not is_instance_valid(SaveManager): return
    var slots = SaveManager.get_all_save_slots()
    
    # Reset tombol (sembunyikan semua dulu)
    btn_load.visible = false
    btn_save.visible = false
    btn_load.disabled = true
    btn_save.disabled = true

    for i in range(slot_buttons.size()):
        var btn = slot_buttons[i]
        if not is_instance_valid(btn): continue
        var slot_data = slots[i]
        
        for conn in btn.pressed.get_connections():
            btn.pressed.disconnect(conn.callable)
        btn.pressed.connect(func(): _select_slot(slot_data.slot))

        if slot_data.exists:
            btn.text = "SLOT %d\n%s" % [slot_data.slot, slot_data.meta.real_datetime]
        else:
            btn.text = "SLOT %d\n<KOSONG>" % slot_data.slot

func _select_slot(slot: int):
    selected_slot = slot
    var slots = SaveManager.get_all_save_slots()
    var current_data = slots[slot-1]
    
    slot_info.text = "Slot %d\n%s" % [slot, current_data.meta.real_datetime if current_data.exists else "Kosong"]
    
    # --- LOGIKA TOMBOL FINAL & AMAN ---
    if is_instance_valid(GM) and GM.is_opening:
        # MAIN MENU: Hanya tombol Load, tombol Save hilang
        btn_load.visible = true
        btn_load.disabled = not current_data.exists
        btn_save.visible = false
    else:
        # IN GAME: Tombol Save SELALU muncul. Tombol Load muncul jika ada data.
        btn_save.visible = true
        btn_save.disabled = false
        
        btn_load.visible = current_data.exists
        btn_load.disabled = not current_data.exists

func _on_load_pressed():
    if selected_slot == -1 or not SaveManager.has_save(selected_slot):
        return

    print("[SaveLoadMenu] REQUEST LOAD SLOT", selected_slot)

    # Sebelum pindah, pastikan TimeManager sudah siap bangun
    if is_instance_valid(TimeManager):
        TimeManager.process_mode = Node.PROCESS_MODE_ALWAYS
        TimeManager.set_process(true)

    if is_instance_valid(GM):
        GM.process_mode = Node.PROCESS_MODE_ALWAYS
        GM.is_opening = false

    SaveManager.load_game(selected_slot)
    
    # Hapus menu agar tidak memblokir input di scene baru
    queue_free()

func _on_save_pressed():
    if selected_slot != -1:
        SaveManager.save_game(selected_slot)
        _refresh_slots()
        _select_slot(selected_slot)

func _on_back_pressed():
    _on_menu_closed()
    queue_free()

func _on_menu_closed():
    # Nyalakan kembali TimeManager saat menu ditutup (Cancel/Back)
    if is_instance_valid(TimeManager):
        TimeManager.set_process(true)
    
    _toggle_touch_ui(true)
    
    # Kembalikan PauseMenu jika ada
    if is_instance_valid(parent_menu):
        parent_menu.visible = true
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        # Kembalikan kontrol game
        if is_instance_valid(GM) and not GM.is_opening:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _toggle_touch_ui(is_visible: bool):
    var tree = get_tree()
    if tree:
        var touch_ui = tree.root.find_child("TouchscreenUI", true, false)
        if touch_ui: touch_ui.visible = is_visible
