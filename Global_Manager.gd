class_name GlobalManagerNode
extends Control

const PAUSE_MENU_SCENE = preload("res://pause_menu.tscn")

var is_new_game := false
var pause_menu_instance = null
var is_game_paused: bool = false
var minigame_open: bool = false
var is_opening := false
var is_loading := false
var mission_ui_open: bool = false
var carried_items := [] 
var parked_vehicles: Dictionary = {}
var vehicles_data: Dictionary = {}
@onready var time_manager = get_node("/root/TimeManager")

var has_backpack: bool = false
var backpack_taken: bool = false
var backpack_scene_path: String = ""  # ← Kosongkan default, jangan hard-code lagi

func _ready():
	time_manager.schedule_point_reached.connect(_on_schedule_point)
	set_process_input(true)
	Engine.time_scale = 1.0
	get_tree().paused = false

func _on_schedule_point(label: String) -> void:
	match label:
		"minigamepopup":
			open_minigame_popup()
			
		"DAILY_ALLOWANCE":
			PlayerData.give_daily_allowance()

func set_vehicle_parked(vehicle_id: String, parking_id: String):
	parked_vehicles[vehicle_id] = parking_id
	print("[GM] Vehicle parked:", vehicle_id, "→", parking_id)


func clear_vehicle_parking(vehicle_id: String):
	if parked_vehicles.has(vehicle_id):
		parked_vehicles.erase(vehicle_id)
		print("[GM] Vehicle reset to default:", vehicle_id)


func get_vehicle_parking(vehicle_id: String) -> String:
	return parked_vehicles.get(vehicle_id, "")

func _handle_daily_allowance():

	if not PlayerData:
		return

	PlayerData.give_daily_allowance()

	var log_text = TimeManager.get_formatted_time() + \
        " - Transfer jajan harian dari Ibu +Rp15000"

	PlayerData.add_transaction(log_text)

	print("[GM] Daily allowance diberikan.")

func save_vehicle(vehicle: Node3D, vehicle_id: String):
	if not is_instance_valid(vehicle):
		print("[GM] save_vehicle: vehicle tidak valid")
		return
	if vehicle_id == "":
		print("[GM] ERROR: vehicle_id kosong")
		return
	
	var scene = get_tree().current_scene
	if scene == null:
		print("[GM] WARNING: current_scene null saat save_vehicle")
		return
	
	# Lebih aman cek property
	var v_scene_path = ""
	if "vehicle_scene_path" in vehicle:
		v_scene_path = vehicle.vehicle_scene_path
	elif vehicle.has_meta("vehicle_scene_path"):
		v_scene_path = vehicle.get_meta("vehicle_scene_path")
	
	vehicles_data[vehicle_id] = {
		"scene_path": scene.scene_file_path,
		"vehicle_scene": v_scene_path,
		"position": vehicle.global_position,
		"rotation": vehicle.global_rotation
	}
	print("[GM] Vehicle saved:", vehicle_id, "di scene", scene.scene_file_path)


func get_vehicles_for_scene(scene_path: String) -> Dictionary:
	var result := {}

	for id in vehicles_data.keys():
		var data = vehicles_data[id]

		if data.get("scene_path", "") == scene_path:
			result[id] = data

	return result


func open_minigame_popup():
	if get_tree().paused:
		return
	var popup_scene = preload("res://minigamepopup.tscn")
	var popup = popup_scene.instantiate()
	get_tree().root.add_child(popup)
	get_tree().paused = true

func save_player_items(player):

	carried_items.clear()

	for item_id in player.equipped_items.keys():

		var data = player.equipped_items[item_id]
		var node = data["node"]
		var item_data : ItemData = data["item_data"]

		if not is_instance_valid(node):
			continue

		var hand := "right"

		if node.get_parent() == player.left_hand_attachment:
			hand = "left"

		carried_items.append({
			"item_id": item_id,
			"item_scene": item_data.equip_scene_path,

			# 🔥 FIX UTAMA
			"item_data": item_data,

			"hand": hand,
			"equip_scale": item_data.equip_scale,
			"current_durability": data.get(
				"current_durability",
				item_data.max_durability
			),

			"node_rotation": node.rotation,
			"node_position_local": node.position
		})

	print("GM: Saved carried items:", carried_items)


func restore_player_items(player):

	if carried_items.is_empty():
		return

	for saved in carried_items:

		var scene = load(saved["item_scene"])

		if scene == null:
			print("GM: Gagal load scene:", saved["item_scene"])
			continue

		var instance = scene.instantiate()

		var equip_point

		if saved["hand"] == "right":
			equip_point = player.right_hand_attachment
		else:
			equip_point = player.left_hand_attachment

		equip_point.add_child(instance)

		instance.transform = Transform3D.IDENTITY
		instance.rotation = saved["node_rotation"]
		instance.position = saved["node_position_local"]
		instance.scale = saved["equip_scale"]

		# ====================================
		# 🔥 FIX FINAL
		# ====================================

		var item_data : ItemData = saved["item_data"]

		if item_data == null:
			print("GM ERROR: item_data NULL:", saved["item_id"])
			instance.queue_free()
			continue

		var item_id = saved["item_id"]

		player.equipped_items[item_id] = {
			"node": instance,
			"item_data": item_data,
			"current_durability": saved["current_durability"]
		}

		instance.set_meta("item_id", item_id)

		player._disable_item_collision(instance)

		print("GM: Restored item:", item_id)
		print("GM: item_data:", item_data.item_name)


func toggle_pause():
	if is_opening or is_loading:
		return
	if minigame_open and not is_game_paused:
		return
	is_game_paused = !is_game_paused
	if is_game_paused:
		Engine.time_scale = 0.0
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if mission_ui_open:
			get_tree().call_group("mission_ui", "on_pause_opened")
		if not is_instance_valid(pause_menu_instance):
			pause_menu_instance = PAUSE_MENU_SCENE.instantiate()
			get_tree().root.add_child(pause_menu_instance)
		pause_menu_instance.show()
	else:
		get_tree().paused = false
		Engine.time_scale = 1.0
		if is_instance_valid(pause_menu_instance):
			pause_menu_instance.hide()
		if mission_ui_open:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().call_group("mission_ui", "on_pause_closed")
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if is_loading:
		return
	if event.is_action_pressed("ui_cancel"):
		if get_tree().root.has_node("SettingMenu"):
			return
		toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("pause"):
		if mission_ui_open:
			return
		else:
			toggle_pause()
			get_viewport().set_input_as_handled()
			return

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(time_manager):
			time_manager._save_time_data()
		get_tree().quit()

func force_resume():
	is_game_paused = false
	minigame_open = false
	get_tree().paused = false
	Engine.time_scale = 1.0
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	print("[GM] Force Resume: Status dibersihkan, kamera aktif.")
