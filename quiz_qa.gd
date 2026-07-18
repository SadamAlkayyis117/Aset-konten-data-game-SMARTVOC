extends Control

signal finished(success: bool, score: int)

# DEBUG TAG
const TAG = "[QuizQA]"

const TOTAL_QUESTIONS := 10
const MIN_SUCCESS := 8
const TIME_PER_QUESTION := 15

enum QuestionType {
    MEANING,
    SYNONYM,
    ANTONYM,
    POS,
    PREPOSITION,
    COLLOCATION
}

var vocab_pool: Array = []
var questions: Array = []
var current_index: int = 0
var score: int = 0
var correct_answer: String = ""
var time_left: int = TIME_PER_QUESTION
var timer: Timer

@onready var label_question = $"Latar soal/LabelSoal"
@onready var label_counter = $LabelCounter
@onready var label_feedback = $LabelFeedback
@onready var label_timer = $Paneltime/LabelTimer

@onready var buttons: Array = [
    $ButtonA,
    $ButtonB,
    $ButtonC,
    $ButtonD
]

func _ready() -> void:
    # WAJIB: Agar jalan saat pause
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    print("%s _ready() called. ProcessMode: WHEN_PAUSED" % [TAG])
    
    randomize()
    
    # Memastikan semua label bersih saat mulai
    label_feedback.text = ""
    
    # Koneksi tombol dengan proteksi double-signal
    for b in buttons:
        if b:
            b.focus_mode = Control.FOCUS_NONE
            if b.pressed.is_connected(_on_answer_pressed):
                b.pressed.disconnect(_on_answer_pressed)
            b.pressed.connect(func(): _on_answer_pressed(b.text))

    # Setup Timer
    timer = Timer.new()
    timer.wait_time = 1
    timer.one_shot = false
    timer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    timer.timeout.connect(_on_timer_tick)
    add_child(timer)


# ===============================
# START GAME
# ===============================
func start_game(data: Dictionary) -> void:
    print("%s start_game() called with data keys: %s" % [TAG, data.keys()])

    
    vocab_pool.clear()
    questions.clear()
    current_index = 0
    score = 0

    var player_level: int = data.get("player_level", 1)
    var raw_vocab: Array = data.get("vocabulary", [])
    print("[QuizQA] Vocabulary received:", raw_vocab.size())
    
    print("%s Raw Vocab Size: %d" % [TAG, raw_vocab.size()])

    # Filter data materi
    for v in raw_vocab:
        if v is Dictionary:
            vocab_pool.append(v)

    print("%s Filtered Vocab Pool Size: %d" % [TAG, vocab_pool.size()])

    if vocab_pool.is_empty():
        push_error("%s [CRITICAL] Materi kosong! Cek Level Player / JSON" % [TAG])
        _finish_game()
        return

    _generate_questions()
    _show_question()

# ===============================
# GENERATE QUESTIONS
# ===============================
func _generate_questions() -> void:
    var attempts := 0
    while questions.size() < TOTAL_QUESTIONS and attempts < 200:
        attempts += 1
        var v: Dictionary = vocab_pool.pick_random()
        var t: int = randi() % QuestionType.size()
        
        var q = _build_question(v, t)
        if q != null:
            questions.append(q)
    
    print("%s Questions Generated: %d" % [TAG, questions.size()])

# ===============================
# BUILD QUESTION
# ===============================
func _build_question(v: Dictionary, t: int) -> Variant:
    var correct: String = ""
    var options: Array = []

    match t:
        QuestionType.MEANING:
            correct = v.get("meaning", "")
            options = _collect_meanings(v)
        QuestionType.SYNONYM:
            var a: Array = v.get("synonym", [])
            if a.is_empty(): return null
            correct = a.pick_random()
            options = _collect_from_field("synonym", correct)
        QuestionType.ANTONYM:
            var a: Array = v.get("antonym", [])
            if a.is_empty(): return null
            correct = a.pick_random()
            options = _collect_from_field("antonym", correct)
        QuestionType.POS:
            correct = v.get("pos", "noun")
            options = ["noun", "verb", "adjective", "adverb"]
        QuestionType.PREPOSITION:
            var a: Array = v.get("preposition", [])
            if a.is_empty(): return null
            correct = a.pick_random()
            options = ["on", "in", "at", "with", "to", "for"]
        QuestionType.COLLOCATION:
            var a: Array = v.get("collocation", [])
            if a.is_empty(): return null
            correct = a.pick_random()
            options = _collect_from_field("collocation", correct)

    if correct == "" or options.size() < 4:
        # Filler safety
        while options.size() < 4:
            var filler_v = vocab_pool.pick_random()
            var filler = filler_v.get("meaning", "---")
            if filler not in options: options.append(filler)

    options.shuffle()
    return {
        "question": _build_stem(t, v),
        "correct": correct,
        "options": options
    }

# ===============================
# STEM VARIATIONS (3 PER BAGIAN)
# ===============================
func _build_stem(t: int, v: Dictionary) -> String:
    var w: String = v.get("word", "Unknown")
    var s: Array[String] = []
    match t:
        QuestionType.MEANING:
            s = ["“%s” paling tepat artinya…" % w, "Makna dari kata “%s” adalah…" % w, "Arti kata “%s” yang benar yaitu…" % w]
        QuestionType.SYNONYM:
            s = ["Sinonim terdekat dari “%s” adalah…" % w, "Kata yang maknanya paling mirip dengan “%s” yaitu…" % w, "Padanan kata dari “%s” yang tepat adalah…" % w]
        QuestionType.ANTONYM:
            s = ["Antonim terdekat dari “%s” adalah…" % w, "Lawan kata dari “%s” yaitu…" % w, "Kata yang berlawanan makna dengan “%s” adalah…" % w]
        QuestionType.POS:
            s = ["“%s” berfungsi sebagai…" % w, "Kelas kata dari “%s” adalah…" % w, "“%s” paling sering digunakan sebagai…" % w]
        QuestionType.PREPOSITION:
            s = ["“%s” diikuti preposisi yang benar…" % w, "Preposisi tepat untuk “%s ___” adalah…" % w, "Penggunaan preposisi untuk “%s” yaitu…" % w]
        QuestionType.COLLOCATION:
            s = ["Kolokasi umum untuk “%s” adalah…" % w, "Pasangan kata yang tepat dengan “%s” yaitu…" % w, "Frasa yang lazim bersama “%s” adalah…" % w]
    return s.pick_random()

# ===============================
# SHOW QUESTION
# ===============================
func _show_question() -> void:
    if current_index >= questions.size():
        _finish_game()
        return

    var q: Dictionary = questions[current_index]
    print("%s Showing Question #%d: %s" % [TAG, current_index+1, q["question"]])
    
    # Update Teks & Paksa Muncul (Show)
    label_question.text = str(q["question"])
    label_question.show()
    
    correct_answer = str(q["correct"])
    label_counter.text = "%d / %d" % [current_index + 1, questions.size()]
    label_feedback.text = ""

    for i in range(4):
        buttons[i].text = str(q["options"][i])
        buttons[i].disabled = false
        buttons[i].show()

    time_left = TIME_PER_QUESTION
    label_timer.text = str(time_left)
    timer.start()

# ===============================
# OPTION HELPERS
# ===============================
func _collect_meanings(v: Dictionary) -> Array:
    var o: Array = [v.get("meaning", "")]
    var i := 0
    while o.size() < 4 and i < 50:
        i += 1
        var m = vocab_pool.pick_random().get("meaning", "")
        if m != "" and m not in o: o.append(m)
    return o

func _collect_from_field(f: String, c: String) -> Array:
    var o: Array = [c]
    var i := 0
    while o.size() < 4 and i < 50:
        i += 1
        var data = vocab_pool.pick_random().get(f, [])
        if data is Array and not data.is_empty():
            var pick = data.pick_random()
            if pick not in o: o.append(pick)
    return o

func _on_timer_tick() -> void:
    time_left -= 1
    label_timer.text = str(time_left)
    if time_left <= 0:
        timer.stop()
        _on_answer_pressed("")

func _on_answer_pressed(ans: String) -> void:
    timer.stop()
    for b in buttons: b.disabled = true

    if ans == correct_answer:
        score += 1
        label_feedback.text = "✅ Benar"
    else:
        label_feedback.text = "❌ Salah\nJawaban: %s" % correct_answer

    # Gunakan timer yang independent dari pause jika perlu, tapi karena UI when_paused, timer biasa ok.
    await get_tree().create_timer(1).timeout
    current_index += 1
    _show_question()

func _finish_game() -> void:
    print("%s Game Finished. Score: %d" % [TAG, score])
    emit_signal("finished", score >= MIN_SUCCESS, score)
    queue_free()
