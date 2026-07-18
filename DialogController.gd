extends Node
class_name DialogController

# =====================================================
# SIGNALS
# =====================================================
signal dialog_started(dialog_id: String)
signal dialog_turn_changed(turn_index: int)
signal dialog_failed(turn_index: int, fail_type: String)
signal dialog_completed(dialog_id: String)

# =====================================================
# EXPORT
# =====================================================
@export var dialog_id: String
@export var npc_name: String = "NPC"

# =====================================================
# INTERNAL STATE
# =====================================================
var dialog_data: Dictionary = {}
var turns: Array[Dictionary] = []

var current_turn: int = 0
var dialog_active: bool = false
var last_fail_type: String = ""

# =====================================================
# PUBLIC API
# =====================================================

func start_dialog() -> Array:
    _reset_state()
    _load_dialog_data()

    if dialog_data.is_empty():
        push_error("DialogController: dialog_id '%s' not found" % dialog_id)
        return []

    dialog_active = true
    emit_signal("dialog_started", dialog_id)
    return get_current_npc_lines()


func get_current_npc_lines() -> Array:
    if not dialog_active:
        return []

    if current_turn >= turns.size():
        return []

    var turn: Dictionary = turns[current_turn]
    return turn.get("npc_lines", [])


func submit_player_input(player_text: String) -> Dictionary:
    if not dialog_active:
        return _fail_result("dialog_not_active")

    var normalized: String = _normalize_text(player_text)
    var turn: Dictionary = turns[current_turn]

    if _is_input_accepted(normalized, turn):
        return _handle_success(turn)
    else:
        return _handle_fail(turn)


func is_dialog_finished() -> bool:
    return current_turn >= turns.size()


func force_end_dialog() -> void:
    dialog_active = false
    current_turn = turns.size()
    emit_signal("dialog_completed", dialog_id)

# =====================================================
# INTERNAL LOGIC
# =====================================================

func _handle_success(turn: Dictionary) -> Dictionary:
    var responses: Array = turn.get("success_responses", [])
    var npc_reply: Dictionary = _pick_random_line(responses)

    current_turn += 1
    emit_signal("dialog_turn_changed", current_turn)

    if current_turn >= turns.size():
        dialog_active = false
        emit_signal("dialog_completed", dialog_id)

    return {
        "result": "success",
        "npc_reply": npc_reply,
        "turn_index": current_turn
    }


func _handle_fail(turn: Dictionary) -> Dictionary:
    var fail_responses: Dictionary = turn.get("fail_responses", {})
    var fail_type: String = _pick_fail_type(fail_responses)

    last_fail_type = fail_type
    var npc_reply: Dictionary = _pick_random_line(fail_responses.get(fail_type, []))

    emit_signal("dialog_failed", current_turn, fail_type)

    return {
        "result": "fail",
        "fail_type": fail_type,
        "npc_reply": npc_reply,
        "turn_index": current_turn
    }


func _is_input_accepted(text: String, turn: Dictionary) -> bool:
    var keywords: Array = turn.get("accept_keywords", [])
    var topics: Array = turn.get("accept_topics", [])

    for keyword in keywords:
        if text.find(String(keyword).to_lower()) != -1:
            return true

    for topic in topics:
        if text.find(String(topic).to_lower()) != -1:
            return true

    return false

# =====================================================
# DATA LOADING
# =====================================================

func _load_dialog_data() -> void:
    var path: String = "res://data/dialog/dialogs.json"

    if not FileAccess.file_exists(path):
        push_error("DialogController: dialog file not found")
        return

    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    var content: String = file.get_as_text()
    file.close()

    var json: Variant = JSON.parse_string(content)
    if typeof(json) != TYPE_DICTIONARY:
        push_error("DialogController: invalid JSON format")
        return

    var root: Dictionary = json
    for entry in root.get("npc_encounters", []):
        if entry.get("id", "") == dialog_id:
            dialog_data = entry
            turns = entry.get("turns", [])
            return

    push_error("DialogController: dialog_id '%s' not found in JSON" % dialog_id)

# =====================================================
# HELPERS
# =====================================================

func _reset_state() -> void:
    dialog_data.clear()
    turns.clear()
    current_turn = 0
    dialog_active = false
    last_fail_type = ""


func _normalize_text(text: String) -> String:
    return text.strip_edges().to_lower()


func _pick_random_line(lines: Array) -> Dictionary:
    if lines.is_empty():
        return { "text": "...", "emotion": "neutral" }

    var item: Variant = lines[randi() % lines.size()]
    if typeof(item) == TYPE_DICTIONARY:
        return item

    return { "text": str(item), "emotion": "neutral" }


func _pick_fail_type(fail_responses: Dictionary) -> String:
    if last_fail_type != "" and fail_responses.has(last_fail_type):
        return last_fail_type

    var keys: Array = fail_responses.keys()
    if keys.is_empty():
        return "confused"

    return String(keys[randi() % keys.size()])


func _fail_result(reason: String) -> Dictionary:
    return {
        "result": "fail",
        "reason": reason,
        "npc_reply": { "text": "...", "emotion": "neutral" },
        "turn_index": current_turn
    }
