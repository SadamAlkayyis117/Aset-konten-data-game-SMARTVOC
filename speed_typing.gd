extends Control

signal finished(success: bool, score: int)

# =========================
# KONFIGURASI
# =========================
const TOTAL_QUESTIONS := 15
const MIN_SUCCESS := 13
const TIME_PER_QUESTION := 8 # detik (speed test)

# Template Pertanyaan dalam Bahasa Indonesia
const QUESTION_TEMPLATES := {
    SpeedType.WORD_FROM_MEANING: [
        "Ketik kosakata Inggris dari arti berikut:\n\"%s\"",
        "Apa kata bahasa Inggris untuk:\n\"%s\"",
        "Terjemahkan ke bahasa Inggris:\n\"%s\""
    ],
    SpeedType.MEANING_FROM_WORD: [
        "Apa arti bahasa Indonesia dari kata:\n\"%s\"",
        "Ketik arti kata:\n\"%s\"",
        "Masukkan arti yang tepat dari:\n\"%s\""
    ],
    SpeedType.SYNONYM: [
        "Ketik sinonim (persamaan kata) dari:\n\"%s\"",
        "Apa sinonim dari kata berikut:\n\"%s\"",
        "Tuliskan kata yang mirip maknanya dengan:\n\"%s\""
    ],
    SpeedType.ANTONYM: [
        "Ketik antonim (lawan kata) dari:\n\"%s\"",
        "Apa lawan kata dari:\n\"%s\"",
        "Tuliskan antonim yang benar untuk:\n\"%s\""
    ],
    SpeedType.POS_FORM: [
        "Termasuk jenis kata (POS) apakah:\n\"%s\"",
        "Apa kategori Part of Speech dari:\n\"%s\"",
        "Ketik jenis kata (noun/verb/adj) untuk:\n\"%s\""
    ],
    SpeedType.COMPLETE_SENTENCE: [
        "Lengkapi bagian kosong berikut:\n\"%s\"",
        "Ketik kata yang hilang dari frasa ini:\n\"%s\"",
        "Isi bagian '____' pada kalimat:\n\"%s\""
    ]
}

enum SpeedType {
    WORD_FROM_MEANING,
    MEANING_FROM_WORD,
    SYNONYM,
    ANTONYM,
    POS_FORM,
    COMPLETE_SENTENCE
}

# =========================
# STATE
# =========================
var vocab_pool: Array = []
var questions: Array = []
var current_index: int = 0
var score: int = 0
var correct_answer: String = ""
var time_left: int = TIME_PER_QUESTION
var timer: Timer

# =========================
# UI
# =========================
@onready var label_question: Label = $PanelQuestion/LabelQuestion
@onready var label_timer: Label = $Timerr/LabelTimer
@onready var label_feedback: Label = $LabelFeedback
@onready var input_answer: LineEdit = $Jawaban/LineEditAnswer

# =========================
# READY
# =========================
func _ready():
    randomize()
    input_answer.text = ""
    input_answer.editable = true
    input_answer.grab_focus()
    input_answer.text_submitted.connect(_on_submit)

    timer = Timer.new()
    timer.wait_time = 1
    timer.timeout.connect(_on_timer_tick)
    add_child(timer)

# =========================
# START GAME
# =========================
func start_game(data: Dictionary):
    var _player_level: int = data.get("player_level", 1)
    var raw_vocab: Array = data.get("vocabulary", [])
    
    # Jika data datang dari struktur JSON 'words'
    if raw_vocab.is_empty():
        raw_vocab = data.get("words", [])

    vocab_pool.clear()
    for v in raw_vocab:
        if v is Dictionary:
            vocab_pool.append(v)

    if vocab_pool.is_empty():
        push_error("SpeedTest: Vocab pool is empty!")
        return

    _generate_questions()
    _show_question()

# =========================
# GENERATE SOAL
# =========================
func _generate_questions():
    questions.clear()
    var attempts = 0
    
    while questions.size() < TOTAL_QUESTIONS and attempts < 300:
        attempts += 1
        var v = vocab_pool.pick_random()
        var qtype = randi() % SpeedType.size()

        var q = _build_question(v, qtype)
        if q != null:
            questions.append(q)

# =========================
# BUILDER SOAL (LOGIKA DIPERBAIKI)
# =========================
func _build_question(v: Dictionary, qtype: int) -> Variant:
    var prompt: String = ""
    var answer: String = ""
    
    var word_en: String = str(v.get("word", ""))
    var meaning_id: String = str(v.get("meaning", ""))
    var template: String = QUESTION_TEMPLATES[qtype].pick_random()

    match qtype:
        SpeedType.WORD_FROM_MEANING:
            prompt = template % meaning_id
            answer = word_en

        SpeedType.MEANING_FROM_WORD:
            prompt = template % word_en
            answer = meaning_id

        SpeedType.SYNONYM:
            var syns: Array = v.get("synonym", [])
            if syns.is_empty(): return null
            prompt = template % word_en
            answer = str(syns.pick_random())

        SpeedType.ANTONYM:
            var ants: Array = v.get("antonym", [])
            if ants.is_empty(): return null
            prompt = template % word_en
            answer = str(ants.pick_random())

        SpeedType.POS_FORM:
            var pos_val: String = str(v.get("pos", ""))
            if pos_val == "": return null
            prompt = template % word_en
            answer = pos_val

        SpeedType.COMPLETE_SENTENCE:
            var colls: Array = v.get("collocation", [])
            if colls.is_empty(): return null
            
            var full_text: String = str(colls.pick_random())
            # Sensor kata EN di dalam kalimat kolokasi
            if word_en.to_lower() in full_text.to_lower():
                # Gunakan RegEx atau replace sederhana untuk menyembunyikan jawaban
                var regex = RegEx.new()
                regex.compile("(?i)" + word_en) # case insensitive
                prompt = template % regex.sub(full_text, "____", true)
                answer = word_en
            else:
                return null

    if answer == "" or prompt == "": return null

    return {
        "question": prompt,
        "answer": answer
    }

# =========================
# TAMPILKAN SOAL
# =========================
func _show_question():
    if current_index >= questions.size():
        _finish_game()
        return

    label_feedback.text = ""
    input_answer.text = ""
    input_answer.editable = true
    input_answer.grab_focus()

    var q = questions[current_index]
    label_question.text = q.question
    correct_answer = q.answer

    time_left = TIME_PER_QUESTION
    label_timer.text = str(time_left)
    timer.start()

# =========================
# TIMER & SUBMIT
# =========================
func _on_timer_tick():
    time_left -= 1
    label_timer.text = str(time_left)
    if time_left <= 0:
        timer.stop()
        _validate_answer("")

func _on_submit(text: String):
    timer.stop()
    _validate_answer(text)

# =========================
# VALIDASI (STRICT & CLEAN)
# =========================
func _validate_answer(text: String):
    input_answer.editable = false
    
    # Normalisasi input agar tidak case-sensitive
    var user_ans = text.strip_edges().to_lower()
    var target_ans = correct_answer.strip_edges().to_lower()

    if user_ans == target_ans and user_ans != "":
        score += 1
        label_feedback.text = "✅ Benar!"
    else:
        label_feedback.text = "❌ Salah\nJawaban: %s" % correct_answer

    await get_tree().create_timer(0.8).timeout

    current_index += 1
    _show_question()

# =========================
# SELESAI
# =========================
func _finish_game():
    timer.stop()
    var success: bool = score >= MIN_SUCCESS
    emit_signal("finished", success, score)
    queue_free()
