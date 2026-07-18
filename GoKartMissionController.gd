extends Node

signal mission_started
signal mission_finished

var mission_running := false
var current_kart = null
var current_player = null
const GOKART_THEME := preload("res://GokartBGM.wav")
var bgm_player: AudioStreamPlayer
var boost_active := false
var boost_timer := 0.0
var mission_time := 0.0

func _ready():

	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = "SFX"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	bgm_player.stream = GOKART_THEME

	add_child(bgm_player)

func _process(delta):
	if mission_running:
		mission_time += delta
		
		if boost_active:
			boost_timer -= delta
			if boost_timer <= 0:
				boost_active = false
				if current_kart:
					current_kart.reset_speed()

func start_mission(kart, player):

	FunMissionManager.change_state(
		FunMissionManager.FunMissionState.MISSION_RUNNING
	)

	current_kart = kart
	current_player = player
	mission_running = true
	mission_time = 0.0

	if !bgm_player.playing:
		bgm_player.play()

	var ui = get_tree().get_first_node_in_group("gokart_ui")
	var timer = get_tree().get_first_node_in_group("mission_timer")

	if ui and timer:
		ui.setup(timer, kart)
		timer.start_timer()
		timer.result_ready.connect(_on_timer_result)

	emit_signal("mission_started")

	print("MISSION STARTED - Time: 0.0")

func _on_timer_result(rank, time):

	bgm_player.stop()

	print("RANK:", rank)
	print("TIME:", time)

	var result := FunMissionResultData.new()

	result.mission_type = "GOKART"
	result.rank = rank
	result.time = time

	match rank:
		"PERFECT":
			result.score = 100
			result.reward_money = 10000
			result.reward_xp = 5

		"BEST":
			result.score = 70
			result.reward_money = 5000

		"GOOD":
			result.score = 40
			result.reward_money = 3000

	FunMissionManager.mission_result = result

	var ui = get_tree().get_first_node_in_group("gokart_ui")

	if ui:
		ui.hide_ui()

	emit_signal("mission_finished")


func finish_mission():

	mission_running = false

	Engine.time_scale = 1.0

	bgm_player.stop()

	print("🏁 RACE FINISHED - Total Time:", mission_time)

	var ui = get_tree().get_first_node_in_group("gokart_ui")

	if ui:
		ui.hide_ui()

	FunMissionManager.next_objective()

	emit_signal("mission_finished")

	if FunMissionManager.mission_result:
		FunMissionManager.finish_gameplay(FunMissionManager.mission_result)

func calculate_score(time: float) -> int:
	# Contoh scoring sederhana
	if time < 60: return 100
	elif time < 90: return 80
	elif time < 120: return 60
	else: return 40

func trigger_type_challenge():
	var ui = get_tree().get_first_node_in_group("type_challenge_ui")
	if ui:
		ui.start_challenge()

func challenge_success():
	Engine.time_scale = 1.0
	boost_active = true
	boost_timer = 3.0
	if current_kart:
		current_kart.apply_boost()
	print("BOOST SUCCESS")

func challenge_failed():
	Engine.time_scale = 1.0
	print("CHALLENGE FAILED")
