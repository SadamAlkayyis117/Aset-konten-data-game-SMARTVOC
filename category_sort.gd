extends Control

signal finished(success: bool, score: int)

var vocab_data : Array = []

# =====================
# KONFIGURASI
# =====================
const TOTAL_ROUNDS := 8
const MIN_SUCCESS := 6
const TIME_PER_ROUND := 20

enum SortType {
    POS,
    SYNONYM,
    ANTONYM,
    MEANING
}

# =====================
# STATE
# =====================
var vocab_pool: Array = []
var current_round: int = 0
var score: int = 0
var selected_item: String = ""
var correct_map: Dictionary = {}
var time_left: int = TIME_PER_ROUND

var timer: Timer

# =====================
# UI
# =====================
@onready var label_instruction = $LabelInstruction
@onready var label_timer = $Timerr/LabelTimer
@onready var label_feedback = $LabelFeedback

@onready var item_buttons: Array = [
    $Itemroot/Item1,
    $Itemroot/Item2,
    $Itemroot/Item3,
    $Itemroot/Item4
]

# Perhatikan nama variabel ini: category_buttons
@onready var category_buttons: Array[Button] = [
    $CategoryArearoot/CategoryBox1/Categoryname1,
    $CategoryArearoot/CategoryBox2/Categoryname2,
    $CategoryArearoot/CategoryBox3/Categoryname3
]


# =====================
# READY
# =====================
func _ready():
    for b in item_buttons:
        if b:
            b.focus_mode = Control.FOCUS_NONE
            b.pressed.connect(func(): _on_item_selected(b.text))

    for btn in category_buttons:
        if btn:
            btn.pressed.connect(func(): _on_category_pressed(btn))

    timer = Timer.new()
    timer.wait_time = 1
    timer.timeout.connect(_on_timer_tick)
    add_child(timer)

# =====================
# START DARI POPUP
# =====================
func start_game(data: Dictionary):
    var player_level: int = data.get("player_level", 1)
    var raw_vocab: Array = data.get("vocabulary", [])

    vocab_pool.clear()
    for v in raw_vocab:
        if v is Dictionary and v.get("level", 0) <= player_level:
            vocab_pool.append(v)

    _next_round()

# =====================
# ROUND LOGIC
# =====================
func _next_round():
    if current_round >= TOTAL_ROUNDS:
        _finish_game()
        return

    current_round += 1
    label_feedback.text = ""
    selected_item = ""
    time_left = TIME_PER_ROUND
    label_timer.text = str(time_left)
    
    _generate_round()
    timer.start()

func _on_category_pressed(btn: Button):
    if selected_item == "":
        label_feedback.text = "Pilih item dulu!"
        return

    var category = btn.text

    if correct_map.has(selected_item) and correct_map[selected_item] == category:
        score += 1
        label_feedback.text = "✅ Benar!"
        # Kosongkan teks tombol item yang benar
        for b in item_buttons:
            if b.text == selected_item:
                b.text = ""
    else:
        label_feedback.text = "❌ Salah!"

    selected_item = ""

# =====================
# GENERATE SOAL
# =====================
func _generate_round():
    correct_map.clear()
    if vocab_pool.is_empty(): return

    var type = SortType.values().pick_random()

    match type:
        SortType.POS:
            label_instruction.text = "Kelompokkan berdasarkan jenis kata (POS)"
            _setup_pos()
        SortType.SYNONYM:
            label_instruction.text = "Kelompokkan ke Sinonim yang benar"
            _setup_synonym()
        SortType.ANTONYM:
            label_instruction.text = "Kelompokkan ke Antonim yang benar"
            _setup_antonym()
        SortType.MEANING:
            label_instruction.text = "Kelompokkan sesuai maknanya"
            _setup_meaning()

# =====================
# SETUP FUNCTIONS (FIXED IDENTIFIERS)
# =====================

func _setup_pos():
    var categories = ["noun", "verb", "adjective"]
    for i in range(3):
        var btn = category_buttons[i]
        if btn:
            btn.text = categories[i].capitalize()

    for i in range(4):
        var v = vocab_pool.pick_random()
        if item_buttons[i]:
            item_buttons[i].text = v.get("word", "???")
            correct_map[item_buttons[i].text] = str(v.get("pos", "noun")).capitalize()

func _setup_synonym():
    var temp_pool = vocab_pool.duplicate()
    temp_pool.shuffle()

    for i in range(3):
        var v = temp_pool.pop_back()
        var key_word = v.get("word", "Key")
        
        if category_buttons[i]:
            category_buttons[i].text = key_word

        var syns = v.get("synonym", [])
        if not syns.is_empty():
            var s = syns.pick_random()
            item_buttons[i].text = s
            correct_map[s] = key_word

    item_buttons[3].text = vocab_pool.pick_random().get("word", "???")
    correct_map[item_buttons[3].text] = "None"

func _setup_antonym():
    for i in range(3):
        var v = vocab_pool.pick_random()
        var key_word = v.get("word", "Key")
        
        if category_buttons[i]:
            category_buttons[i].text = "Antonym of: " + key_word

        var ants = v.get("antonym", [])
        if not ants.is_empty():
            var a = ants.pick_random()
            item_buttons[i].text = a
            correct_map[a] = "Antonym of: " + key_word

    item_buttons[3].text = vocab_pool.pick_random().get("word", "???")
    correct_map[item_buttons[3].text] = "None"

func _setup_meaning():
    for i in range(3):
        var v = vocab_pool.pick_random()
        var meaning = v.get("meaning", "???")
        
        if category_buttons[i]:
            category_buttons[i].text = meaning

        var word = v.get("word", "???")
        item_buttons[i].text = word
        correct_map[word] = meaning

    var extra = vocab_pool.pick_random().get("word", "???")
    item_buttons[3].text = extra
    correct_map[extra] = "None"

# =====================
# INTERAKSI
# =====================
func _on_item_selected(word: String):
    if word == "": return
    selected_item = word
    label_feedback.text = "Pilih kategori untuk: " + word

# =====================
# TIMER & FINISH
# =====================
func _on_timer_tick():
    time_left -= 1
    label_timer.text = str(time_left)
    if time_left <= 0:
        timer.stop()
        _next_round()

func _finish_game():
    timer.stop()
    var success = score >= MIN_SUCCESS
    emit_signal("finished", success, score)
    queue_free()
