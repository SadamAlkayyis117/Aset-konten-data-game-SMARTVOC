extends Control

signal finished(success: bool, score: int)

# =========================
# KONFIGURASI
# =========================
const GRID_SIZE := 5
const TIME_LIMIT := 120

# =========================
# STATE
# =========================
var vocab_pool: Array = []
var across_word: String
var down_word: String
var intersection_index_across := 0
var intersection_index_down := 0
var time_left := TIME_LIMIT
var timer: Timer

# =========================
# UI
# =========================
@onready var label_timer: Label = $Timerr/LabelTimer
@onready var label_clue: Label = $Clue/LabelClue
@onready var label_feedback: Label = $LabelFeedback
@onready var grid: Control = $"Crossword Grid"

# =========================
# READY
# =========================
func _ready():
    timer = Timer.new()
    timer.wait_time = 1
    timer.timeout.connect(_on_timer_tick)
    add_child(timer)

# =========================
# START GAME
# =========================
func start_game(data: Dictionary):
    var player_level: int = data.get("player_level", 1)
    var raw_vocab: Array = data.get("vocabulary", [])

    vocab_pool.clear()
    for v in raw_vocab:
        if v is Dictionary and v.get("level", 0) <= player_level:
            vocab_pool.append(v)

    _generate_crossword()
    timer.start()

# =========================
# GENERATE CROSSWORD
# =========================
func _generate_crossword():
    if vocab_pool.size() < 2: return
    
    vocab_pool.shuffle()
    var v1 = vocab_pool.pick_random()
    var v2 = vocab_pool.pick_random()

    across_word = str(v1.get("word", "")).to_lower()
    down_word = str(v2.get("word", "")).to_lower()

    # Validasi panjang kata agar muat di grid
    var attempts = 0
    while (across_word.length() > GRID_SIZE or down_word.length() > GRID_SIZE or across_word == down_word) and attempts < 50:
        v2 = vocab_pool.pick_random()
        down_word = str(v2.get("word", "")).to_lower()
        attempts += 1

    # Cari huruf perpotongan
    for i in across_word.length():
        for j in down_word.length():
            if across_word[i] == down_word[j]:
                intersection_index_across = i
                intersection_index_down = j
                _place_words(i, j)
                _set_clue(v1, v2)
                return

    # fallback kalau gagal cari perpotongan, coba lagi
    _generate_crossword()

# =========================
# PLACE WORDS
# =========================
func _place_words(across_intersection: int, down_intersection: int):
    _clear_grid()

    # Across diletakkan di Baris 2 (tengah grid 5x5)
    for x in across_word.length():
        var cell = _cell(2, x)
        if cell: cell.editable = true

    # Down diletakkan memotong Baris 2 di kolom perpotongan
    for y in down_word.length():
        # Baris dihitung relatif agar memotong di baris 2
        var target_row = 2 - down_intersection + y
        if target_row >= 0 and target_row < GRID_SIZE:
            var cell = _cell(target_row, across_intersection)
            if cell: cell.editable = true

# =========================
# CLUE
# =========================
func _set_clue(v1, v2):
    label_clue.text = "Across: " + _build_clue(v1) + "\nDown: " + _build_clue(v2)

# =========================
# BUILD CLUE
# =========================
func _build_clue(v) -> String:
    var options = []
    if v.get("meaning", "") != "": options.append("meaning")
    if not v.get("synonym", []).is_empty(): options.append("synonym")
    if not v.get("antonym", []).is_empty(): options.append("antonym")
    
    var t = options.pick_random() if not options.is_empty() else "meaning"

    match t:
        "meaning":
            return v.get("meaning", "No clue")
        "synonym":
            return "Sinonim: " + str(v.synonym.pick_random())
        "antonym":
            return "Antonim: " + str(v.antonym.pick_random())
    
    return "No clue available"

# =========================
# CHECK ANSWER
# =========================
func _on_Button_Check_pressed():
    if _check_all():
        timer.stop()
        label_feedback.text = "✅ Crossword benar!"
        _finish(true)
    else:
        label_feedback.text = "❌ Masih ada yang salah"

func _check_all() -> bool:
    # Cek Across
    for i in across_word.length():
        var cell = _cell(2, i)
        if cell.text.to_lower() != across_word[i]: return false
    
    # Cek Down
    for y in down_word.length():
        var target_row = 2 - intersection_index_down + y
        if target_row >= 0 and target_row < GRID_SIZE:
            var cell = _cell(target_row, intersection_index_across)
            if cell.text.to_lower() != down_word[y]: return false
            
    return true

# =========================
# GRID UTIL
# =========================
func _cell(row: int, col: int) -> LineEdit:
    return grid.get_node_or_null("Cell_%d_%d" % [row, col])

func _clear_grid():
    for c in grid.get_children():
        if c is LineEdit:
            c.text = ""
            c.editable = false

# =========================
# TIMER
# =========================
func _on_timer_tick():
    time_left -= 1
    label_timer.text = str(time_left)

    if time_left <= 0:
        timer.stop()
        _finish(false)

# =========================
# FINISH
# =========================
func _finish(success: bool):
    # FIX LINE 140 & 172: Gunakan format ternary GDScript 4
    var score: int = 1 if success else 0
    emit_signal("finished", success, score)
    queue_free()
