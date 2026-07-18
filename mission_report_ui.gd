extends Control

@onready var text_report: TextEdit = $Body/TextEditReport
@onready var button_submit: Button = $Footer/ButtonSubmit
@onready var label_title: Label = $Header/LabelTitle
@onready var label_npc: Label = $Header/LabelNPC
@onready var label_status: Label = $Header/LabelStatus
@onready var label_objective: RichTextLabel = $Body/LabelObjective
@onready var label_instruction: RichTextLabel = $Body/LabelInstruction
@onready var label_word_count: Label = $Footer/WordCount

var mission_data: Dictionary = {}
var min_word_count: int = 0
var required_keywords: Array = []
var optional_keywords: Array = []   # ← ini yang sebelumnya gak pernah di-set, sekarang aman
var feedback: Dictionary = {}
var _word_regex := RegEx.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("mission_ui")
	set_process_input(true)
	set_process_unhandled_input(true)
	
	_word_regex.compile("\\S+")
	if not text_report.text_changed.is_connected(_on_text_changed):
		text_report.text_changed.connect(_on_text_changed)
	if not button_submit.pressed.is_connected(_on_ButtonSubmit_pressed):
		button_submit.pressed.connect(_on_ButtonSubmit_pressed)
	
	_setup_mouse_filters()   # ← panggil setup khusus

# Fungsi baru untuk mengatur mouse filter secara paksa
func _setup_mouse_filters() -> void:
	# Root harus STOP supaya menangkap semua klik
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Semua container parent harus IGNORE agar klik tembus ke anak
	for node in get_children():
		if node is Control:
			if node.name in ["Header", "Body", "Footer"]:
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				node.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Interactive elements harus STOP
	button_submit.mouse_filter = Control.MOUSE_FILTER_STOP
	button_submit.focus_mode = Control.FOCUS_ALL
	button_submit.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	text_report.mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("MissionReportUI menerima klik")


func open_report(data: Dictionary) -> void:
	var gm := get_node_or_null("/root/GM")
	if gm:
		gm.mission_ui_open = true
	# Pastikan UI di atas semua
	move_to_front()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true
	text_report.grab_focus()
	mission_data = data
	min_word_count = data.get("min_words", 0)
	required_keywords = data.get("required_keywords", [])
	optional_keywords = data.get("optional_keywords", [])
	feedback = data.get("feedback", {})
	text_report.editable = true
	text_report.text = ""
	text_report.grab_focus()
	button_submit.disabled = true
	label_title.text = "Mission Report"
	label_npc.text = "Requested by : Courier"
	label_status.text = "Status : %s" % data.get("status_flow", [])[0]
	label_objective.clear()
	label_objective.append_text("")
	_set_instruction_text()
	_update_word_count()
	_evaluate_report()
	
	_setup_mouse_filters()


func _exit_tree() -> void:
	# 🟢 SAFETY: Jika node dihapus paksa, reset status GM
	var gm := get_node_or_null("/root/GM")
	if gm:
		gm.mission_ui_open = false
	   
func on_pause_opened():
	text_report.editable = false
	text_report.release_focus()

func on_pause_closed():
	text_report.editable = true
	text_report.grab_focus()

# ================= INSTRUCTION =================
func _set_instruction_text() -> void:
	label_instruction.clear()
	var instruction_text := ""
	instruction_text += "Mission Recap:\n"
	instruction_text += mission_data.get("description", "") + "\n\n"
	instruction_text += "Write a clear and complete mission report based on what you have done.\n"
	instruction_text += "Explain the situation, actions taken, and the outcome using your own words.\n"
	instruction_text += "Make sure your report is detailed enough and easy to understand."
	label_instruction.append_text(instruction_text)

# ================= WORD COUNT =================
func _count_words(text: String) -> int:
	if text.is_empty():
		return 0
	return _word_regex.search_all(text).size()

func _update_word_count() -> void:
	var clean := text_report.text.strip_edges()
	label_word_count.text = "Word count: %d / %d" % [_count_words(clean), min_word_count]

# ================= INPUT =================
func _on_text_changed() -> void:
	_update_word_count()
	_evaluate_report()


func _extract_words(text: String) -> Array[String]:
	var words: Array[String] = []
	for m in _word_regex.search_all(text):  # ← diubah: tidak to_lower di sini
		words.append(m.get_string())
	return words

# FULL FUNGSI _check_required_keywords BARU + DEBUG SUPER DETAIL
func _check_required_keywords(words: Array[String]) -> Dictionary:
	# ==============================
	# NORMALISASI KEYWORDS
	# ==============================
	var required_lower: Array[String] = []
	var optional_lower: Array[String] = []
	for r in required_keywords:
		required_lower.append(String(r).to_lower())
	for o in optional_keywords:
		optional_lower.append(String(o).to_lower())
   
	# ==============================
	# COUNTER + MATCH LIST UNTUK DEBUG
	# ==============================
	var keyword_counts: Dictionary = {}      # "keyword" → jumlah kemunculan
	var keyword_matches: Dictionary = {}     # "keyword" → array kata asli yang match
	var required_found: Dictionary = {}      # hanya untuk cek missing
	
	for r in required_lower:
		required_found[r] = false
		keyword_counts[r] = 0
		keyword_matches[r] = []
	
	for o in optional_lower:
		keyword_counts[o] = 0
		keyword_matches[o] = []
   
	# ==============================
	# SCAN SETIAP KATA + RECORD MATCH
	# ==============================
	for w in words:                          # w = kata asli (bukan lower)
		var word := w.to_lower()
		for k in keyword_counts.keys():
			if word.find(k) != -1:
				keyword_counts[k] += 1
				keyword_matches[k].append(w)  # simpan kata asli untuk debug
				if k in required_found:
					required_found[k] = true
   
	# ==============================
	# DEBUG: PRINT SEMUA COUNTS (biar kamu bisa liat kapan saja)
	# ==============================
	print("=== DEBUG KEYWORD COUNTS ===")
	for k in keyword_counts.keys():
		if keyword_counts[k] > 0:
			print("  '%s' → %d kali | kata: %s" % [k, keyword_counts[k], keyword_matches[k]])
	print("============================")
	
	# ==============================
	# CEK REQUIRED YANG HILANG
	# ==============================
	for r in required_found.keys():
		if not required_found[r]:
			print("DEBUG: Missing keyword → '%s'" % r)
			return {
				"ok": false,
				"reason": "missing",
				"keyword": r
			}
   
	# ==============================
	# CEK MULTIPLE + DEBUG DETAIL
	# ==============================
	for k in keyword_counts.keys():
		if keyword_counts[k] > 1:
			print("=== DEBUG MULTIPLE DETECTED ===")
			print("Keyword yang bermasalah: '%s'" % k)
			print("Muncul %d kali di kata-kata berikut:" % keyword_counts[k])
			print("   → %s" % str(keyword_matches[k]))
			print("============================")
			return {
				"ok": false,
				"reason": "multiple",
				"keyword": k,
				"count": keyword_counts[k]
			}
   
	# Semua aman
	return { "ok": true }

# ================= VALIDATION =================
func _evaluate_report() -> void:
	var raw_text := text_report.text.strip_edges()
	var count := _count_words(raw_text)
	label_objective.clear()
	if count < min_word_count:
		label_objective.append_text(feedback.get("too_short", "Report too short."))
		button_submit.disabled = true
		return
	var words: Array[String] = _extract_words(raw_text)
	var keyword_result := _check_required_keywords(words)
	if not keyword_result.ok:
		if keyword_result.reason == "missing":
			label_objective.append_text(feedback.get("missing_keywords"))
		else:
			label_objective.append_text(feedback.get("grammar_error"))
		button_submit.disabled = true
		return
	if not _basic_grammar_check(raw_text):
		label_objective.append_text(feedback.get("grammar_error"))
		button_submit.disabled = true
		return
	label_objective.append_text(feedback.get("accepted"))
	button_submit.disabled = false
	
	# RE-FORCE agar tombol bisa diklik
	button_submit.mouse_filter = Control.MOUSE_FILTER_STOP
	button_submit.grab_focus()


func _basic_grammar_check(text: String) -> bool:
	# Cek minimal ada 2 titik untuk menandakan struktur kalimat
	if text.count(".") < 2:
		return false
	# Cek panjang karakter minimal (asumsi rata-rata 4-5 huruf per kata)
	if text.length() < (min_word_count * 4):
		return false
	return true



func _on_ButtonSubmit_pressed() -> void:
	print("Mission report submitted successfully")
   
	# 1. Reset GM flag dulu
	var gm := get_node_or_null("/root/GM")
	if gm:
		gm.mission_ui_open = false
   
	# 2. Hide UI
	visible = false
   
	# 3. Feedback panel (jika ada)
	var mission_id = mission_data.get("id", "mission_unknown")
	var status := "Approved"
	var feedback_text_msg = feedback.get("accepted", "Mission approved successfully.")
	var feedback_panel := get_tree().get_first_node_in_group("report_feedback")
	if feedback_panel:
		feedback_panel.show_feedback(mission_id, status, feedback_text_msg)
   
	# 4. Tambah XP
	var progress_manager := get_node_or_null("/root/ProgressManager")
	if progress_manager:
		progress_manager.add_xp(15)
		print("XP +15 added to ProgressManager")
   
	# 5. 🔥 PENTING: Beritahu MissionManager bahwa misi selesai
	#    Ini yang bikin MissionLabel hilang
	var mission_manager := get_node_or_null("/root/MissionManager")
	if mission_manager:
		mission_manager._finish_mission()
		print("DEBUG: Called MissionManager._finish_mission() → label akan hilang")
   
	# Resume movement (tetap dipertahankan)
	call_deferred("_force_capture_mouse")
	call_deferred("_resume_player_control")

func _force_capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("DEBUG: Mouse mode restored to CAPTURED")

func _resume_player_control() -> void:
	# Prioritas utama: panggil force_unlock() dari Player
	var player := get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().get_first_node_in_group("Player")
	
	if player and player.has_method("force_unlock"):
		player.force_unlock()
		print("DEBUG: Player.force_unlock() dipanggil → movement harus normal")
		return
	
	# Fallback kalau force_unlock tidak ada
	if player:
		player.set_process_input(true)
		player.set_physics_process(true)
		if "input_locked" in player:
			player.input_locked = false
		print("DEBUG: Fallback reset input_locked")
	else:
		print("DEBUG: Player tidak ditemukan di group 'player'")
