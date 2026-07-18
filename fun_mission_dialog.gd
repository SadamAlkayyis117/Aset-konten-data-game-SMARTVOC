extends CanvasLayer
class_name FunMissionDialog

signal dialog_finished

@export var dialog_database_path := "res://funmissiondialog.json"
@export var dialog_id := ""

var turns = []
var index = 0

@onready var npc_text = $DialogCard/NpcText
@onready var player_input: LineEdit = $DialogCard/PlayerInput
@onready var button = $DialogCard/ButtonSubmit

func _ready():
    add_to_group("mission_ui")
    process_mode = Node.PROCESS_MODE_ALWAYS

    var gm = get_node_or_null("/root/GM")
    if gm:
        gm.mission_ui_open = true
    
    # 🔥 1. Tampilkan kursor & fokus ke input
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    player_input.grab_focus()
    
    # 🔥 2. Blokir input player (movement & action)
    _block_player_input(true)
    
    load_dialog()
    show_turn()
    button.pressed.connect(_next)
    
    # Optional: koneksi kalau ada signal pause dari luar
    # get_tree().paused = true  # kalau mau pause world saat dialog

func _exit_tree():
    var gm = get_node_or_null("/root/GM")
    if gm:
        gm.mission_ui_open = false

    _block_player_input(false)
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Fungsi blokir input player (movement & interaksi)
func _block_player_input(block: bool):
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.set_input_locked(block)
        print("DEBUG: Player input locked =", block)
    
    # Optional: blokir action global kalau perlu
    if block:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func load_dialog():
    if not FileAccess.file_exists(dialog_database_path):
        printerr("ERROR: Dialog JSON not found at ", dialog_database_path)
        return
    var file = FileAccess.open(dialog_database_path, FileAccess.READ)
    var text = file.get_as_text()
    file.close()
    var data = JSON.parse_string(text)
    if data == null:
        printerr("ERROR: Invalid JSON in dialog file")
        return
    for d in data.get("dialogs", []):
        if d["id"] == dialog_id:
            turns = d["turns"]
            print("DEBUG: Dialog loaded - ID:", dialog_id, "Turns:", turns.size())
            break

func show_turn():
    if index >= turns.size():
        dialog_finished.emit()
        queue_free()
        return
    
    var turn = turns[index]
    npc_text.text = "\n".join(turn["npc_lines"])
    player_input.text = ""
    player_input.grab_focus()  # fokus ulang setiap turn

func _next():
    var turn = turns[index]
    var text = player_input.text.to_lower().strip_edges()
    var keywords = turn["accept_keywords"]
    var valid = false
    
    for k in keywords:
        if text.find(k) != -1:
            valid = true
            break
    
    if valid:
        index += 1
        show_turn()
    else:
        var fails = turn["fail_responses"]
        npc_text.text = fails.pick_random()
        player_input.text = ""  # clear setelah salah
        player_input.grab_focus()
