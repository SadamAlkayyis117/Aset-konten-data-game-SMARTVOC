extends CanvasLayer

# ===== NODE REFERENCES =====
@onready var panel_quiz      = $"panel quiz"
@onready var label_soal      = $"panel quiz/PanelSoal/LabelSoal"
@onready var input_answer    = $"panel quiz/LineEditAnswer"
@onready var label_feedback  = $"panel quiz/LabelFeedback"
@onready var btn_submit      = $"panel quiz/ButtonSubmit"
@onready var btn_back        = $"panel quiz/ButtonBack"

# ===== DATA =====
var current_quiz_data : Dictionary
var current_question  : Dictionary
var is_correct        := false
var current_lang      := "en"

func _ready() -> void:
    # Hubungkan sinyal tombol secara manual jika belum di Editor
    if not btn_submit.pressed.is_connected(_on_submit_pressed):
        btn_submit.pressed.connect(_on_submit_pressed)
    if not btn_back.pressed.is_connected(_on_back_pressed):
        btn_back.pressed.connect(_on_back_pressed)
    
    panel_quiz.visible = false

# Fungsi utama yang dipanggil dari ChapterStory
func open_quiz(quiz_data: Dictionary, lang: String) -> void:
    current_quiz_data = quiz_data
    current_lang = lang
    is_correct = false
    
    if not current_quiz_data.has("questions") or current_quiz_data.questions.is_empty():
        push_error("[Quiz] Data soal tidak ditemukan!")
        return

    # Ambil soal secara acak dari database chapter tersebut
    current_question = current_quiz_data.questions.pick_random()

    # Set visual
    label_soal.text = current_question.question.get(current_lang, "No Question")
    input_answer.text = ""
    input_answer.editable = true
    label_feedback.text = "Tulis jawaban dengan teliti (Sensitive Case)!"
    label_feedback.modulate = Color.WHITE

    panel_quiz.visible = true
    self.show()

func _on_submit_pressed() -> void:
    if is_correct: return

    var user_ans = input_answer.text.strip_edges() # Hapus spasi di awal/akhir saja
    var correct_ans = current_question.answer.get(current_lang, "")

    # STRICT SENSITIVE CASE CHECK
    # Menggunakan "==" memastikan huruf besar, kecil, dan simbol harus 100% identik
    if user_ans == correct_ans:
        _process_win()
    else:
        _process_fail()

func _process_win() -> void:
    is_correct = true
    label_feedback.text = "CORRECT! +%d EXP" % current_quiz_data.get("exp", 10)
    label_feedback.modulate = Color.GREEN
    input_answer.editable = false
    
    # Tambahkan EXP ke Global Manager
    if GM.has_method("add_exp"):
        GM.add_exp(current_quiz_data.get("exp", 10))
    
    # Beri jeda sebentar lalu tutup otomatis atau biarkan player klik back
    await get_tree().create_timer(2.0).timeout
    _on_back_pressed()

func _process_fail() -> void:
    label_feedback.text = "WRONG! Periksa huruf kapital atau typo."
    label_feedback.modulate = Color.RED
    
    # Efek kocok (shake) pada input jika salah
    var tween = create_tween()
    tween.tween_property(input_answer, "position:x", input_answer.position.x + 10, 0.05)
    tween.tween_property(input_answer, "position:x", input_answer.position.x - 10, 0.05)
    tween.tween_property(input_answer, "position:x", input_answer.position.x, 0.05)

func _on_back_pressed() -> void:
    panel_quiz.visible = false
    self.hide()
    # Jika ingin menghapus scene sepenuhnya saat tutup:
    # queue_free()
