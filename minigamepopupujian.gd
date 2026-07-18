extends CanvasLayer

enum PopupState { TUTORIAL, PLAYING, RESULT }
var state : PopupState
var progress := ProgressManager
var current_mode : String = "Ujian"
var current_level : int
var current_vocab : Array = []
var exam_level_target : int = 0


# ================= NODE REFERENCES =================
@onready var tutorial_root = $Popuproot/TutorialRoot
@onready var minigame_container = $Popuproot/MinigameContainer
@onready var result_root = $Popuproot/ResultRoot
@onready var label_title = $"Popuproot/TextureRect/Panelheader/Label Title"
@onready var label_tutorial = $"Popuproot/TutorialRoot/Label Tutorial"
@onready var label_point = $"Popuproot/TutorialRoot/Poin Didapat"
@onready var label_level = $"Popuproot/TutorialRoot/Level Player"
@onready var label_highscore = $"Popuproot/TutorialRoot/Skor tertinggi"
@onready var video_player = $Popuproot/TutorialRoot/VideoStreamPlayer
@onready var btn_start = $Popuproot/TutorialRoot/Button
@onready var btn_retry = $"Popuproot/ResultRoot/Button retry"
@onready var btn_exit = $"Popuproot/ResultRoot/Button surrend"
@onready var btn_finish = $"Popuproot/ResultRoot/Button Finish"
@onready var btn_close = $Popuproot/TextureRect/ButtonClose
@onready var label_result = $Popuproot/ResultRoot/Panel/LabelResult

# ================= DATA =================
var current_minigame_scene : PackedScene
var current_minigame_instance : Node
var current_minigame_id : String

# Contoh database mini game
var minigames = {
	"quiz": {
		"scene": preload("res://Quiz QA Ujian.tscn"),
		"tutorial_video": preload("res://Quiz QA.ogv"),
		"tutorial_text": "Jawab soal soal dengan baik dan benar 
        pastikan terlebih dahulu setiap jawaban yang dipilih 
        itu yakin adalah jawaban yang benar."
	},
	"word_scramble": {
		"scene": preload("res://Word Scramble Ujian.tscn"),
		"tutorial_video": preload("res://Word Scramble.ogv"),
		"tutorial_text": "Susun huruf menjadi kata yang benar, perhatikan 
        setiap hurufnya karena satu huruf salah atau 
        kurang dianggap salah."
	},
	"fill_the_blank": {
		"scene": preload("res://Fill the blank Ujian.tscn"),
		"tutorial_video": preload("res://Fill the blank.ogv"),
		"tutorial_text": "Isi setiap kolom yang hilang 
        untuk melengkapi kalimat yang keluar pastikan 
        kata yang dipilih cocok dengan kalimatnya."
	},
	"speedtyping": {
		"scene": preload("res://Speed Typing Ujian.tscn"),
		"tutorial_video": preload("res://Speedtyping.ogv"),
		"tutorial_text": "Fokus, Perhatikan baik baik 
        soalnya lalu ketik dengan betul jawabannya 
        tanpa salah atau kurang satu huruf pun ."
	},
	"category_sort": {
		"scene": preload("res://Category Sort Ujian.tscn"),
		"tutorial_video": preload("res://Category Sort.ogv"),
		"tutorial_text": "Pilih kosa kata nya dan cocokan 
        dengan kategori dari kosakata tersebut bisa arti, 
        jenis, dan lain lain."
	},
	"word_ladder": {
		"scene": preload("res://Word Ladder Ujian.tscn"),
		"tutorial_video": preload("res://Word Ladder.ogv"),
		"tutorial_text": "Pikirkan kosakata yang berkaitan 
        dengan kosakata awal dan kosakata akhir nya 
        lalu hubungkan sehingga menjadi tangga kosakata."
	}
}

# ================= READY =================
func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	tutorial_root.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	minigame_container.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	result_root.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	video_player.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	btn_start.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	btn_retry.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	btn_exit.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	btn_close.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# 🔥 INI YANG HILANG
	if GM.minigame_open == false:
		GM.minigame_open = true

	if not btn_start.pressed.is_connected(_on_start_pressed):
		btn_start.pressed.connect(_on_start_pressed)

	if not btn_retry.pressed.is_connected(_on_retry_pressed):
		btn_retry.pressed.connect(_on_retry_pressed)

	if not btn_exit.pressed.is_connected(_on_exit_pressed):
		btn_exit.pressed.connect(_on_exit_pressed)

	if not btn_close.pressed.is_connected(_on_exit_pressed):
		btn_close.pressed.connect(_on_exit_pressed)

	if not btn_finish.pressed.is_connected(_on_exit_pressed):
		btn_finish.pressed.connect(_on_exit_pressed)

	# Debug safety
	if current_vocab.is_empty():
		start("Ujian")

func start(mode: String = "Ujian", exam_level: int = 0):
	current_mode = mode

	if mode == "Ujian":
		exam_level_target = exam_level
		current_level = exam_level_target
		current_vocab = _collect_exam_vocab(exam_level_target)
	else:
		exam_level_target = 0
		current_level = progress.level
		current_vocab = progress.get_material_full_by_level(current_level)

	print("[MiniGamePopup] MODE:", current_mode)
	print("[MiniGamePopup] LEVEL:", current_level)
	print("[MiniGamePopup] TOTAL VOCAB:", current_vocab.size())

	get_tree().paused = true
	show_tutorial()

# ================= STATE =================
func show_tutorial():
	state = PopupState.TUTORIAL

	# hide result UI buttons while tutorial shown
	btn_finish.visible = false
	btn_exit.visible = false
	btn_retry.visible = false
	
	tutorial_root.visible = true
	minigame_container.visible = false
	result_root.visible = false
	
	pick_random_minigame()
	update_tutorial_ui()
	
	video_player.stop()
	video_player.stream = minigames[current_minigame_id]["tutorial_video"]
	video_player.play()



func show_minigame():
	state = PopupState.PLAYING

	# hide result UI buttons while playing
	btn_finish.visible = false
	btn_exit.visible = false
	btn_retry.visible = false

	tutorial_root.visible = false
	minigame_container.visible = true
	result_root.visible = false
	
	load_minigame()

func show_result(success: bool, score: int):
	state = PopupState.RESULT
	
	tutorial_root.visible = false
	minigame_container.visible = false
	result_root.visible = true
	
	label_result.text = (
		"BERHASIL!\nSkor: %d" % score
		if success
		else "GAGAL!\nSkor: %d" % score
	)

	# Visibilitas tombol sesuai requirement:
	if success:
		btn_finish.visible = true    # tunjukkan Finish
		btn_exit.visible = false     # sembunyikan Surrend
		btn_retry.visible = false
	else:
		btn_finish.visible = false
		btn_exit.visible = true
		btn_retry.visible = true

# ================= MINI GAME =================
func pick_random_minigame():
	var keys = minigames.keys()
	current_minigame_id = keys.pick_random()
	current_minigame_scene = minigames[current_minigame_id]["scene"]

func update_tutorial_ui():
	label_title.text = current_minigame_id.capitalize()
	label_tutorial.text = minigames[current_minigame_id]["tutorial_text"]
	label_point.text = "Poin didapat: +5 EXP"
	label_level.text = "Levelmu: ???"
	label_highscore.text = "Skor tertinggi: ???"
	
	video_player.stream = minigames[current_minigame_id]["tutorial_video"]
	video_player.play()

func load_minigame():
	clear_minigame()
	current_minigame_instance = current_minigame_scene.instantiate()
	minigame_container.add_child(current_minigame_instance)

	# WAJIB: agar hidup saat pause
	current_minigame_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED

	# CONNECT FINISHED
	if current_minigame_instance.has_signal("finished"):
		current_minigame_instance.finished.connect(_on_minigame_finished)

	# 🔥 INI YANG SELAMA INI HILANG
	if current_minigame_instance.has_method("start_game"):
		current_minigame_instance.start_game({
			"player_level": current_level,
			"vocabulary": current_vocab
		})
	else:
		push_error("Minigame tidak punya start_game()")


func clear_minigame():
	for c in minigame_container.get_children():
		c.queue_free()
	if current_minigame_instance:
		if current_minigame_instance.has_signal("finished"):
			current_minigame_instance.finished.disconnect(_on_minigame_finished)


# ================= SIGNALS =================
func _on_start_pressed():
	print("[MiniGamePopup] START PRESSED")
	show_minigame()

func _on_retry_pressed():
	show_tutorial()

func _on_exit_pressed():
	clear_minigame()

	# 🔥 FIX UTAMA
	GM.minigame_open = false
	GM.is_game_paused = false

	get_tree().paused = false
	Engine.time_scale = 1.0

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	queue_free()

func _on_minigame_finished(success: bool, score: int):
	if success:
		if current_mode == "Latihan":
			progress.add_xp(5)
			progress.complete_material(current_level, score)
		elif current_mode == "Ujian":
			progress.add_xp(10)
			progress.pass_exam(exam_level_target, score)
			_unlock_vocab_for_exam(exam_level_target)
			
			# KONEKSI PENTING: Beritahu manager bahwa kita baru saja lulus ujian
			progress.just_passed_exam = true 

	show_result(success, score)

func _unlock_vocab_for_exam(exam_level: int):
	var start_level := exam_level - 9
	if start_level < 1:
		start_level = 1

	var words := []

	for lvl in range(start_level, exam_level + 1):
		var data = progress.get_material_full_by_level(lvl)
		for w in data:
			var key = w.get("word", w.get("en", ""))
			if key != "":
				words.append(key)

	progress.unlock_multiple(words)

func _collect_exam_vocab(target_level: int) -> Array:
	var vocab := []

	for lvl in range(1, target_level + 1):
		var words = progress.get_material_full_by_level(lvl)
		vocab.append_array(words)

	return vocab
