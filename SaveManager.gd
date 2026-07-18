extends Node

const SAVE_DIR := "user://saves/"
const MAX_SLOTS := 6

var _pending_load_data = null

func _ready():
	_ensure_save_dir()
	# INI KUNCINYA: Deteksi otomatis saat scene baru selesai dimuat
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node):
	if node == get_tree().current_scene:
		print("[SaveManager] Scene loaded:", node.name)

		await get_tree().process_frame
		await get_tree().process_frame

		apply_loaded_data()

func _ensure_save_dir():
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)


# --- UTIL ---
func _get_save_path(slot: int) -> String:
	return SAVE_DIR + "save_%d.json" % slot

func has_save(slot: int) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))

func _read_meta(slot: int) -> Dictionary:
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path): return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_text)
	if typeof(data) == TYPE_DICTIONARY:
		return data.get("meta", {})
	return {}

# --- SAVE GAME ---
func save_game(slot: int) -> void:
	if slot < 1 or slot > MAX_SLOTS: return

	var player = _get_player()
	var current_scene = get_tree().current_scene
	if not current_scene: return
	force_save_all_vehicles()
		
	var scene_path = current_scene.scene_file_path
	if scene_path == "": return 

	var save_data := {
		"meta": {
			"slot": slot,
			"real_datetime": Time.get_datetime_string_from_system()
		},
		"world": {
			"scene_path": scene_path
		},
		"player": {
			"position": _vec3_to_array(player.global_position) if player else [0,0,0],
			"rotation_y": player.rotation.y if player else 0.0
		},
		"time": TimeManager._save_time_data() if TimeManager else {},
		
		"vehicles": GM.vehicles_data,
		
		"inventory": [],
		
		# TAMBAHAN: Tas persist
		"backpack": {
			"equipped": GM.has_backpack,
			"taken": GM.backpack_taken,
			"scene_path": GM.backpack_scene_path if GM.has_backpack else ""
		}
	}
	for inv_item in InventoryManager.inventory_items:
		var item_path := ""
		if inv_item.data:
			item_path = inv_item.data.resource_path
			save_data["inventory"].append({
				"item_path": item_path,
				"quantity": inv_item.quantity,
				"durability": inv_item.current_durability
			})
	var file = FileAccess.open(_get_save_path(slot), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		print("[SaveManager] Game tersimpan di slot ", slot, " dengan tas equipped:", GM.has_backpack)
	
	

# --- LOAD GAME ---
func load_game(slot: int) -> void:
	GM.is_new_game = false
	var path = _get_save_path(slot)
	if not FileAccess.file_exists(path): return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(data) != TYPE_DICTIONARY: return

	_pending_load_data = data

	# 1. WAJIB: Matikan Pause agar scene baru bisa jalan
	get_tree().paused = false
	
	# 2. WAJIB: Pastikan TimeManager Hidup
	if is_instance_valid(TimeManager):
		TimeManager.set_process(true)

	# 3. Bersihkan Menu yang mungkin menutupi atau memblokir input
	for child in get_tree().root.get_children():
		if "SaveLoadMenu" in child.name or "Pause" in child.name:
			child.queue_free()

	if data.world.has("scene_path"):
		get_tree().change_scene_to_file(data.world.scene_path)
		# Kita tidak pakai call_deferred disini, kita andalkan _on_node_added di atas
		# agar timingnya pas saat scene benar-benar masuk.

func apply_loaded_data():
	if _pending_load_data == null:
		return

	var data = _pending_load_data

	await get_tree().process_frame

	# ======================
	# PLAYER
	# ======================
	var player = _get_player()
	if is_instance_valid(player):
		var p_data = data.get("player", {})
		player.global_position = _array_to_vec3(p_data.get("position", [0,0,0]))
		player.rotation.y = p_data.get("rotation_y", 0.0)

		player.sitting = false
		player.input_locked = false

	# ======================
	# TIME
	# ======================
	if is_instance_valid(TimeManager) and data.has("time"):
		TimeManager._load_time_data(data.time)

	# ======================
	# VEHICLES (🔥 SYSTEM BARU)
	# ======================
	if data.has("vehicles"):
		GM.vehicles_data = data["vehicles"]
		print("[SaveManager] Vehicles loaded:", GM.vehicles_data)

	# ======================
	# BACKPACK
	# ======================
	if data.has("backpack"):
		GM.has_backpack = data.backpack.get("equipped", false)
		GM.backpack_taken = data.backpack.get("taken", false)
		GM.backpack_scene_path = data.backpack.get("scene_path", "")
	if is_instance_valid(player):
		player.call_deferred("_respawn_backpack_after_ready")
	
	InventoryManager.clear_inventory()
	if data.has("inventory"):
		for item in data["inventory"]:
			var item_data: ItemData = load(item["item_path"])
			if item_data == null:
				print("[SaveManager] Gagal load ItemData:", item["item_path"])
				continue
			var inv = InventoryItems.new()
			inv.data = item_data
			inv.quantity = item.get("quantity", 1)
			inv.current_durability = item.get("durability", item_data.max_durability)
			InventoryManager.inventory_items.append(inv)
	InventoryManager.emit_signal("inventory_updated")
	GM.force_resume()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_pending_load_data = null
	print("[SaveManager] LOAD COMPLETE")

func force_save_all_vehicles():
	if not is_instance_valid(GM):
		return

	var vehicles = get_tree().get_nodes_in_group("bike")

	for v in vehicles:
		if not is_instance_valid(v):
			continue

		if v.has_meta("vehicle_id"):
			var id = v.get_meta("vehicle_id")
			GM.save_vehicle(v, id)

	print("[SaveManager] All vehicles saved")


func _force_release_ui_blocker():
	for node in get_tree().root.get_children():
		if node is Control or node is CanvasLayer:
			if node.visible:
				node.visible = false

func _reset_mouse_filter():
	for node in get_tree().root.get_children():
		if node is Control:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func get_all_save_slots() -> Array:
	var slots := []
	for i in range(1, MAX_SLOTS + 1):
		var exists = has_save(i)
		slots.append({
			"slot": i,
			"exists": exists,
			"meta": _read_meta(i) if exists else null
		})
	return slots

func _get_player():
	return get_tree().get_first_node_in_group("Player")

func _vec3_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func _array_to_vec3(a) -> Vector3:
	if typeof(a) == TYPE_ARRAY and a.size() >= 3:
		return Vector3(a[0], a[1], a[2])
	return Vector3.ZERO
