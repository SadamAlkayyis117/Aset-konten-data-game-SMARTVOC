extends CanvasLayer

# Menjaga dua scene berbeda sesuai struktur awalmu
@export var minigame_practice_scene: PackedScene
@export var minigame_exam_scene: PackedScene

@onready var label_text = $Panel/Label
@onready var btn_practice = $Panel/latihan
@onready var btn_exam = $Panel/ujian
@onready var btn_confirm = $Panel/BtnConfirm

var teacher_ref

func open(teacher):
    teacher_ref = teacher

    # === CEK LULUS UJIAN DARI PROGRESS MANAGER ===
    if ProgressManager.just_passed_exam:
        _show_exam_pass_dialog()
    else:
        _update_ui()

    show()

func _ready():
    # Agar dialog tidak ikut membeku saat game di-pause
    process_mode = Node.PROCESS_MODE_ALWAYS
    
    btn_practice.pressed.connect(_on_practice)
    btn_exam.pressed.connect(_on_exam)
    btn_confirm.pressed.connect(_on_confirm)

# ========================
# DIALOG LULUS UJIAN
# ========================
func _show_exam_pass_dialog():
    label_text.text = "Mantap, kemampuanmu ada peningkatan. Teruskan ya dan jangan lupa self reward-nya biar kamu semangat terus."

    btn_practice.visible = false
    btn_exam.visible = false

    btn_confirm.visible = true
    btn_confirm.text = "Ya baik bu"

    # reset flag di ProgressManager agar tidak muncul berulang
    ProgressManager.just_passed_exam = false

func _on_confirm():
    queue_free()

# ========================
# DIALOG NORMAL & LOCK SYSTEM
# ========================
func _update_ui():
    var lvl = ProgressManager.level
    label_text.text = "Apa yang ingin kamu lakukan?"

    btn_practice.visible = true
    btn_exam.visible = true
    btn_confirm.visible = false

    # Logika Kunci Ujian: Hanya terbuka di kelipatan 10
    if lvl > 0 and lvl % 10 == 0:
        btn_exam.disabled = false
        btn_exam.text = "Ujian Level %d" % lvl
    else:
        btn_exam.disabled = true
        btn_exam.text = "Ujian (Terkunci)"

# ========================
# PENGHUBUNG KE SCENE POPUP
# ========================

func _on_practice():
    if minigame_practice_scene:
        var popup = minigame_practice_scene.instantiate()
        get_tree().root.add_child(popup)
        
        # Pastikan scene yang dipanggil punya fungsi start()
        if popup.has_method("start"):
            popup.start("Latihan")
        
        queue_free() # Tutup dialog guru setelah popup terbuka

func _on_exam():
    var lvl = ProgressManager.level
    # Validasi tambahan sebelum instantiate
    if lvl % 10 == 0:
        if minigame_exam_scene:
            var popup = minigame_exam_scene.instantiate()
            get_tree().root.add_child(popup)
            
            if popup.has_method("start"):
                popup.start("Ujian", lvl)
            
            queue_free()
    else:
        label_text.text = "Ujian hanya tersedia di level kelipatan 10."
