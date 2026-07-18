extends Control

signal finished(success: bool, score: int)

const TAG = "[FillTheBlank]"

# =========================
# CONFIG
# =========================
const TOTAL_QUESTIONS := 30
const MIN_SUCCESS := 25
const TIME_PER_QUESTION := 25 # Ditambah karena membaca percakapan butuh waktu lebih lama

# =========================
# STATE
# =========================
var vocab_pool: Array[Dictionary] = []
var questions: Array[Dictionary] = []
var current_index: int = 0
var score: int = 0
var time_left: int = TIME_PER_QUESTION
var timer: Timer

var current_blanks: Array[String] = []
var filled_answers: Array[String] = []

# =========================
# UI
# =========================
@onready var label_question: RichTextLabel = $QA/LabelQuestion
@onready var label_counter: Label = $Counter/LabelCounter
@onready var label_timer: Label = $Timerr/LabelTimer
@onready var label_feedback: RichTextLabel = $LabelFeedback

@onready var option_buttons: Array[Button] = [
    $OptionContainer/WordButton1,
    $OptionContainer/WordButton2,
    $OptionContainer/WordButton3,
    $OptionContainer/WordButton4,
    $OptionContainer/WordButton5,
    $OptionContainer/WordButton6,
    $OptionContainer/WordButton7
]

# =========================
# READY
# =========================
func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    for b in option_buttons:
        if b:
            b.focus_mode = Control.FOCUS_NONE
            b.pressed.connect(self._on_button_pressed.bind(b))

    timer = Timer.new()
    timer.wait_time = 1
    timer.timeout.connect(_on_timer_tick)
    add_child(timer)

func _on_button_pressed(b: Button):
    _on_word_selected(b.text)

# =========================
# START
# =========================
func start_game(data: Dictionary):
    var raw_vocab: Array = data.get("words", [])
    if raw_vocab.is_empty():
        raw_vocab = data.get("vocabulary", [])

    vocab_pool.clear()
    for v in raw_vocab:
        if v is Dictionary:
            vocab_pool.append(v)

    if vocab_pool.is_empty(): return

    _generate_questions()
    _show_question()

# =========================
# GENERATE QUESTIONS
# =========================
func _generate_questions():
    questions.clear()
    var attempts = 0
    while questions.size() < TOTAL_QUESTIONS and attempts < 400:
        attempts += 1
        # 50% peluang soal percakapan, 50% soal teknis kompleks
        var q: Dictionary
        if randf() > 0.5:
            q = _build_conversation_question()
        else:
            q = _build_complex_question()
            
        if not q.is_empty():
            questions.append(q)

# =========================
# CONVERSATION GENERATOR
# =========================
func _build_conversation_question() -> Dictionary:
    var v: Dictionary = vocab_pool.pick_random()
    var word_en = str(v.get("word", "")).to_lower()
    var meaning = str(v.get("meaning", ""))
    
    # Pilih template percakapan secara acak
    var templates = [
        {
            "text": "A: Do you know what '[color=cyan]%s[/color]' means?\nB: Yes, it means [blank0].",
            "ans": [meaning]
        },
        {
            "text": "A: Can you use '[color=cyan]%s[/color]' in a sentence?\nB: Sure, '[i][blank0][/i]' is a good example.",
            "ans": [word_en]
        },
        {
            "text": "A: Hey, I found the word '[color=cyan]%s[/color]'. Is it a verb?\nB: No, the part of speech is actually [blank0].",
            "ans": [str(v.get("pos", "unknown"))]
        },
        {
            "text": "A: I'm confused about '[color=cyan]%s[/color]'.\nB: Don't be! It simply means [blank0] and it is a [blank1].",
            "ans": [meaning, str(v.get("pos", ""))]
        }
    ]
    
    # Tambahkan template kolokasi jika ada
    var colls = v.get("collocation", [])
    if not colls.is_empty():
        var c = str(colls.pick_random())
        templates.append({
            "text": "A: How do we say '[i]%s[/i]' correctly?\nB: You should say '[i]%s[/i]'. The missing word is [blank0].",
            "ans": [word_en],
            "extra": c.replace(word_en, "_____")
        })

    var selected = templates.pick_random()
    var final_text = selected["text"]
    
    # Jika ada data extra (seperti kalimat kolokasi yang disensor)
    if selected.has("extra"):
        final_text = final_text % [selected["extra"], word_en]
    else:
        final_text = final_text % word_en

    return _finalize_q_data(final_text, selected["ans"])

# =========================
# COMPLEX TECHNICAL GENERATOR
# =========================
func _build_complex_question() -> Dictionary:
    var v: Dictionary = vocab_pool.pick_random()
    var word_en = str(v.get("word", "")).to_upper()
    var components = []
    
    if v.has("meaning"): components.append({"q": "berarti [blank]", "a": str(v.meaning)})
    if v.has("pos"): components.append({"q": "jenisnya [blank]", "a": str(v.pos)})
    
    var syns = v.get("synonym", [])
    if not syns.is_empty(): components.append({"q": "sinonim: [blank]", "a": str(syns.pick_random())})
    
    var blank_count = randi_range(1, mini(3, components.size()))
    if blank_count == 0: return {}
    
    components.shuffle()
    var selected = components.slice(0, blank_count)
    var final_sentence = "Analisa Kata [b][color=yellow]%s[/color][/b]: " % word_en
    var final_answers: Array[String] = []
    
    for i in range(selected.size()):
        final_sentence += selected[i]["q"].replace("[blank]", "[blank%d]" % i)
        final_answers.append(selected[i]["a"])
        if i < selected.size() - 1: final_sentence += " & "

    return _finalize_q_data(final_sentence, final_answers)

# =========================
# HELPER: FINALIZE DATA & DECOYS
# =========================
func _finalize_q_data(sentence: String, answers: Array) -> Dictionary:
    var final_answers: Array[String] = []
    for a in answers: final_answers.append(str(a))
    
    var options: Array[String] = []
    options.append_array(final_answers)
    
    var safety = 0
    while options.size() < option_buttons.size() and safety < 100:
        safety += 1
        var dv = vocab_pool.pick_random()
        var keys = ["word", "meaning", "pos", "synonym"]
        var val = dv.get(keys.pick_random())
        var decoy = ""
        if val is Array and not val.is_empty(): decoy = str(val.pick_random())
        elif val is String: decoy = val
        
        if decoy != "" and not decoy in options:
            options.append(decoy)
    
    options.shuffle()
    return { "raw_sentence": sentence, "answers": final_answers, "options": options }

# =========================
# UI RENDERING & GAME LOGIC
# =========================
func _render_sentence(raw: String, filled: Array[String], blanks: Array[String]) -> String:
    var res: String = raw
    for i in range(filled.size()):
        res = res.replace("[blank"+str(i)+"]", "[b][color=lime]%s[/color][/b]" % filled[i])
    for j in range(filled.size(), blanks.size()):
        res = res.replace("[blank"+str(j)+"]", "[u][color=gray]_____[/color][/u]")
    return res

func _show_question():
    if current_index >= questions.size():
        _finish_game()
        return

    label_feedback.text = ""
    label_counter.text = "PROGRES: %d/%d" % [current_index + 1, TOTAL_QUESTIONS]

    var q: Dictionary = questions[current_index]
    current_blanks.clear()
    for a in q["answers"]: current_blanks.append(str(a))
    filled_answers.clear()
    
    label_question.text = _render_sentence(q["raw_sentence"], filled_answers, current_blanks)

    for i in range(option_buttons.size()):
        if i < q["options"].size():
            option_buttons[i].text = str(q["options"][i])
            option_buttons[i].visible = true
            option_buttons[i].disabled = false
        else:
            option_buttons[i].visible = false

    time_left = TIME_PER_QUESTION
    label_timer.text = str(time_left)
    timer.start()

func _on_word_selected(word: String):
    if filled_answers.size() >= current_blanks.size(): return
    filled_answers.append(word)
    label_question.text = _render_sentence(questions[current_index]["raw_sentence"], filled_answers, current_blanks)
    if filled_answers.size() == current_blanks.size(): _check_answer()

func _check_answer():
    timer.stop()
    for b in option_buttons: if b: b.disabled = true
    var correct = true
    for i in range(current_blanks.size()):
        if i >= filled_answers.size():
            correct = false
            break
        if filled_answers[i] != current_blanks[i]:
            correct = false
            break

    if correct:
        score += 1
        label_feedback.text = "[color=lime]MANTAP![/color]"
    else:
        label_feedback.text = "[color=red]SALAH![/color] Ans: " + ", ".join(current_blanks)

    await get_tree().create_timer(1.5).timeout
    current_index += 1
    _show_question()

func _on_timer_tick():
    time_left -= 1
    label_timer.text = str(time_left)
    if time_left <= 0:
        timer.stop()
        _check_answer()

func _finish_game():
    emit_signal("finished", score >= MIN_SUCCESS, score)
    queue_free()
