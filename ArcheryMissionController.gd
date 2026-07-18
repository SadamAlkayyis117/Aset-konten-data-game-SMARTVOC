extends Node

signal mission_started
signal mission_finished

var mission_running := false
var current_wave := 0
var max_wave := 5
var vocab_data = []
var current_data = {}
var current_answer = ""
var completed_waves := 0
var current_word := ""
var filled_letters := []
var mission_ended := false
var question_list := []
const ARCHERY_THEME := preload("res://Archery.wav")
var bgm_player: AudioStreamPlayer

func _ready():

	add_to_group("archery_controller")

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "SFX"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.stream = ARCHERY_THEME

	add_child(bgm_player)

	load_vocab()

func start_mission(player):

	mission_ended = false

	if mission_running:
		return

	FunMissionManager.change_state(
		FunMissionManager.FunMissionState.MISSION_RUNNING
	)

	mission_running = true
	current_wave = 1
	completed_waves = 0

	# ▶ Mulai musik Archery
	if !bgm_player.playing:
		bgm_player.play()

	_start_wave()

	# ==========================
	# TUTUP SEMUA GATE
	# ==========================
	for gate in get_tree().get_nodes_in_group("archery_gate"):
		gate.close_gate()

	var timer = get_tree().get_first_node_in_group("archery_timer")
	if timer:
		timer.start_timer()
		timer.result_ready.connect(_on_timer_finished)

	var screen = get_tree().get_first_node_in_group("archery_screen")
	if screen and screen.has_method("show_instruction"):
		screen.show_instruction()

	emit_signal("mission_started")

	print("ARCHERY STARTED")

	FunMissionManager.next_objective()
	
func _start_wave():
	print("WAVE:", current_wave)
	_generate_question()
	filled_letters.clear()
	for i in range(current_answer.length()):
		filled_letters.append("")
	_spawn_letter_blocks()
	_update_ui()
	
func _generate_question():
	var data = get_random_word()
	if not data:
		print("ERROR: vocab kosong")
		return
	current_data = data
	current_answer = data["word"].to_upper()
	current_word = "" # optional kalau ga pakai
	print("WORD:", current_answer)

func _spawn_letter_blocks():
	var spawner = get_tree().get_first_node_in_group("letter_spawner")
	if spawner:
		spawner.start_spawning()
	else:
		print("ERROR: letter_spawner tidak ditemukan")
func on_letter_hit(letter: String):
	for i in range(current_answer.length()):
		if current_answer[i] == letter and filled_letters[i] == "":
			filled_letters[i] = letter
			break
	_update_ui()
	if _is_word_complete():
		_on_word_completed()

func _update_ui():
	var display := ""
	for l in filled_letters:
		if l == "":
			display += "[_]"
		else:
			display += "[" + l + "]"
	var screen = get_tree().get_first_node_in_group("archery_screen")
	if screen and current_data:
		var clues = current_data["clues"]
		screen.update_screen(
			display,
			clues[0],
			clues[1],
			clues[2],
			current_wave
		)

func load_vocab():
	var file = FileAccess.open("res://MateriArchery.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	if json:
		vocab_data = json
		
func get_random_word():
	if vocab_data.is_empty():
		return null
	return vocab_data.pick_random()

func _is_word_complete() -> bool:
	for l in filled_letters:
		if l == "":
			return false
	return true

func _on_word_completed():
	print("WORD COMPLETE:", current_answer)
	completed_waves += 1
	if current_wave >= max_wave:
		_finish_mission()
		return

	current_wave += 1

	# speed naik 1.5x
	_increase_difficulty()

	_start_wave()

func _increase_difficulty():
	var spawner = get_tree().get_first_node_in_group("letter_spawner")
	if spawner:
		spawner.speed *= 1.5

func _on_timer_finished(rank, time):

	if mission_ended:
		return

	mission_ended = true

	# ⏹ Stop musik Archery
	bgm_player.stop()

	var result := FunMissionResultData.new()
	result.mission_type = "ARCHERY"
	result.time = time

	if completed_waves >= 5:
		result.rank = "PERFECT"
		result.score = 100
		result.reward_money = 10000
		result.reward_xp = 5
	elif completed_waves >= 2:
		result.rank = "BEST"
		result.score = 70
		result.reward_money = 5000
	else:
		result.rank = "GOOD"
		result.score = 40
		result.reward_money = 3000

	mission_running = false

	var spawner = get_tree().get_first_node_in_group("letter_spawner")
	if spawner:
		spawner.stop_spawning()

	# ==========================
	# BUKA SEMUA GATE
	# ==========================
	for gate in get_tree().get_nodes_in_group("archery_gate"):
		gate.open_gate()

	var screen = get_tree().get_first_node_in_group("archery_screen")
	if screen and screen.has_method("hide_gameplay_ui"):
		screen.hide_gameplay_ui()

	FunMissionManager.mission_result = result

	emit_signal("mission_finished")

	FunMissionManager.next_objective()


func _finish_mission():

	if mission_ended:
		return

	mission_ended = true

	# ⏹ Stop musik Archery
	bgm_player.stop()

	mission_running = false

	var spawner = get_tree().get_first_node_in_group("letter_spawner")
	if spawner:
		spawner.stop_spawning()

	# ==========================
	# BUKA SEMUA GATE
	# ==========================
	for gate in get_tree().get_nodes_in_group("archery_gate"):
		gate.open_gate()

	var timer = get_tree().get_first_node_in_group("archery_timer")
	if timer:
		timer.stop_timer()

	var result := FunMissionResultData.new()
	result.mission_type = "ARCHERY"
	result.rank = "PERFECT"
	result.score = 100
	result.reward_money = 10000
	result.reward_xp = 5

	FunMissionManager.mission_result = result

	emit_signal("mission_finished")
