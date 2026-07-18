extends Node

signal mission_progress_updated(current: int, total: int)
signal mission_ui_updated(description: String, current: int, total: int)

enum MissionState {
	IDLE,
	DIALOG_ACTIVE,
	MISSION_ACCEPTED,
	MISSION_RUNNING,
	MISSION_OBJECTIVE_COMPLETE,
	REPORT_READY,
	REPORT_DRAFT,
	MISSION_FINISHED
}

var current_state: MissionState = MissionState.IDLE
var current_mission: Dictionary = {}
var delivery_count: int = 0
var waiting_for_pickup: bool = false
var current_item: Node = null
var current_marker: Node = null
var courier_base_position: Vector3 = Vector3(-46.288, 0, 45.866)
var package_spawn_position: Vector3 = Vector3(-48.74, 2.933, 49.168)
var bakery_base_position: Vector3 = Vector3(-115.598, 0.0, -134.977)
var bakery_package_spawn_position: Vector3 = Vector3(-123.182, 2.933, -134.761)
var police_base_position: Vector3 = Vector3(-42.943, 0, -43.65)
var police_poster_spawn_position: Vector3 = Vector3(-38.82, 2.933, -43.65)
var caregiver_base_position: Vector3 = Vector3(92.711, 0, 48.343)
var scriptwriter_base_position: Vector3 = Vector3(183.377, 0, -47.644)
var ui_description: String = ""
var ui_current: int = 0
var ui_total: int = 0
var waiting_for_report: bool = false
var courier_npc: Node = null
var bakery_npc: Node = null
var police_npc: Node = null
var caregiver_npc: Node = null
var scriptwriter_npc: Node = null

# ================= SPAWN POINT =================
var spawn_points: Array[Vector3] = [
	Vector3(46.202, 0, -151.153),
	Vector3(-7.434, 0, -151.153),
	Vector3(-127.028, 0, -179.064),
	Vector3(-183.841, 0, -179.064),
	Vector3(-162.982, 0, -13.253),
	Vector3(-69.708, 0, 25.787),
	Vector3(-94.991, 0, 86.935),
	Vector3(192.481, 0, -70.127),
	Vector3(148.642, 0, 82.462),
	Vector3(171.971, 0, 204.946),
	Vector3(223.157, 0, 204.946),
	Vector3(128.776, 0, 160.179),
	Vector3(112.249, 0, 109.205),
	Vector3(69.421, 0, 137.157),
	Vector3(69.421, 0, 189.979),
	Vector3(-95.1, 0, 166.487),
	Vector3(-32.369, 0, 170.989),
	Vector3(-12.169, 0, 202.192)
]

# ================= RESOURCE =================
var mission_ui_instance: Control = null
var courier_scene: PackedScene = preload("res://npc_kurir_1.tscn")
var bakery_scene: PackedScene = preload("res://npc_nenek_bakery_1.tscn")
var mission_ui_scene: PackedScene = preload("res://missionlabel.tscn")
var mission_report_scene: PackedScene = preload("res://mission_report_ui.tscn")
var mission_report_database_path: String = "res://MissionReport.json"
var mission_database_path: String = "res://Mission.json"
var mission_dialog_scene: PackedScene = preload("res://mission_dialog.tscn")
var delivery_marker_scene: PackedScene = preload("res://markpoint_mission.tscn")

# 🔥 MULTI ITEM PRELOAD
var delivery_item_scenes: Dictionary = {
	"package": preload("res://paket.tscn"),
	"bakery": preload("res://kotak_kue.tscn"),
	"poster": preload("res://poster.tscn"),
	"cat": preload("res://kucing_hitam.tscn"),
	"script_page": preload("res://script.tscn")
}

var randomized_deliveries: Array[Dictionary] = []

# ================= UTIL =================
func get_world() -> Node:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		return player.get_parent()
	return get_tree().root


# ================= MISSION START =================
func start_mission(mission_data: Dictionary) -> void:
	if current_state != MissionState.IDLE:
		return

	# 🔥 CEK NEEDS SEBELUM MULAI MISI
	if NeedsManager.get_writing_health_critical():
		print("[Mission] Gagal mulai misi: Health terlalu rendah!")
		# Optional: tampilkan popup "Anda terlalu sakit untuk bekerja"
		return

	if NeedsManager.get_writing_social_requirement() < 20:
		print("[Mission] Social rendah → dialog mungkin sulit")
		# Bisa tambah branch dialog buruk nanti

	current_mission = mission_data
	delivery_count = 0
	waiting_for_report = false
	_generate_random_deliveries()
	change_state(MissionState.DIALOG_ACTIVE)


func start_mission_by_id(mission_id: String) -> void:
	if current_state != MissionState.IDLE:
		return

	if not FileAccess.file_exists(mission_database_path):
		push_error("Mission database not found")
		return

	var file := FileAccess.open(mission_database_path, FileAccess.READ)
	var json: Dictionary = JSON.parse_string(file.get_as_text()) as Dictionary
	file.close()

	for mission: Dictionary in json.get("missions", []):
		if mission.get("id", "") == mission_id:
			start_mission(mission)
			return

	push_error("Mission ID not found")

func _ensure_mission_ui() -> void:
	if mission_ui_instance and is_instance_valid(mission_ui_instance):
		return

	mission_ui_instance = mission_ui_scene.instantiate()
	mission_ui_instance.name = "MissionUI"

	var world := get_tree().root
	world.add_child(mission_ui_instance)


# ================= RANDOM DELIVERY =================
func _generate_random_deliveries() -> void:
	var points_copy: Array[Vector3] = spawn_points.duplicate()
	points_copy.shuffle()

	randomized_deliveries.clear()

	for i in range(min(10, points_copy.size())):
		randomized_deliveries.append({
			"package_spawn_pos": points_copy[i],
			"delivery_marker_pos": points_copy[i] + Vector3(0, 0, 5)
		})

	current_mission["total_deliveries"] = randomized_deliveries.size()

# ================= STATE =================
func change_state(new_state: MissionState) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		MissionState.DIALOG_ACTIVE:
			_set_player_input_locked(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			_start_dialog()
		MissionState.MISSION_ACCEPTED:
			_set_player_input_locked(false)
			_on_mission_accepted()

		MissionState.MISSION_RUNNING:
			_start_next_delivery()

		MissionState.MISSION_OBJECTIVE_COMPLETE:
			_on_objective_complete()

		MissionState.MISSION_FINISHED:
			_finish_mission()


# ================= DIALOG =================
func _start_dialog() -> void:
	var dialog = mission_dialog_scene.instantiate()
	dialog.dialog_id = current_mission.get("dialog_id", "")
	dialog.dialog_database_path = "res://Autogeneratenpcdialog.json"
	dialog.dialog_finished.connect(_on_dialog_finished)
	get_world().add_child(dialog)


func _on_dialog_finished(accepted: bool) -> void:
	_set_player_input_locked(false)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if accepted:
		change_state(MissionState.MISSION_ACCEPTED)
	else:
		current_mission.clear()
		change_state(MissionState.IDLE)


# ================= ACCEPT =================
func _on_mission_accepted() -> void:
	_ensure_mission_ui()

	ui_description = current_mission.get("objective", {}).get("description", "")
	ui_current = delivery_count
	ui_total = current_mission.get("total_deliveries", 0)

	emit_signal(
		"mission_ui_updated",
		ui_description,
		ui_current,
		ui_total
	)

	change_state(MissionState.MISSION_RUNNING)



# ================= DELIVERY LOOP =================
func _start_next_delivery() -> void:
	if delivery_count >= randomized_deliveries.size():
		change_state(MissionState.MISSION_OBJECTIVE_COMPLETE)
		return

	# 🔥 CEK ENERGY SAAT MULAI DELIVERY BARU
	if NeedsManager.energy < 20:
		print("[Mission] Energy sangat rendah! Delivery lambat.")
		# Optional: tambah delay atau penalty movement di player

	waiting_for_pickup = true
	var mission_id: String = current_mission.get("id", "")
	var delivery: Dictionary = randomized_deliveries[delivery_count]

	var item_key: String = "package"
	if mission_id == "script_salvage":
		item_key = "script_page"
	elif mission_id == "cat_chaos_control":
		item_key = "cat"
	elif current_mission.get("npc_roles", []).has("bakery_owner"):
		item_key = "bakery"
	elif current_mission.get("npc_roles", []).has("police"):
		item_key = "poster"
	else:
		item_key = current_mission.get("delivery_item", "package")

	if not delivery_item_scenes.has(item_key):
		item_key = "package"

	var item_scene: PackedScene = delivery_item_scenes[item_key]
	current_item = item_scene.instantiate()
	current_item.name = "MissionItem_%d" % delivery_count
	var world := get_world()
	world.add_child(current_item)

	if mission_id == "script_salvage" or mission_id == "cat_chaos_control":
		var random_pos = delivery["delivery_marker_pos"]
		current_item.global_position = random_pos
		spawn_delivery_marker()
	else:
		var spawn_position: Vector3 = package_spawn_position
		if current_mission.get("npc_roles", []).has("bakery_owner"):
			spawn_position = bakery_package_spawn_position
		elif current_mission.get("npc_roles", []).has("police"):
			spawn_position = police_poster_spawn_position
		current_item.global_position = spawn_position



func spawn_delivery_marker() -> void:
	if not waiting_for_pickup:
		return
	waiting_for_pickup = false
	var delivery: Dictionary = randomized_deliveries[delivery_count]
	
	if current_marker and is_instance_valid(current_marker):
		current_marker.queue_free()
		current_marker = null
	
	current_marker = delivery_marker_scene.instantiate()
	current_marker.name = "DeliveryMarker_%d" % delivery_count
	var world := get_world()
	world.add_child(current_marker)
	
	var marker_pos = delivery["delivery_marker_pos"]
	current_marker.global_position = marker_pos
	
	current_marker.body_entered.connect(_on_delivery_marker_entered)
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_waypoint"):
		player.set_waypoint(current_marker.global_position)
	
	var mission_id: String = current_mission.get("id", "")
	if mission_id == "script_salvage":
		print("DEBUG SCRIPTWRITER: Markpoint & Arrow spawn langsung di posisi script:", marker_pos)
	elif mission_id == "cat_chaos_control":
		print("DEBUG CAREGIVER: Markpoint & Arrow spawn langsung di posisi kucing:", marker_pos)
	else:
		print("DEBUG NORMAL: Markpoint spawn di drop point:", marker_pos)


func complete_mission_report(courier: Node) -> void:
	if current_state != MissionState.REPORT_READY:
		print("DEBUG REPORT: complete_mission_report dipanggil tapi state bukan REPORT_READY → skip")
		return
	
	waiting_for_report = false
	current_state = MissionState.REPORT_DRAFT
	
	print("DEBUG REPORT: complete_mission_report dipanggil")
	print("DEBUG REPORT: current_mission id:", current_mission.get("id", "TIDAK ADA ID!"))
	print("DEBUG REPORT: current_mission keys:", current_mission.keys())
	
	_set_player_input_locked(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Input.flush_buffered_events()
	
	if courier:
		if courier.has_node("AnimationPlayer"):
			var anim := courier.get_node("AnimationPlayer") as AnimationPlayer
			if anim.has_animation("Idle"):
				anim.play("Idle")
	
	if not FileAccess.file_exists(mission_report_database_path):
		push_error("MissionReport.json not found")
		return
	
	var file := FileAccess.open(mission_report_database_path, FileAccess.READ)
	var json := JSON.parse_string(file.get_as_text()) as Dictionary
	file.close()
	
	print("DEBUG REPORT: MissionReport.json loaded, available report ids:")
	for r in json.get("mission_reports", []):
		print("  -", r.get("id", "NO ID"))
	
	var report_data: Dictionary = {}
	var target_id = current_mission.get("id", "")
	for r in json.get("mission_reports", []):
		if r.get("id", "") == target_id:
			report_data = r
			print("DEBUG REPORT: Report ditemukan untuk id:", target_id)
			break
	
	if report_data.is_empty():
		push_error("Mission report data not found for id: %s" % target_id)
		print("DEBUG REPORT: ERROR - report tidak ditemukan untuk id:", target_id)
		return
	
	var report_ui := mission_report_scene.instantiate()
	report_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(report_ui)
	if report_ui.has_method("open_report"):
		report_ui.open_report(report_data)
	
	if courier:
		courier.queue_free()
	
	print("Mission report UI opened and input unlocked for typing")

func start_courier_respawn_timer() -> void:
	# STEP 1: Hide semua NPC
	_clear_all_writing_npcs()

	# STEP 2: Timer global
	var timer := Timer.new()
	timer.wait_time = float(current_mission.get("cooldown", 300))
	timer.one_shot = true

	timer.timeout.connect(func():
		_respawn_all_writing_npcs()
	)

	add_child(timer)
	timer.start()

	print("[Mission] Global cooldown started (SEMUA NPC hide)")

func _clear_all_writing_npcs() -> void:
	var npcs := get_tree().get_nodes_in_group("mission_npc")

	for npc in npcs:
		if npc and is_instance_valid(npc):
			npc.hide()

			if "available" in npc:
				npc.available = false

	print("[Mission] Semua NPC writing di-hide untuk cooldown")


func _respawn_all_writing_npcs() -> void:
	var npcs := get_tree().get_nodes_in_group("mission_npc")

	for npc in npcs:
		if npc and is_instance_valid(npc):
			npc.show()

			if "available" in npc:
				npc.available = true

	print("[Mission] Semua NPC writing muncul kembali setelah cooldown")


# ================= TRIGGER =================
func _on_delivery_marker_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var player := body as CharacterBody3D
	if not player.is_carrying:
		return

	if player.has_method("start_drop"):
		await player.start_drop()

	if current_item:
		current_item.queue_free()
		current_item = null

	if current_marker:
		current_marker.queue_free()
		current_marker = null

	delivery_count += 1
	_ensure_mission_ui()
	ui_description = current_mission.get("objective", {}).get("description", "")
	ui_current = delivery_count
	ui_total = current_mission.get("total_deliveries", 0)
	emit_signal("mission_ui_updated", ui_description, ui_current, ui_total)

	# 🔥 PENALTY PROGRESS: kalau mood rendah, progress lebih lambat (simulasi)
	var mood_penalty = NeedsManager.get_mood_penalty()
	if mood_penalty > 1.0:
		print("[Mission] Progress lambat karena mood rendah (penalty:", mood_penalty, ")")
		# Optional: tambah delay atau kurangi ui_current sementara

	_start_next_delivery()



func _set_player_input_locked(locked: bool) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_input_locked"):
		player.set_input_locked(locked)


# ================= COMPLETE =================
func _on_objective_complete() -> void:
	waiting_for_report = true
	current_state = MissionState.REPORT_READY

	_ensure_mission_ui()

	ui_description = "Return to courier and submit mission report"
	ui_current = delivery_count
	ui_total = delivery_count

	emit_signal(
		"mission_ui_updated",
		ui_description,
		ui_current,
		ui_total
	)

	print("Deliveries done. Awaiting player report interaction.")



func _finish_mission() -> void:
	# 🔥 FINAL EXP PENALTY
	var mood_penalty = NeedsManager.get_mood_penalty()
	var base_exp = 50  # misal base EXP misi writing
	var final_exp = int(base_exp / mood_penalty)
	ProgressManager.add_xp(final_exp)
	print("[Mission Finish] EXP diberikan:", final_exp, "(mood penalty:", mood_penalty, ")")

	current_mission.clear()
	delivery_count = 0
	randomized_deliveries.clear()
	waiting_for_report = false
	if mission_ui_instance and is_instance_valid(mission_ui_instance):
		mission_ui_instance.queue_free()
		mission_ui_instance = null
	_set_player_input_locked(false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	change_state(MissionState.IDLE)

	start_courier_respawn_timer()
