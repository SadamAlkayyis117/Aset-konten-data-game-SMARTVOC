extends Control
class_name MissionDialog

signal dialog_finished(accepted: bool)

@export var dialog_database_path: String
@export var dialog_id: String

# ===== INTERNAL STATE =====
var dialog_data: Dictionary
var turns: Array
var current_turn_index: int = 0
var accepted: bool = false

# ===== NODE REFS =====
@onready var npc_text: RichTextLabel = $DialogCard/NpcText
@onready var player_input: LineEdit = $DialogCard/PlayerInput
@onready var submit_button: Button = $DialogCard/ButtonSubmit

# ==========================
func _ready() -> void:
    # Penting: Tetap jalan meski game di-pause oleh GlobalManager
    process_mode = Node.PROCESS_MODE_ALWAYS
    add_to_group("mission_ui")

    var gm = get_node_or_null("/root/GM")
    if gm:
        gm.mission_ui_open = true

    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    _block_player_input(true)
    load_dialog()
    show_current_turn()

    submit_button.pressed.connect(_on_submit_pressed)

    # Koneksi input keyboard ENTER untuk submit
    player_input.gui_input.connect(func(event):
        if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
            # Pastikan tidak sedang dipause saat tekan enter
            if not get_tree().paused:
                _on_submit_pressed()
    )

func _block_player_input(block: bool):
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.set_input_locked(block)
        print("DEBUG: Player input locked =", block)

func _exit_tree() -> void:
    var gm = get_node_or_null("/root/GM")
    if gm:
        gm.mission_ui_open = false

    # 🔥 TAMBAHAN WAJIB
    _block_player_input(false)

# ==========================
func load_dialog() -> void:
    if dialog_id.is_empty():
        push_error("Dialog ID empty")
        return

    var file := FileAccess.open(dialog_database_path, FileAccess.READ)
    if file == null:
        push_error("Dialog DB not found: " + dialog_database_path)
        return

    var data: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()

    var encounters: Array = data.get("npc_encounters", [])
    for e in encounters:
        if e.get("id", "") == dialog_id:
            dialog_data = e
            turns = dialog_data.get("turns", [])
            return

    push_error("Dialog ID not found in DB: " + dialog_id)


# ==========================
func show_current_turn() -> void:
    if current_turn_index >= turns.size():
        end_dialog(true)
        return

    var turn: Dictionary = turns[current_turn_index]
    var npc_lines: Array = turn.get("npc_lines", [])

    if npc_lines.is_empty():
        npc_text.text = "[i]..."
    else:
        var chosen: Dictionary = npc_lines.pick_random()
        npc_text.text = chosen.get("text", "...")

    # 🔥 RESET UI STATE SETIAP TURN
    player_input.text = ""
    player_input.editable = true
    submit_button.disabled = false

    call_deferred("_focus_input")

func _focus_input():
    if is_instance_valid(player_input):
        player_input.grab_focus()

# ==========================
func _on_submit_pressed(_text := "") -> void:
    if current_turn_index >= turns.size():
        return

    # LOCK INPUT
    player_input.editable = false
    submit_button.disabled = true

    var input_text := player_input.text.strip_edges().to_lower()
    if input_text.is_empty():
        player_input.editable = true
        submit_button.disabled = false
        player_input.grab_focus()
        return

    var turn: Dictionary = turns[current_turn_index]

    if is_input_valid(input_text, turn):
        current_turn_index += 1

        # ⚠️ JANGAN AWAIT DI SINI
        show_current_turn()
    else:
        show_fail_response(turn)
        player_input.editable = true
        submit_button.disabled = false
        player_input.grab_focus()

func on_pause_opened():
    player_input.editable = false
    player_input.release_focus()

func on_pause_closed():
    player_input.editable = true
    call_deferred("_focus_input")

# ==========================
func is_input_valid(input_text: String, turn: Dictionary) -> bool:
    var keywords: Array = turn.get("accept_keywords", [])
    var topics: Array = turn.get("accept_topics", [])

    for k in keywords:
        if input_text.find(k.to_lower()) != -1:
            return true

    for t in topics:
        if input_text.find(t.to_lower()) != -1:
            return true

    return false

# ==========================
func show_fail_response(turn: Dictionary) -> void:
    var fail_responses: Dictionary = turn.get("fail_responses", {})
    var pool: Array = []

    if fail_responses.has("confused"):
        pool += fail_responses["confused"]

    if fail_responses.has("annoyed"):
        pool += fail_responses["annoyed"]

    if pool.is_empty():
        npc_text.text = "What do you mean?"
    else:
        npc_text.text = pool.pick_random()

# ==========================
func end_dialog(success: bool) -> void:
    accepted = success
    dialog_finished.emit(accepted)
    # Saat dialog selesai, kita kembalikan kontrol ke game
    var gm = get_node_or_null("/root/GM")
    if gm:
        gm.mission_ui_open = false
        # Kembalikan ke captured hanya jika ini akhir interaksi
        # Jika lanjut ke report, nanti report yang set visible lagi
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) 
    
    queue_free()
