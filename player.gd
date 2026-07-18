extends CharacterBody3D

enum UpperState {
	NONE,
	TAP,
	HOLD,
	RELOAD,
	CONSUME,
	MELEE
}

enum PlayerMode {
	WALK,
	SIT,
	CLASSROOM_SIT,
	DINING_SIT,
	BIKE,
	KART,
	SLEEP,
	TOILET,
	SHOWER,
	BATH
}

enum CameraMode {
	TP_CENTER,
	TP_RIGHT,
	TP_LEFT,
	FP
}

var movement_locked: bool = false
@export var walk_speed: float = 10.0
@export var run_speed: float = 17.0
@export var rotation_speed: float = 9.0
@export var acceleration: float = 20.0
@export var arrival_distance: float = 3.0
var camera_mode := CameraMode.TP_CENTER
var camera_default_yaw: float = 0.0      # simpan yaw default saat masuk mode
var camera_look_sensitivity: float = 0.005  # sesuaikan kecepatan mouse look
var camera_pitch_limit: float = deg_to_rad(60)
var look_at_target: Node = null
var third_person_position: Vector3
var third_person_rotation: Vector3
var current_speed: float = walk_speed
var is_running: bool = false
@export var jump_velocity: float = 10.0
const GRAVITY = 20.0
var throw_charge_start_time : float = 0.0
var throw_charge_power : float = 0.0
const THROW_MIN_FORCE := 4.0
const THROW_MAX_FORCE := 18.0
const THROW_MAX_CHARGE_TIME := 2.0
var bike_anim_state := ""
var bike_last_dir: Vector3 = Vector3.ZERO
var target_waypoint: Vector3 = Vector3.INF
var analog_input: Vector2 = Vector2.ZERO
var input_locked: bool = false
var input_context := {
	"movement": false,
	"interaction": false,
	"ui": false,
	"combat": false
}
var is_using_telescope := false
var food_carrying := false
var current_bath = null
var current_shower = null
var current_closet = null
var saved_sleep_rotation_y := 0.0
var is_sleeping := false
var sleep_bed = null
var sleep_point = null
var wake_point = null
var is_on_ladder := false
var ladder_ref = null
@export var ladder_speed := 3.0
@export var crouch_speed: float = 4.0
var is_crouching: bool = false
var is_swimming := false
@export var swim_speed := 6.0
@export var swim_fast_speed := 10.0
var vehicle_look_target: Node3D = null
var is_auto_aiming := false
var bike_was_moving := false
var mode: PlayerMode = PlayerMode.WALK
var sitting: bool = false
var carry_style: String = "default"
var sit_chair: Node = null
var sit_point: Node = null
var stand_up_lock: bool = false
var classroom_sit: bool = false
var dining_sit: bool = false
var dining_eating: bool = false
var is_carrying: bool = false
var is_interacting: bool = false
var current_interactable: Node = null
var exiting_bike := false
var saved_visual_rotation: Vector3 = Vector3.ZERO
var has_backpack: bool = false
var backpack_item: Node = null
var inventory_open: bool = false
var is_using_phone_camera := false
var equipped_items := {}
var equipped_source := {} # item_id : "inventory" | "quickslot" | "world"
var fire_pressed_time: float = 0.0
var is_alt_firing: bool = false
var last_fire_time: float = 0.0
var fire_anim_index: Dictionary = {}
var last_fire_pressed_time: float = 0.0
const FIRE_DEBOUNCE_SEC: float = 0.2
var is_playing_fire: bool = false
var upper_state : UpperState = UpperState.NONE
var DEBUG_ANIM := true
var lower_playback : AnimationNodeStateMachinePlayback
var debug_position_timer: float = 0.0
const DEBUG_POSITION_INTERVAL: float = 300.0  # print setiap 1 detik
var nearby_container = null
var vehicle_camera_follow_strength := 4.0
var crosshair_ui : Control
var current_carried_item: Node = null
const RUN_STEP := preload("res://Lari.wav")
var run_step_timer := 0.0
@export var sit_rotation_offset_deg: float = 145.0
@export var shoulder_offset_right := Vector3(-0.7, -3.0, 5.0)
@export var shoulder_offset_left := Vector3(-0.7, -3.0, -5.0)
@export var shoulder_offset_center := Vector3(0, 0, 0)
@onready var run_sfx: AudioStreamPlayer3D = $RunSFX
@onready var phone_cam = $PhoneCamera
@onready var phone_cam_back = $metarig/PhoneCamBack
@onready var phone_cam_front = $metarig/PhoneCamFront
@onready var pivot_center = $SpringarmCenter
@onready var pivot_right = $SpringarmRight
@onready var pivot_left = $SpringarmLeft
@onready var cam_tp_center = $SpringarmCenter/SpringArm3D/Center
@onready var cam_tp_right = $SpringarmRight/SpringArm3D/RightShoulder
@onready var cam_tp_left = $SpringarmLeft/SpringArm3D/LeftShoulder
@onready var cam_fp = $metarig/Skeleton3D/BoneAttachment3D/CameraFirstPerson
@onready var head = $metarig/Skeleton3D/Cube_001
@onready var body = $metarig/Skeleton3D/Cube_041
@onready var hair = $metarig/Skeleton3D/Icosphere_003/Icosphere_003
@onready var clothing = $metarig/Skeleton3D/Cube_049
@onready var back_point: Marker3D = $metarig/BackPoint
@onready var anim_player = $AnimationPlayer
@onready var visual_root = $metarig
@onready var arrow_indicator = get_node_or_null("ArrowIndicator")
@onready var inventory_ui: CanvasLayer = preload("res://inventory_ui.tscn").instantiate()
@onready var interact_popup: CanvasLayer = preload("res://interact_pop_up.tscn").instantiate()
@onready var fullmap_ui: CanvasLayer = get_tree().root.find_child("fullmap", true, false).get_parent() if get_tree().root.find_child("fullmap", true, false) else null
@onready var needs_ui = preload("res://needs_ui.tscn").instantiate()
@onready var smartphone_ui: CanvasLayer = preload("res://Smartphone.tscn").instantiate()
@onready var right_hand_attachment: BoneAttachment3D = $metarig/Skeleton3D/RightHandPoint
@onready var left_hand_attachment: BoneAttachment3D = $metarig/Skeleton3D/LeftHandPoint

var joystick_node: Node = null

# ============================================================
# INPUT HELPER
# ============================================================

func get_active_pivot():
	match camera_mode:
		CameraMode.TP_CENTER:
			return pivot_center
		CameraMode.TP_RIGHT:
			return pivot_right
		CameraMode.TP_LEFT:
			return pivot_left
		_:
			return pivot_center

func set_analog_input(vector: Vector2):
	analog_input = vector

func set_input_locked(locked: bool, ui_mode: bool = false):
	input_locked = locked

	input_context["movement"] = locked
	input_context["combat"] = locked

	var pivot = get_active_pivot()

	if locked:
		if mode != PlayerMode.BIKE:
			velocity = Vector3.ZERO

		if ui_mode:
			if is_instance_valid(pivot):
				pivot.is_looking_around = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			if is_instance_valid(pivot):
				pivot.is_looking_around = true
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		if is_instance_valid(pivot):
			pivot.is_looking_around = true

		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func toggle_mouse_mode():
	var pivot = get_active_pivot()

	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if is_instance_valid(pivot):
			pivot.is_looking_around = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ============================================================
# READY
# ============================================================

func _ready():
	rotation.y = 0.0
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_mode = CameraMode.TP_CENTER
	_apply_camera_mode()   # ✅ LANGSUNG APPLY, JANGAN TOGGLE
	var pivot = get_active_pivot()
	camera_default_yaw = pivot.rotation.y
	cam_tp_center.current = true
	set_input_locked(false)
	if not back_point:
		print("WARNING: BackPoint (Marker3D) tidak ditemukan di metarig! Buat manual di scene.")
	
	stand_up_lock = true
	get_tree().create_timer(1.5).timeout.connect(func(): stand_up_lock = false)
	
	if is_instance_valid(fullmap_ui):
		print("DEBUG READY: fullmap_ui ditemukan! Nama:", fullmap_ui.name)
	else:
		print("DEBUG READY: fullmap_ui NULL! Cek nama node 'fullmap' di scene tree")
		for child in get_tree().root.get_children():
			if child is CanvasLayer:
				print(" - CanvasLayer di root:", child.name, " - Path:", child.get_path())
	
	crosshair_ui = preload("res://Crosshair.tscn").instantiate()
	call_deferred("_add_crosshair")
	
	var closet_ui = preload("res://closet_ui.tscn").instantiate()
	closet_ui.name = "ClosetUI"
	get_tree().root.call_deferred("add_child", closet_ui)
	
	var sleep_ui = preload("res://sleep_ui.tscn").instantiate()
	sleep_ui.name = "SleepUI"
	get_tree().root.call_deferred("add_child", sleep_ui)
	
	if is_instance_valid(arrow_indicator):
		arrow_indicator.visible = false
	
	var touchscreen_ui = get_tree().get_root().get_node_or_null("TouchScreenUI")
	if is_instance_valid(touchscreen_ui):
		joystick_node = touchscreen_ui.get_node_or_null("Joystick")
		if is_instance_valid(joystick_node) and joystick_node.has_signal("analog_output"):
			joystick_node.analog_output.connect(set_analog_input)
	
	call_deferred("_add_ui_to_root")
	call_deferred("_add_interact_popup_to_root")
	call_deferred("_add_needs_ui")
	call_deferred("_add_smartphone_ui")
	
	# Tas respawn tetap
	if GM.has_backpack and GM.backpack_scene_path != "":
		call_deferred("_respawn_backpack_after_ready")
	WeaponManager.weapon_equipped.connect(_on_weapon_equipped)
	WeaponManager.weapon_unequipped.connect(_on_weapon_unequipped)


func _add_crosshair():
	get_tree().root.add_child(crosshair_ui)
	crosshair_ui.visible = false

func _add_interact_popup_to_root():
	if interact_popup.get_parent() == null:  # lebih aman dari not get_parent()
		get_tree().root.add_child(interact_popup)
		print("DEBUG: interact_popup berhasil di-add ke root tree")
	else:
		print("DEBUG: interact_popup sudah punya parent, skip add_child")
	
	interact_popup.visible = false
	
	# Connect signal (aman di deferred)
	interact_popup.use_pressed.connect(_on_popup_use)
	interact_popup.store_pressed.connect(_on_popup_store)
	interact_popup.canceled.connect(_on_popup_cancel)

func _add_ui_to_root():
	if not inventory_ui.get_parent():
		get_tree().root.add_child(inventory_ui)
		inventory_ui.name = "InventoryUI"
	
	# Connect signal ke player
	inventory_ui.use_item_requested.connect(_on_inventory_use)
	inventory_ui.drop_item_requested.connect(_on_inventory_drop)
	inventory_ui.input_quickuse_requested.connect(_on_input_quickuse)
	
	inventory_ui.visible = false
	var quick_use_bar = get_tree().root.get_node_or_null("QuickUseBar")
	if not quick_use_bar:
		quick_use_bar = preload("res://quick_use_bar.tscn").instantiate()
		get_tree().root.add_child(quick_use_bar)
		quick_use_bar.name = "QuickUseBar"
		quick_use_bar.visible = false
	
	print("DEBUG: UI Inventory dan QuickUseBar siap, QuickSlotRadial sekarang di InventoryUI")

func _add_needs_ui():
	if needs_ui.get_parent() == null:
		get_tree().root.add_child(needs_ui)
		needs_ui.visible = false

func _add_smartphone_ui():
	if smartphone_ui.get_parent() == null:
		get_tree().root.add_child(smartphone_ui)
		smartphone_ui.name = "SmartphoneUI"
		smartphone_ui.setup(self)
	
	smartphone_ui.visible = false

func _on_weapon_equipped(weapon):
	if crosshair_ui:
		crosshair_ui.visible = true

func _on_weapon_unequipped():
	if crosshair_ui:
		crosshair_ui.visible = false


# ============================================================
# INPUT
# ============================================================

func _input(event):
	if get_tree().paused:
		return
	
	if _is_mission_ui_open():
		return

	if event.is_action_pressed("toggle_needs"):
		if is_instance_valid(needs_ui):
			needs_ui.visible = true
			  
	if event.is_action_released("toggle_needs"):
		if is_instance_valid(needs_ui):
			needs_ui.visible = false
  
	if interact_popup.visible:
		return
	else:
		if is_input_blocked("interaction"):
			if event.is_action_pressed("Inventory"):
				if inventory_open:
					_close_inventory()
				return
			return
  
	if mode == PlayerMode.BIKE:
		return
  
	if event.is_action_pressed("Interaksi"):
		debug_input_state("PRESS E")
		if is_input_blocked("interaction"):
			print("BLOCKED INTERACTION")
			return
		handle_interaction()
  
	if event.is_action_pressed("ui_cancel"):
		toggle_mouse_mode()
  
	if event.is_action_pressed("Fullmap"):
		if is_instance_valid(fullmap_ui):
			var is_open = fullmap_ui.full_map_canvas.visible
			if fullmap_ui.has_method("toggle_full_map"):
				fullmap_ui.toggle_full_map(!is_open)
	
	if event.is_action_pressed("Inventory"):
		if is_input_blocked("ui"):
			return
		if not has_backpack or not is_instance_valid(backpack_item):
			print("DEBUG: Tidak bisa buka inventory - belum pakai tas")
			return
		if inventory_open:
			_close_inventory()
		else:
			_open_inventory()
		return
  
	if event.is_action_pressed("open_smartphone"):
		if is_instance_valid(smartphone_ui):
			smartphone_ui.toggle_phone()
		return
  
	if event.is_action_pressed("QuickUse1"):
		_use_quickuse_slot(0)
	if event.is_action_pressed("QuickUse2"):
		_use_quickuse_slot(1)
	if event.is_action_pressed("QuickUse3"):
		_use_quickuse_slot(2)
	if event.is_action_pressed("QuickUse4"):
		_use_quickuse_slot(3)
	if event.is_action_pressed("QuickUse5"):
		_use_quickuse_slot(4)
  
	if event.is_action_pressed("Drop"):
		if _drop_equipped_item():
			return
	  
		if has_backpack and is_instance_valid(backpack_item):
			if inventory_open:
				_close_inventory()
			backpack_item.unequip()
			has_backpack = false
			backpack_item = null
			GM.has_backpack = false
			GM.backpack_scene_path = ""
			InventoryManager.max_slots = 0
			print("DEBUG: Tas di-drop → max_slots reset ke 0")
	
	if event.is_action_pressed("SwitchCamera"):
		_toggle_camera_mode()
  
	if event.is_action_pressed("Sheathe"):
		for item_id in equipped_items.keys():
			var source = equipped_source.get(item_id, "world")
			if source == "world":
				print("DEBUG: Tidak bisa sheathe item dari world")
				return
		_handle_sheathe()
  
	if event.is_action_pressed("Fire"):
		print("DEBUG: FIRE DETECTED")
		_on_fire_pressed()
	if event.is_action_released("Fire"):
		_on_fire_released()
	
	if Input.is_action_just_pressed("AltFire"):
		_on_alt_fire_pressed()
	
	if Input.is_action_just_released("AltFire"):
		_on_alt_fire_released()
  
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and !is_using_telescope:
		if event is InputEventMouseMotion:
			if camera_mode == CameraMode.FP:
				_handle_fp_look(event)
			else:
				var pivot = get_active_pivot()   # 🔥 FIX DI SINI
				if is_instance_valid(pivot):
					pivot.handle_mouse_input(event)

func _handle_fp_look(event: InputEventMouseMotion):
	visual_root.rotation.y -= event.relative.x * camera_look_sensitivity
	var rot = cam_fp.rotation
	rot.x -= event.relative.y * camera_look_sensitivity
	rot.x = clamp(rot.x, -camera_pitch_limit, camera_pitch_limit)
	cam_fp.rotation.x = rot.x

func debug_input_state(tag: String):
	print("[INPUT DEBUG]", tag,
		" | movement:", input_context["movement"],
		" interaction:", input_context["interaction"],
		" ui:", input_context["ui"],
		" locked:", input_locked,
		" mode:", mode
	)

func _update_crouch_state():

	# mode tertentu tidak boleh crouch
	if mode != PlayerMode.WALK or is_swimming or sitting or classroom_sit:
		is_crouching = false
		return

	is_crouching = Input.is_action_pressed("Crouch")

func _get_item_anim_player(item_node: Node, item_data: ItemData):

	if not item_data.use_item_animation:
		return null

	if item_data.item_anim_player_path == NodePath():
		return null

	return item_node.get_node_or_null(item_data.item_anim_player_path)

func is_input_blocked(type: String) -> bool:
	return input_context.get(type, false)

func _on_alt_fire_pressed():
	if movement_locked or is_interacting or mode != PlayerMode.WALK:
		return

	var active_item = _get_active_hand_item()
	if not active_item:
		return

	var item_id = active_item.get_meta("item_id")
	var data = equipped_items.get(item_id)
	if not data:
		return

	var item_data: ItemData = data["item_data"]

	if not item_data.enable_alt_fire:
		return

	is_alt_firing = true
	is_playing_fire = true

	var item_anim = _get_item_anim_player(active_item, item_data)

	match item_data.alt_fire_type:

		"Aim", "Block":
			# 🔥 PLAYER
			if item_data.alt_fire_anim != "":
				anim_player.play(item_data.alt_fire_anim)

			# 🔥 ITEM (PINDAH KE SINI)
			if item_anim and item_data.alt_item_anim != "":
				item_anim.play(item_data.alt_item_anim)

		"Throw":
			throw_charge_start_time = Time.get_ticks_msec() / 1000.0

			# 🔥 PLAYER
			if item_data.alt_fire_anim != "":
				anim_player.play(item_data.alt_fire_anim)

			# 🔥 ITEM
			if item_anim and item_data.alt_item_anim != "":
				item_anim.play(item_data.alt_item_anim)


func _on_alt_fire_released():

	if not is_alt_firing:
		return

	var active_item = _get_active_hand_item()
	if not active_item:
		is_alt_firing = false
		is_playing_fire = false
		return

	var item_id = active_item.get_meta("item_id")
	var data = equipped_items.get(item_id)
	if not data:
		is_alt_firing = false
		is_playing_fire = false
		return

	var item_data: ItemData = data["item_data"]

	is_alt_firing = false

	var item_anim = _get_item_anim_player(active_item, item_data)

	match item_data.alt_fire_type:

		"Aim", "Block":
			# 🔥 PLAYER
			if item_data.alt_fire_release_anim != "":
				anim_player.play(item_data.alt_fire_release_anim)

			# 🔥 ITEM
			if item_anim and item_data.alt_item_release_anim != "":
				item_anim.play(item_data.alt_item_release_anim)

		"Throw":
			var now = Time.get_ticks_msec() / 1000.0
			var held_time = now - throw_charge_start_time
			var charge_ratio = clamp(held_time / THROW_MAX_CHARGE_TIME, 0.0, 1.0)
			throw_charge_power = lerp(THROW_MIN_FORCE, THROW_MAX_FORCE, charge_ratio)

			# 🔥 PLAYER
			if item_data.alt_fire_release_anim != "":
				anim_player.play(item_data.alt_fire_release_anim)

			# 🔥 ITEM
			if item_anim and item_data.alt_item_release_anim != "":
				item_anim.play(item_data.alt_item_release_anim)

			await anim_player.animation_finished

			_throw_equipped_item(item_id, throw_charge_power)

	is_playing_fire = false


func _throw_equipped_item(item_id, power: float = 0.0):
	print("DEBUG: Mulai throw item_id:", item_id, "power:", power)

	if not equipped_items.has(item_id):
		print("DEBUG: Item tidak ditemukan")
		return
	
	var data = equipped_items[item_id]
	var item_node = data["node"]
	var item_data = data["item_data"]

	if not is_instance_valid(item_node):
		print("DEBUG: Item node invalid")
		return

	# 🔥 HAPUS DARI TANGAN
	if item_node.get_parent():
		item_node.get_parent().remove_child(item_node)
	item_node.queue_free()

	# 🔥 LOAD WORLD SCENE
	if item_data.world_scene_path == "":
		print("ERROR: world_scene_path kosong")
		return

	var world_scene = load(item_data.world_scene_path)
	if not world_scene:
		print("ERROR: gagal load world scene")
		return

	var world_item = world_scene.instantiate()
	var world = get_tree().current_scene
	world.add_child(world_item)

	# 🔥 POSISI
	var cam = get_viewport().get_camera_3d()
	var forward = -cam.global_transform.basis.z.normalized()
	var spawn_offset = forward * 1.2 + Vector3.UP * 1.0

	var pivot = get_active_pivot()
	world_item.global_position = pivot.global_position + spawn_offset
	world_item.scale = item_data.world_scale

	print("DEBUG: Spawn world item:", world_item)

	# 🔥 HITUNG IMPULSE
	var final_power = power if power > 0 else 12.0
	var impulse = (forward * final_power * 4.0) + (Vector3.UP * final_power * 2.0)

	# 🔥 KIRIM KE ITEM (FIX UTAMA)
	if world_item is ItemPickup:
		world_item.throw_impulse = impulse
		world_item.should_throw = true
		print("DEBUG: Throw data dikirim ke item")

	else:
		print("ERROR: world_item bukan ItemPickup")

	# 🔥 ENABLE INTERACTION
	if world_item.has_method("enable_interaction"):
		world_item.enable_interaction()

	# 🔥 CLEANUP
	if item_data.item_type == ItemData.ItemType.WEAPON:
		WeaponManager.unequip_weapon()

	equipped_items.erase(item_id)
	equipped_source.erase(item_id)

	print("DEBUG: Throw selesai (data-driven)")

func _toggle_camera_mode():

	camera_mode += 1
	if camera_mode > CameraMode.FP:
		camera_mode = CameraMode.TP_CENTER

	_apply_camera_mode()

func _apply_camera_mode():

	cam_tp_center.current = false
	cam_tp_right.current = false
	cam_tp_left.current = false
	cam_fp.current = false

	pivot_center.set_process(false)
	pivot_right.set_process(false)
	pivot_left.set_process(false)

	match camera_mode:

		CameraMode.TP_CENTER:
			cam_tp_center.current = true
			pivot_center.set_process(true)
			_show_full_body()

		CameraMode.TP_RIGHT:
			cam_tp_right.current = true
			pivot_right.set_process(true)
			_show_full_body()

		CameraMode.TP_LEFT:
			cam_tp_left.current = true
			pivot_left.set_process(true)
			_show_full_body()

		CameraMode.FP:
			cam_fp.current = true
			_hide_head_only()
			
func _get_aim_point() -> Vector3:
	var cam = get_viewport().get_camera_3d()
	var from = cam.global_transform.origin
	var to = from + (-cam.global_transform.basis.z * 1000.0)

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false

	var result = space.intersect_ray(query)

	if result:
		return result.position
	else:
		return to

func _auto_face_target(target_pos: Vector3):
	if camera_mode == CameraMode.FP:
		var cam = cam_fp.global_transform
		var forward = -cam.basis.z.normalized()
		var target_rot = atan2(forward.x, forward.z)
		visual_root.rotation.y = target_rot
		return

	var dir = (target_pos - global_position)
	dir.y = 0
	dir = dir.normalized()
	var target_rot = atan2(dir.x, dir.z)
	visual_root.rotation.y = target_rot


func _show_full_body():
	head.visible = true
	body.visible = true
	hair.visible = true
	clothing.visible = true

func _hide_head_only():
	head.visible = false
	hair.visible = false
	body.visible = true
	clothing.visible = true


func _get_active_hand_item():

	# CEK TANGAN KANAN
	for child in right_hand_attachment.get_children():
		if child.has_meta("item_id"):
			return child

	# CEK TANGAN KIRI
	for child in left_hand_attachment.get_children():
		if child.has_meta("item_id"):
			return child

	return null


func _on_fire_pressed():
	var now = Time.get_ticks_msec() / 1000.0
	if now - last_fire_pressed_time < FIRE_DEBOUNCE_SEC:
		return
	last_fire_pressed_time = now
	if current_carried_item is PreparedFood:
		if mode != PlayerMode.DINING_SIT:
			return
		dining_eating = true
		anim_player.play("Eat")
		current_carried_item.eat(self)
		return
	if movement_locked or is_interacting or mode != PlayerMode.WALK:
		return
  
	var active_item = _get_active_hand_item()
	if not active_item:
		return
  
	var item_id = active_item.get_meta("item_id")
	var data = equipped_items.get(item_id)
	if not data:
		return
  
	var item_data = data.get("item_data")
	if item_data == null:
		print("ERROR FIRE: item_data NULL")
		return
  
	if not item_data.enable_fire:
		print("DEBUG FIRE: Item ini tidak support Fire")
		return
  
	fire_pressed_time = Time.get_ticks_msec() / 1000.0
	if item_data.item_type == ItemData.ItemType.WEAPON:
		if is_alt_firing:
			print("DEBUG: Accurate shot")
		else:
			print("DEBUG: Hip fire")
	
	var aim_point = _get_aim_point()
  
	_play_fire_animation(item_id, item_data, true)


# Fire Released
func _on_fire_released():
	if movement_locked or is_interacting or mode != PlayerMode.WALK:
		return
  
	var active_item = _get_active_hand_item()
	if not active_item:
		return
  
	var item_id = active_item.get_meta("item_id")
	var data = equipped_items.get(item_id)
	if not data:
		return
  
	var item_data = data.get("item_data")
	if item_data == null:
		print("ERROR FIRE: item_data NULL")
		return
  
	if not item_data.enable_fire:
		return
  
	_play_fire_animation(item_id, item_data, false)


func _spawn_projectile(item_data: ItemData, item_node: Node):

	if not item_data.is_projectile_weapon:
		return

	# 🔥 CEK AMMO
	if not InventoryManager.has_item(item_data.ammo_item_id):
		print("DEBUG: AMMO HABIS")
		return

	InventoryManager.remove_item(item_data.ammo_item_id, item_data.ammo_per_shot)

	var scene = load(item_data.projectile_scene)
	if not scene:
		print("ERROR: projectile_scene gagal load")
		return

	var projectile = scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	# =========================
	# 🎯 AIM SYSTEM
	# =========================
	var aim_point = _get_aim_point()

	# =========================
	# 🔫 SPAWN POSITION
	# =========================
	var muzzle = item_node.get_node_or_null("Muzzle")
	var spawn_pos: Vector3

	if muzzle:
		spawn_pos = muzzle.global_transform.origin
	else:
		spawn_pos = get_active_pivot().global_position

	projectile.global_position = spawn_pos

	# =========================
	# 🚀 ARAH KE TARGET (INI KUNCI)
	# =========================
	var direction = (aim_point - spawn_pos).normalized()

	if projectile.has_method("launch"):
		projectile.launch(direction)

	print("DEBUG: PROJECTILE → AIM LOCKED")

func _update_run_sfx(delta: float) -> void:

	# Harus di tanah
	if !is_on_floor():
		run_step_timer = 0.0
		return

	# Harus sedang sprint
	if !is_running:
		run_step_timer = 0.0
		return

	# Jangan bunyi kalau diam
	if velocity.length() < 0.5:
		run_step_timer = 0.0
		return

	run_step_timer += delta

	if run_step_timer >= 0.23:
		run_step_timer = 0.0

		if !run_sfx.playing:
			run_sfx.stream = RUN_STEP
			run_sfx.pitch_scale = randf_range(0.97, 1.03)
			run_sfx.play()

func _play_fire_animation(item_id: String, item_data: ItemData, is_pressed: bool):

	if item_data == null:
		print("ERROR: item_data NULL di _play_fire_animation")
		return

	if StoreTransactionManager.is_item_unpaid(item_data):
		print("DEBUG: Fire dibatalkan - item belum dibayar:", item_id)
		return

	var item_node = equipped_items[item_id]["node"]
	var item_anim = _get_item_anim_player(item_node, item_data)

	# =========================
	# TAP MODE
	# =========================
	if item_data.fire_type == "Tap":

		if not is_pressed:
			return

		var now = Time.get_ticks_msec() / 1000.0

		if now - last_fire_time < 0.15:
			return

		if now - last_fire_time > 3.0:
			fire_anim_index[item_id] = 0

		var index = fire_anim_index.get(item_id, 0)

		if item_data.fire_animations.is_empty():
			return

		var anim_name = item_data.fire_animations[index % item_data.fire_animations.size()]

		anim_player.play(anim_name)

		if item_anim and item_data.fire_item_animations.size() > 0:
			item_anim.play(item_data.fire_item_animations[0])

		fire_anim_index[item_id] = index + 1
		last_fire_time = now
		is_playing_fire = true

		await anim_player.animation_finished

		is_playing_fire = false

		_apply_item_usage(item_id)
		_spawn_projectile(item_data, item_node)

	# =========================
	# HOLD MODE (FIX UTAMA)
	# =========================
	elif item_data.fire_type == "Hold":

		if item_data.fire_animations.size() < 2:
			print("ERROR: Hold but anim kurang")
			return

		var pull_anim = item_data.fire_animations[0]
		var hold_anim = item_data.fire_animations[1]

		# =====================
		# PRESS
		# =====================
		if is_pressed:

			if upper_state == UpperState.HOLD:
				return

			print("DEBUG: START PULL")

			upper_state = UpperState.HOLD
			is_playing_fire = true

			# 🔥 PLAY PULL
			anim_player.play(pull_anim)

			if item_anim and item_data.fire_item_animations.size() > 0:
				item_anim.play(item_data.fire_item_animations[0])

			# 🔥 TANPA BLOCK → LANGSUNG LANJUT LOOP
			await anim_player.animation_finished

			if upper_state != UpperState.HOLD:
				return

			print("DEBUG: ENTER HOLD LOOP")

			anim_player.play(hold_anim)

			if item_anim and item_data.fire_item_animations.size() > 1:
				item_anim.play(item_data.fire_item_animations[1])

		# =====================
		# RELEASE
		# =====================
		else:

			if upper_state != UpperState.HOLD:
				return

			print("DEBUG: RELEASE")

			upper_state = UpperState.NONE
			is_playing_fire = false

			# 🔥 PLAY RELEASE
			if item_data.fire_release_anim != "":
				anim_player.play(item_data.fire_release_anim)

			if item_anim and item_data.fire_item_release_anim != "":
				item_anim.play(item_data.fire_item_release_anim)

			_apply_item_usage(item_id)

			if item_data.fire_spawn_timing == "OnRelease":
				_spawn_projectile(item_data, item_node)
			

func _apply_item_usage(item_id: String):

	if not equipped_items.has(item_id):
		return

	var equipped = equipped_items[item_id]
	var item_data = equipped["item_data"]

	# =========================
	# 🔥 DURABILITY
	# =========================
	equipped["current_durability"] -= 1

	print(
		"DEBUG: Durability item di tangan sekarang:",
		equipped["current_durability"]
	)

	# =========================
	# 🔥 EFFECT
	# =========================
	NeedsManager.apply_item_effect(item_data)

	if NeedsManager.health <= 20:
		print("DEBUG: Health critical setelah consume!")

	# =========================
	# 🔥 HABIS
	# =========================
	if equipped["current_durability"] <= 0:

		# 🔥 FIX UTAMA
		var source = equipped_source.get(item_id, "")

		print(
			"DEBUG: Durability habis untuk",
			item_id,
			"source:",
			source
		)

		# =====================
		# INVENTORY REFILL
		# =====================
		if source == "inventory":

			if InventoryManager.has_item(item_id):

				InventoryManager.remove_item(item_id, 1)

				equipped["current_durability"] = item_data.max_durability

				print(
					"DEBUG: Auto refill dari stack inventory untuk",
					item_id
				)

				return

		# =====================
		# QUICKUSE
		# =====================
		elif source == "quickuse":

			QuickUseManager.use_item(item_id)

			if not QuickUseManager.has_item(item_id):
				print("DEBUG: Habis dari quickuse")

		# =====================
		# HAPUS TOTAL
		# =====================
		var node = equipped["node"]

		if is_instance_valid(node):
			node.queue_free()

		equipped_items.erase(item_id)
		equipped_source.erase(item_id)

		print("DEBUG: Item habis total, hapus dari tangan")


func _on_fire_anim_finished(anim_name):
	if not is_playing_fire:
		return
	is_playing_fire = false
	
	# JANGAN RESET KE 0.0 kalau masih pegang item
	if equipped_items.size() > 0:
		var active_item = _get_item_in_right_hand()
		if active_item:
			var item_data = equipped_items[active_item.get_meta("item_id")]["item_data"]


func _use_quickuse_slot(index: int):
	var item_data = QuickUseManager.get_slot_item(index)
	if item_data:
		print("DEBUG: Pakai item dari QuickUse slot", index + 1, ":", item_data.item_name)
		_use_item(null, item_data, "quickuse")  # source "quickuse" untuk bedakan
	else:
		print("DEBUG: Slot QuickUse", index + 1, "kosong")

# Helper open/close inventory (update path kalau beda)
func _open_inventory():
	if not has_backpack or not is_instance_valid(backpack_item):
		print("DEBUG: Tidak bisa buka inventory - belum pakai tas!")
		return
   
	# Update max_slots dari tas yang sedang dipakai (aman kalau tas di-drop)
	if is_instance_valid(backpack_item) and backpack_item.has_method("max_slots"):
		InventoryManager.max_slots = backpack_item.max_slots
		print("DEBUG: Max slots inventory disesuaikan dengan tas:", InventoryManager.max_slots)
   
	if not is_instance_valid(inventory_ui):
		print("ERROR: inventory_ui null!")
		return
   
	inventory_open = true
	set_input_locked(true)
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var pivot = get_active_pivot()
	if is_instance_valid(pivot):
		pivot.is_looking_around = true
   
	inventory_ui.visible = true
	inventory_ui.populate_inventory(InventoryManager.get_items())
   
	var quick_use_bar = get_tree().root.get_node_or_null("QuickUseBar")
	if quick_use_bar:
		quick_use_bar.visible = true
		print("DEBUG: QuickUseBar ditampilkan saat inventory buka")
   
	print("DEBUG: Inventory OPEN")

func _close_inventory():
	if not is_instance_valid(inventory_ui):
		print("ERROR: inventory_ui null saat close!")
		return
	
	inventory_open = false
	set_input_locked(false)
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var pivot = get_active_pivot()
	if is_instance_valid(pivot):
		pivot.is_looking_around = true
	
	inventory_ui.visible = false
	
	var quick_use_bar = get_tree().root.get_node_or_null("QuickUseBar")
	if quick_use_bar:
		quick_use_bar.visible = false
	
	print("DEBUG: Inventory CLOSED")

func _drop_equipped_item() -> bool:
	if equipped_items.is_empty():
		anim_player.play("Idle")
		print("DEBUG DROP/SHEATHE: Kembali ke default Idle")
		return false

	print("DEBUG DROP: Mulai drop, equipped count:", equipped_items.size())

	var dropped_any = false
	var item_ids_to_remove = []

	for item_id in equipped_items.keys():

		var data = equipped_items[item_id]
		var item_node: Node3D = data["node"]
		var item_data: ItemData = data["item_data"]

		if not is_instance_valid(item_node):
			print("DEBUG DROP: Item invalid:", item_id)
			item_ids_to_remove.append(item_id)
			continue

		print("DEBUG DROP: Drop item:", item_id)

		var world = get_tree().current_scene
		if item_data.world_scene_path != "":
			var world_scene = load(item_data.world_scene_path)
			if world_scene:
				var world_item = world_scene.instantiate()
				world.add_child(world_item)
				var drop_offset = (-global_transform.basis.z * 1.5) + Vector3(randf_range(-0.5,0.5),0,randf_range(-0.5,0.5))
				world_item.global_position = global_transform.origin + drop_offset
				world_item.scale = item_data.world_scale
				if world_item.has_method("enable_interaction"):
					world_item.enable_interaction()
		item_node.queue_free()

		# 🔥 kalau weapon → unequip weapon manager
		if item_data.item_type == ItemData.ItemType.WEAPON:
			WeaponManager.unequip_weapon()

		item_ids_to_remove.append(item_id)
		dropped_any = true

	for item_id in item_ids_to_remove:
		equipped_items.erase(item_id)
		equipped_source.erase(item_id)

	if equipped_items.is_empty():
		anim_player.play("Idle")
		print("DEBUG DROP/SHEATHE: Kembali ke default Idle")

	return dropped_any

func _exit_tree():
	if StoreTransactionManager.unpaid_inventory_items.size() > 0 or StoreTransactionManager.unpaid_hand_items.size() > 0:
		StoreTransactionManager.clear_all_unpaid(self)
		print("Keluar area tanpa bayar → item hilang.")

func set_interactable(node: Node):
	current_interactable = node

func clear_interactable(node: Node):
	if current_interactable == node:
		current_interactable = null

func _enable_item_collision(item: Node):
	if item is CollisionObject3D:
		item.collision_layer = 1  # sesuaikan layer world item kamu
		item.collision_mask = 1   # sesuaikan mask
	
	for child in item.get_children():
		if child is CollisionShape3D:
			child.disabled = false
		
		if child.get_child_count() > 0:
			_enable_item_collision(child)

func _on_input_quickslot(item_data: ItemData):
	print("DEBUG: Player terima request input quickslot", item_data.item_name)
	# Bisa tambah logic kalau perlu (misal cek duplikat)

func _on_input_quickuse(item_data: ItemData):
	print("DEBUG: Player terima request input quickuse", item_data.item_name)

func _handle_sheathe():

	if equipped_items.is_empty():
		anim_player.play("Idle")
		print("DEBUG DROP/SHEATHE: Kembali ke default Idle")
		return

	print("DEBUG SHEATHE: Mulai sheathe, equipped count:", equipped_items.size())

	var sheathed_any = false
	var item_ids_to_remove = []

	var hands = [right_hand_attachment, left_hand_attachment]

	for hand in hands:
		if hand and hand.get_child_count() > 0:
			for child in hand.get_children():

				if child.has_meta("item_id"):

					var item_id = child.get_meta("item_id")

					if item_id in equipped_items:

						var source = equipped_source.get(item_id, "world")

						# =========================
						# 🔥 FIX UTAMA
						# =========================
						if source == "world":
							print("DEBUG SHEATHE: Item dari world → tidak boleh disheath")
							continue

						var data = equipped_items.get(item_id)
						var item_node = data["node"] if data else null

						if not is_instance_valid(item_node):
							continue

						var item_data : ItemData = data["item_data"]

						# weapon manager
						if item_data.item_type == ItemData.ItemType.WEAPON:
							WeaponManager.unequip_weapon()

						# dua tangan fix
						if data.get("two_handed", false):
							var grip_left = item_node.get_node_or_null("GripPointLeft")
							if grip_left and grip_left.get_parent():
								grip_left.get_parent().remove_child(grip_left)
								grip_left.reparent(item_node)

						hand.remove_child(item_node)

						if source == "inventory":
							item_node.queue_free()
							InventoryManager.add_item(item_data)

						elif source == "quickuse" or source == "quickslot":
							item_node.queue_free()

						item_ids_to_remove.append(item_id)
						sheathed_any = true

	for item_id in item_ids_to_remove:
		equipped_items.erase(item_id)
		equipped_source.erase(item_id)

	if sheathed_any:
		print("DEBUG SHEATHE: Selesai:", item_ids_to_remove.size())
	else:
		print("DEBUG SHEATHE: Tidak ada item valid untuk disheath")



func handle_interaction():

	print("INTERACT CHECK")
	print("current_interactable =", current_interactable)

	if is_interacting or mode == PlayerMode.BIKE or current_interactable == null:
		return
   
	# KHUSUS TAS
	if current_interactable.has_method("is_backpack") and current_interactable.is_backpack():
		if has_backpack: return
		backpack_item = current_interactable
		has_backpack = true
		backpack_item.equip(self)
		GM.has_backpack = true
		return
		
	if current_interactable is Cashier:
		current_interactable.process_payment(self)
		return
   
	# ============================
	# 🔥 KHUSUS STORE CONTAINER
	# ============================
	if current_interactable.has_method("open_container"):
		current_interactable.open_container(self)
		return
   
	# ITEM STORABLE/USEABLE (world item biasa)
	if current_interactable.has_method("get_item_data") and current_interactable.get_item_data():
		var item_data = current_interactable.get_item_data()
		interact_popup.show_popup(current_interactable, item_data)
		_toggle_touchscreen_block(true)
		return
   
	# CARRY BIASA
	if current_interactable.has_method("pick_up"):
		if is_carrying:
			start_drop()
			current_interactable.drop()
		else:
			start_pickup()   # 🔥 INI YANG HILANG
			current_interactable.pick_up()
	
	if current_interactable.has_method("interact"):
		print("DEBUG: CALL INTERACT ->", current_interactable)
		current_interactable.interact(self)
		return

func can_start_vocab_minigame() -> bool:
	if NeedsManager.mood <= 15:
		# Tampilkan popup warning (kamu bisa buat UI warning sederhana nanti)
		print("DEBUG: Mood terlalu rendah! Sulit fokus belajar vocab (mood:", NeedsManager.mood, ")")
		# Optional: tampilkan popup atau animasi pusing
		return false
	return true

# Handler popup
func _on_popup_use(item_node: Node, item_data: ItemData):
	_use_item(item_node, item_data)
	set_input_locked(false)
	_toggle_touchscreen_block(false)  # buka kembali

func _on_popup_store(item_node: Node, item_data: ItemData):
	_store_item(item_node, item_data)
	set_input_locked(false)
	_toggle_touchscreen_block(false)

func _on_popup_cancel():
	set_input_locked(false)
	print("DEBUG: Popup dibatalkan")
	_toggle_touchscreen_block(false)

func _on_inventory_use(item_data: ItemData):
	print("DEBUG PLAYER: Use dari inventory")
	var success = InventoryManager.remove_item(item_data.item_id, 1)
	if not success:
		print("ERROR: Gagal remove item dari inventory")
		return
	_use_item(null, item_data, "inventory")
	inventory_ui.populate_inventory(InventoryManager.get_items())


func _on_inventory_drop(item_data: ItemData):
	print("DEBUG PLAYER: Drop dari inventory")
	if InventoryManager.remove_item(item_data.item_id, 1):
		# Spawn item di world kalau ingin drop visual
		if item_data.item_scene_path != "":
			var scene = load(item_data.item_scene_path)
			if scene:
				var instance = scene.instantiate()
				get_tree().current_scene.add_child(instance)
				instance.global_position = global_position + (-global_transform.basis.z * 1.5)
				instance.scale = item_data.world_scale if "world_scale" in item_data else Vector3.ONE
				print("DEBUG: Item dari inventory di-drop ke world:", item_data.item_name)
	inventory_ui.populate_inventory(InventoryManager.get_items())


# Fungsi baru untuk toggle blokir TouchScreenUI
func _toggle_touchscreen_block(block: bool):
	var touchscreen_ui = get_tree().get_root().get_node_or_null("TouchScreenUI")
	if touchscreen_ui and touchscreen_ui.has_method("block_input"):
		touchscreen_ui.block_input(block)

func is_holding_item() -> bool:
	return not equipped_items.is_empty()

func open_wallet_payment(total:int, desc:String="", callback=null):

	if not is_instance_valid(smartphone_ui):
		return

	smartphone_ui.open_wallet_with_payment(
		total,
		desc,
		callback
	)

func _use_item(item_node: Node, item_data: ItemData, source: String = "world"):

	print("=== USE ITEM START ===")

	if StoreTransactionManager.is_item_unpaid(item_data):
		print("Item belum dibayar!")
		return

	# =========================
	# 🔥 FIX 0: FORCE CLEAR HAND (KHUSUS INVENTORY)
	# =========================
	if source == "inventory":
		print("DEBUG: FORCE CLEAR HAND BEFORE EQUIP")

		for hand in [right_hand_attachment, left_hand_attachment]:
			for child in hand.get_children():
				if child.has_meta("item_id"):
					var old_id = child.get_meta("item_id")

					if equipped_items.has(old_id):
						equipped_items.erase(old_id)
						equipped_source.erase(old_id)

					child.queue_free()

	# =========================
	# 🔥 FIX 1: CLEAN INVALID DATA
	# =========================
	if equipped_items.has(item_data.item_id):
		var old = equipped_items[item_data.item_id]

		if not is_instance_valid(old["node"]):
			equipped_items.erase(item_data.item_id)
			equipped_source.erase(item_data.item_id)
		else:
			print("DEBUG: Item masih valid di tangan, skip")
			return

	# =========================
	# 🔥 LOAD SCENE
	# =========================
	if item_data.equip_scene_path == "":
		print("ERROR: equip_scene_path kosong")
		return

	var scene = load(item_data.equip_scene_path)
	if not scene:
		print("ERROR: gagal load equip scene")
		return

	var instance = scene.instantiate()
	instance.set_meta("item_id", item_data.item_id)

	print("DEBUG: INSTANCE CREATED:", instance)

	var grip_r = instance.get_node_or_null("GripPointRight")
	var grip_l = instance.get_node_or_null("GripPointLeft")

	var has_r = grip_r != null
	var has_l = grip_l != null

	var right = right_hand_attachment
	var left = left_hand_attachment

	var target_hand : BoneAttachment3D = null
	var target_left : BoneAttachment3D = null

	# =========================
	# 🔥 SLOT LOGIC (FIX STRICT)
	# =========================
	if has_r and has_l:
		target_hand = right
		target_left = left

	elif has_r:
		target_hand = right

	elif has_l:
		target_hand = left

	else:
		target_hand = right

	# =========================
	# 🔥 REMOVE WORLD ITEM
	# =========================
	if source == "world" and is_instance_valid(item_node):
		if item_node.get_parent():
			item_node.get_parent().remove_child(item_node)
		item_node.queue_free()

	# =========================
	# 🔥 SPAWN KE TANGAN
	# =========================
	target_hand.add_child(instance)

	if has_r:
		instance.transform = grip_r.transform.affine_inverse()
	elif has_l:
		instance.transform = grip_l.transform.affine_inverse()
	else:
		instance.transform = Transform3D.IDENTITY

	instance.scale = item_data.equip_scale

	# =========================
	# 🔥 DUA TANGAN
	# =========================
	if has_r and has_l and target_left:
		var grip_left = instance.get_node("GripPointLeft")
		grip_left.reparent(target_left)
		grip_left.transform = Transform3D.IDENTITY

	_disable_item_collision(instance)

	if instance.has_method("disable_interaction"):
		instance.disable_interaction()

	# =========================
	# 🔥 REGISTER
	# =========================
	equipped_items[item_data.item_id] = {
		"node": instance,
		"item_data": item_data,
		"two_handed": has_r and has_l,
		"world_scale": item_data.world_scale,
		"current_durability": item_data.max_durability
	}

	equipped_source[item_data.item_id] = source

	print("DEBUG: EQUIPPED ITEMS NOW:", equipped_items.keys())

	# =========================
	# 🔥 WEAPON
	# =========================
	if item_data.item_type == ItemData.ItemType.WEAPON:
		WeaponManager.equip_weapon(instance)

	if item_data.auto_idle_anim != "":
		anim_player.play(item_data.auto_idle_anim)

	print("✅ ITEM MASUK TANGAN (FINAL FIX)")

	print("=== USE ITEM END ===")

func _disable_item_collision(item: Node):
	# Kalau item punya CollisionObject3D (RigidBody3D, Area3D, dll)
	if item is CollisionObject3D:
		item.collision_layer = 0
		item.collision_mask = 0
	
	# Cari semua CollisionShape3D di dalam item
	for child in item.get_children():
		if child is CollisionShape3D:
			child.disabled = true
		
		# recursive kalau nested
		if child.get_child_count() > 0:
			_disable_item_collision(child)

func _play_weapon_animation(anim_name: String):

	var active_item = _get_item_in_right_hand()

	if not active_item:
		return

	var anim_player = active_item.get_node_or_null("AnimationPlayer")

	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

# FUNGSI UNTUK STORE (masuk inventory)
func _store_item(item_node: Node, item_data: ItemData):
	if not has_backpack:
		print("DEBUG: Tidak bisa store item - belum pakai tas!")
		return
	
	if item_data.is_storable:
		if InventoryManager.add_item(item_data, item_node.pickup_amount):
			item_node.queue_free()  # hilang dari dunia setelah masuk inventory
			print("DEBUG: Item stored ke inventory:", item_data.item_name)
		else:
			print("DEBUG: Inventory penuh, tidak bisa store:", item_data.item_name)
	else:
		print("DEBUG: Item tidak bisa disimpan:", item_data.item_name)

func start_bath(bath):

	if mode != PlayerMode.WALK:
		return

	current_bath = bath

	mode = PlayerMode.BATH

	set_input_locked(true)

	velocity = Vector3.ZERO

	global_position = bath.bath_point.global_position

	visual_root.global_rotation.y = \
		bath.bath_point.global_rotation.y

	# Tampilkan air bathub
	bath.water_mesh.visible = true

	print("BATH START")

	anim_player.play("BathStart")

	await anim_player.animation_finished

	print("BATH LOOP")

	anim_player.play("BathLoop")

	while NeedsManager.hygiene < 90:

		NeedsManager.hygiene = clamp(
			NeedsManager.hygiene + 2,
			0,
			100
		)

		# Bonus kecil karena berendam
		NeedsManager.mood = clamp(
			NeedsManager.mood + 0.2,
			0,
			100
		)

		await get_tree().create_timer(0.5).timeout

	await finish_bath()

func finish_bath():

	if current_bath == null:
		return

	print("BATH FINISH")

	# Sembunyikan air
	current_bath.water_mesh.visible = false

	anim_player.play("BathEnd")

	await anim_player.animation_finished

	if current_bath.exit_point:

		global_position = current_bath.exit_point.global_position

		visual_root.global_rotation.y = current_bath.exit_point.global_rotation.y

	mode = PlayerMode.WALK

	set_input_locked(false)

	anim_player.play("Idle")

	current_bath = null

func start_shower(shower):

	if mode != PlayerMode.WALK:
		return

	current_shower = shower

	mode = PlayerMode.SHOWER

	set_input_locked(true)

	velocity = Vector3.ZERO

	global_position = shower.shower_point.global_position

	visual_root.global_rotation.y = \
		shower.shower_point.global_rotation.y

	shower.water_particles.visible = true
	shower.water_particles.emitting = true

	anim_player.play("StartShower")

	await anim_player.animation_finished

	anim_player.play("LoopShower")

	while NeedsManager.hygiene < 90:
		NeedsManager.hygiene = clamp(
			NeedsManager.hygiene + 1,
			0,
			100
		)
		
		await get_tree().create_timer(1.0).timeout

	finish_shower()

func finish_shower():

	if current_shower == null:
		return

	current_shower.water_particles.emitting = false
	current_shower.water_particles.visible = false

	anim_player.play("EndShower")

	await anim_player.animation_finished

	global_position = \
		current_shower.exit_point.global_position

	visual_root.global_rotation.y = \
		current_shower.exit_point.global_rotation.y

	mode = PlayerMode.WALK

	set_input_locked(false)

	anim_player.play("Idle")

	current_shower = null

func start_pee(closet):

	if mode != PlayerMode.WALK:
		return

	current_closet = closet

	mode = PlayerMode.TOILET

	set_input_locked(true)

	velocity = Vector3.ZERO

	global_position = closet.sit_point.global_position
	visual_root.global_rotation.y = closet.sit_point.global_rotation.y

	anim_player.play("Pee")

	await anim_player.animation_finished

	NeedsManager.bladder = clamp(
		NeedsManager.bladder + 20,
		0,
		100
	)

	finish_toilet()

func start_poop(closet):

	if mode != PlayerMode.WALK:
		return

	current_closet = closet

	mode = PlayerMode.TOILET

	set_input_locked(true)

	velocity = Vector3.ZERO

	global_position = closet.sit_point.global_position
	visual_root.global_rotation.y = closet.sit_point.global_rotation.y

	anim_player.play("PoopStart")

	await anim_player.animation_finished

	anim_player.play("PoopLoop")

	while NeedsManager.bladder < 100:

		NeedsManager.bladder = clamp(
			NeedsManager.bladder + 2,
			0,
			100
		)

		await get_tree().create_timer(0.5).timeout

	anim_player.play("PoopEnd")

	await anim_player.animation_finished

	finish_toilet()

func finish_toilet():

	if current_closet:

		global_position = current_closet.exit_point.global_position

		visual_root.global_rotation.y = \
			current_closet.exit_point.global_rotation.y

	mode = PlayerMode.WALK

	set_input_locked(false)

	anim_player.play("Idle")

	current_closet = null

func sleep_on_bed(bed, point, wake):

	if mode != PlayerMode.WALK:
		return

	is_sleeping = true
	mode = PlayerMode.SLEEP

	sleep_bed = bed
	sleep_point = point
	wake_point = wake

	set_input_locked(true)

	velocity = Vector3.ZERO

	global_position = point.global_position
	global_rotation = point.global_rotation

	anim_player.play("Sleep")

func start_sleep(hours: int, minutes: int = 0):

	print("START SLEEP CALLED")
	print("CURRENT MODE =", mode)

	if mode != PlayerMode.WALK:
		print("RETURN MODE CHECK")
		return

	print("STEP 1")

	is_sleeping = true
	mode = PlayerMode.SLEEP

	set_input_locked(true)

	velocity = Vector3.ZERO

	print("STEP 2")

	if sleep_point:
		print("SLEEP ROT =", rad_to_deg(sleep_point.global_rotation.y))
		saved_sleep_rotation_y = visual_root.rotation.y
		
		global_position = sleep_point.global_position
		velocity = Vector3.ZERO
		
		visual_root.global_rotation.y = sleep_point.global_rotation.y
		print(
			"PLAYER ROT AFTER =",
			rad_to_deg(visual_root.global_rotation.y)
		)

	print("STEP 3")

	anim_player.play("Sleep")

	print("STEP 4 - WAIT SLEEP")

	await anim_player.animation_finished

	print("STEP 5 - SLEEP FINISHED")

	await Sceneswitcher.fade_out()

	print("STEP 6 - FADE OUT")

	await get_tree().create_timer(0.5).timeout

	print("STEP 7 - SKIP TIME")

	TimeManager.skip_time(hours, minutes)

	var sleep_hours = float(hours) + float(minutes) / 60.0

	NeedsManager.apply_sleep(sleep_hours)

	print("STEP 8")

	await Sceneswitcher.fade_in()

	anim_player.play("WakeUp")

	print("STEP 9 - WAIT WAKEUP")

	await anim_player.animation_finished

	print("STEP 10 - WAKEUP FINISHED")

	if wake_point:
		global_position = wake_point.global_position
		visual_root.rotation.y = wake_point.global_rotation.y

	mode = PlayerMode.WALK
	is_sleeping = false

	set_input_locked(false)

	anim_player.play("Idle")

	print("STEP 11 - DONE")

func wake_up():

	if mode != PlayerMode.SLEEP:
		return

	is_sleeping = false
	mode = PlayerMode.WALK

	set_input_locked(false)

	if wake_point:
		global_position = wake_point.global_position

	anim_player.play("Idle")


func _respawn_backpack_after_ready():
	await get_tree().process_frame

	if not GM.has_backpack:
		return

	if GM.backpack_scene_path == "":
		print("DEBUG TAS RESPAWN: Path kosong, skip respawn")
		return

	print("DEBUG PLAYER: Respawn tas (deferred) dari path:", GM.backpack_scene_path)

	var tas_scene = load(GM.backpack_scene_path)
	if not tas_scene:
		print("ERROR TAS RESPAWN: Gagal load scene:", GM.backpack_scene_path)
		return

	var tas_instance = tas_scene.instantiate()
	var world = get_tree().current_scene
	if not world:
		print("ERROR: current_scene null")
		return

	world.add_child(tas_instance)
	backpack_item = tas_instance
	has_backpack = true

	await get_tree().process_frame

	if is_instance_valid(backpack_item):
		backpack_item.equip(self)
		print("DEBUG TAS RESPAWN: Tas berhasil di-respawn dan di-equip")
		
		
func _handle_swimming(delta):

	# =====================================
	# INPUT HORIZONTAL
	# =====================================
	var input_dir = Input.get_vector("Kiri", "Kanan", "Maju", "Mundur")

	var pivot = get_active_pivot()
	var cam_basis = pivot.global_transform.basis

	# 🔥 FIX PEMBALIKAN W/S
	var move_dir = (
		cam_basis.x * input_dir.x +
		cam_basis.z * input_dir.y
	)

	move_dir.y = 0

	# =====================================
	# VERTICAL CONTROL
	# =====================================
	var vertical := 0.0

	if Input.is_action_pressed("Lompat"):
		vertical += 1.0

	if Input.is_action_pressed("Crouch"):
		vertical -= 1.0

	move_dir.y = vertical
	move_dir = move_dir.normalized()

	# =====================================
	# SPEED
	# =====================================
	var speed := swim_speed

	if Input.is_action_pressed("Lari"):
		speed = swim_fast_speed

	velocity = move_dir * speed

	# =====================================
	# ROTASI
	# =====================================
	var flat_dir = Vector3(move_dir.x, 0, move_dir.z)

	if flat_dir.length() > 0.1:
		visual_root.rotation.y = lerp_angle(
			visual_root.rotation.y,
			atan2(flat_dir.x, flat_dir.z),
			delta * rotation_speed
		)

	# =====================================
	# ANIMASI
	# =====================================
	if move_dir.length() < 0.05:

		if anim_player.current_animation != "IdleWater":
			anim_player.play("IdleWater")

	else:
		if Input.is_action_pressed("Lari"):

			if anim_player.current_animation != "FreeStyle":
				anim_player.play("FreeStyle")

		else:

			if anim_player.current_animation != "FrogStyle":
				anim_player.play("FrogStyle")

	NeedsManager.apply_swimming_effect(delta)


func enter_swim_mode():

	if is_swimming:
		return

	is_swimming = true
	is_crouching = false
	velocity = Vector3.ZERO

	# langsung idle air
	if anim_player.current_animation != "IdleWater":
		anim_player.play("IdleWater")


func exit_swim_mode():

	if not is_swimming:
		return

	is_swimming = false
	velocity = Vector3.ZERO

	if anim_player.current_animation != "Idle":
		anim_player.play("Idle")

func _handle_ladder(delta):

	if ladder_ref == null:
		exit_ladder()
		return

	var move := 0.0

	if Input.is_action_pressed("Maju"):
		move = 1.0
	elif Input.is_action_pressed("Mundur"):
		move = -1.0

	velocity = Vector3.ZERO
	velocity.y = move * ladder_speed

	if move != 0:
		anim_player.play("LadderWalk")
	else:
		anim_player.play("LadderIdle")

	# keluar atas
	if ladder_ref.top_exit and global_position.y >= ladder_ref.top_exit.global_position.y:
		global_position = ladder_ref.top_exit.global_position
		exit_ladder()
		return

	# keluar bawah
	if ladder_ref.bottom_exit and global_position.y <= ladder_ref.bottom_exit.global_position.y:
		global_position = ladder_ref.bottom_exit.global_position
		exit_ladder()
		return


func enter_ladder(ladder):

	if is_on_ladder:
		return

	# MATIKAN SEMUA MODE LAIN
	is_swimming = false
	is_crouching = false
	velocity = Vector3.ZERO

	is_on_ladder = true
	ladder_ref = ladder

	global_position = ladder.get_mount_position()

	# hadap tangga
	visual_root.rotation.y = ladder.global_rotation.y

	anim_player.play("LadderIdle")

func exit_ladder():

	is_on_ladder = false
	ladder_ref = null

	velocity = Vector3.ZERO
	anim_player.play("Idle")

func update_kart_animation():

	if anim_player.current_animation != "GoRide":
		anim_player.play("GoRide")

func _is_mission_ui_open() -> bool:
	return get_tree().get_nodes_in_group("mission_ui").size() > 0

func _physics_process(delta):
	_apply_needs_effects()
	_update_crouch_state()
	_update_carry_position()
	
	# ============================
	# 🚴 BIKE MODE
	# ============================
	if mode == PlayerMode.BIKE:
		var input_dir := Input.get_vector("Kiri", "Kanan", "Maju", "Mundur")
		var local_dir := Vector3(input_dir.x, 0, -input_dir.y)
		
		var pivot = get_active_pivot()
		var cam_basis = pivot.transform.basis
		var bike_dir = (cam_basis.x * local_dir.x) + (-cam_basis.z * local_dir.z)
		
		bike_dir.y = 0
		bike_dir = bike_dir.normalized()
		
		_update_vehicle_camera(delta)
		update_bike_animation(bike_dir)
		
		if food_carrying and current_carried_item:
			var target_point: Node3D = null
			if mode == PlayerMode.DINING_SIT:
				target_point = get_node_or_null("metarig/FoodSitPoint")
			else:
				target_point = get_node_or_null("metarig/FoodCarryPoint")
			if target_point:
				current_carried_item.global_position = target_point.global_position
				current_carried_item.global_rotation = target_point.global_rotation
		elif is_carrying and current_carried_item:
			var carry_point: Node3D = get_node_or_null("metarig/CarryPoint")
			if carry_point:
				current_carried_item.global_position = carry_point.global_position
				current_carried_item.global_rotation = carry_point.global_rotation
		
		move_and_slide()
		_update_waypoint_indicator(delta)
		return
	
	# ============================
	# 🏎 KART MODE
	# ============================
	elif mode == PlayerMode.KART:
		_update_vehicle_camera(delta)
		update_kart_animation()
		
		move_and_slide()
		_update_waypoint_indicator(delta)
		return

	# ============================
	# 🔒 MOVEMENT STATE
	# ============================
	var movement_blocked = is_input_blocked("movement")
	
	if mode == PlayerMode.BATH:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if mode == PlayerMode.SHOWER:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if mode == PlayerMode.TOILET:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if mode == PlayerMode.SLEEP:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	
	if is_on_ladder:
		_handle_ladder(delta)
		move_and_slide()
		return

	if is_swimming:
		_handle_swimming(delta)
		move_and_slide()
		_update_waypoint_indicator(delta)
		return

	# ============================
	# 🌍 GRAVITY
	# ============================
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
	
	# ============================
	# SIT LOCK
	# ============================
	if mode == PlayerMode.CLASSROOM_SIT and sit_point:
		global_position = sit_point.global_position
		velocity = Vector3.ZERO
		if Input.is_action_just_pressed("Lompat"):
			print("CLASSROOM STAND UP")
			stand_up()
			return
		move_and_slide()
		return
	elif mode == PlayerMode.DINING_SIT and sit_point:
		global_position = sit_point.global_position
		velocity = Vector3.ZERO
		if Input.is_action_just_pressed("Lompat"):
			print("DINING STAND UP")
			stand_up_dining()
			return
		move_and_slide()
		return

	# ============================
	# 🔥 AUTO SIT FIX (INI KUNCI UTAMA)
	# ============================
	if classroom_sit and sit_point and mode != PlayerMode.CLASSROOM_SIT:
		var dist = global_position.distance_to(sit_point.global_position)
		
		if dist < 1.5 and is_on_floor():
			print("AUTO RE-SIT TRIGGER")
			sit_on_classroom_chair(sit_chair, sit_point, look_at_target)

	# ============================
	# 🎮 INPUT WASD
	# ============================
	var input_dir := Vector2.ZERO
	if not movement_blocked:
		input_dir = Input.get_vector("Kiri", "Kanan", "Maju", "Mundur")

	var local_dir = Vector3(input_dir.x, 0, -input_dir.y)
	var pivot = get_active_pivot()
	var cam_basis = pivot.transform.basis
	var dir = (cam_basis.x * local_dir.x) + (-cam_basis.z * local_dir.z)
	
	dir.y = 0
	dir = dir.normalized()

	# ============================
	# 🚶 MOVEMENT
	# ============================
	if not movement_blocked:
		is_running = Input.is_action_pressed("Lari") and not is_crouching
		var speed := walk_speed
		if is_crouching:
			speed = crouch_speed
		elif is_running:
			speed = run_speed
		else:
			speed = walk_speed

		velocity.x = move_toward(velocity.x, dir.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, acceleration * delta)
	else:
		velocity.x = 0
		velocity.z = 0

	$metarig.position = Vector3.ZERO

	# ============================
	# 🔄 ROTATION
	# ============================
	if mode == PlayerMode.CLASSROOM_SIT or mode == PlayerMode.DINING_SIT:
		if look_at_target:
			var look_dir = (look_at_target.global_position- global_position)
			look_dir.y = 0
			look_dir = look_dir.normalized()
			var target_rot_y = atan2(look_dir.x,look_dir.z)
			visual_root.rotation.y = target_rot_y
		else:
			visual_root.rotation.y = camera_default_yaw
	elif dir.length() > 0.01 and camera_mode != CameraMode.FP:
		visual_root.rotation.y = lerp_angle(
			visual_root.rotation.y,
			atan2(dir.x, dir.z),
			delta * rotation_speed
		)

	# ============================
	# 🔥 JUMP
	# ============================
	if Input.is_action_just_pressed("Lompat"):
		if mode == PlayerMode.CLASSROOM_SIT:
			print("DEBUG: CLASSROOM SIT - CALLING stand_up()")
			stand_up()
		elif mode == PlayerMode.DINING_SIT:
			print("DEBUG: DINING SIT - CALLING stand_up_dining()")
			stand_up_dining()
		elif is_on_floor() and not movement_blocked:
			print("DEBUG: NORMAL JUMP")
			velocity.y = jump_velocity

	# ============================
	# 🎬 ANIMATION FIX
	# ============================
	if mode == PlayerMode.SLEEP:
		if anim_player.current_animation != "Sleep":
			anim_player.play("Sleep")
	elif mode == PlayerMode.CLASSROOM_SIT:
		if anim_player.current_animation != "Sit":
			anim_player.play("Sit")
	elif mode == PlayerMode.DINING_SIT:
		if dining_eating:
			if anim_player.current_animation != "Eat":
				anim_player.play("Eat")
		else:
			if anim_player.current_animation != "Sit":
				anim_player.play("Sit")
	else:
		if is_using_phone_camera:
			if anim_player.current_animation != "Picture":
				anim_player.play("Picture")
		elif upper_state == UpperState.NONE and not is_interacting:
			update_walk_animation(dir)
	
	_update_run_sfx(delta)
	move_and_slide()
	_update_waypoint_indicator(delta)

	# ============================
	# 🐞 DEBUG
	# ============================
	debug_position_timer += delta
	if debug_position_timer >= DEBUG_POSITION_INTERVAL:
		debug_position_timer -= DEBUG_POSITION_INTERVAL
		
		var pos = global_position
		var rot_y_deg = rad_to_deg(visual_root.rotation.y)
		
		var held = _get_item_in_right_hand()
		var held_name = held.get_meta("item_id") if held and held.has_meta("item_id") else "kosong"
		
		print("VISUAL ROOT POS:", visual_root.global_position)
		print("DEBUG POS [%s s] | pos=(%.2f, %.2f, %.2f) | rot_y=%.1f° | grounded=%s | vel=(%.2f, %.2f, %.2f) | upper=%s | anim=%s | held=%s" % [
			"%.2f" % (Time.get_ticks_msec() / 1000.0),
			pos.x, pos.y, pos.z,
			rot_y_deg,
			str(is_on_floor()),
			velocity.x, velocity.y, velocity.z,
			str(upper_state),
			anim_player.current_animation if anim_player and anim_player.current_animation else "<none>",
			held_name
		])

func _handle_normal_anim():
	if not is_on_floor():
		if anim_player.current_animation != "Jump":
			anim_player.play("Jump")
		return

	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()

	if horizontal_speed < 0.1:
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")
	elif is_running:
		if anim_player.current_animation != "Run":
			anim_player.play("Run")
	else:
		if anim_player.current_animation != "Walk":
			anim_player.play("Walk")


func _apply_needs_effects():

	if NeedsManager.energy <= 20:
		walk_speed = 6.0
		run_speed = 10.0
	else:
		walk_speed = 10.0
		run_speed = 17.0

	if NeedsManager.health <= 10:
		run_speed = 0.0

	if NeedsManager.mood <= 15:
		walk_speed *= 0.8

func _lock_vehicle_camera():
	var pivot = get_active_pivot()
	if not is_instance_valid(pivot):
		return

	var forward_yaw = visual_root.rotation.y
	pivot.target_yaw = forward_yaw + PI
	pivot.target_pitch = deg_to_rad(5)

func _update_vehicle_camera(delta):

	if mode != PlayerMode.BIKE and mode != PlayerMode.KART:
		return

	var pivot = get_active_pivot()
	if not is_instance_valid(pivot):
		return

	# =============================
	# 🎯 TARGET YAW = ARAH KENDARAAN
	# =============================
	var target_yaw = visual_root.global_rotation.y + PI

	# =============================
	# 🔥 AUTO CENTER (SMOOTH FOLLOW)
	# =============================
	pivot.target_yaw = lerp_angle(
		pivot.target_yaw,
		target_yaw,
		delta * vehicle_camera_follow_strength
	)

	# =============================
	# 🎥 PITCH FIX
	# =============================
	pivot.target_pitch = lerp(
		pivot.target_pitch,
		deg_to_rad(5),
		delta * 5.0
	)

func enter_kart():

	if mode == PlayerMode.KART:
		return

	print("🏎 ENTER KART")

	mode = PlayerMode.KART
	velocity = Vector3.ZERO
	var pivot = get_active_pivot()
	if is_instance_valid(pivot):
		pivot.is_looking_around = false
	anim_player.stop(true)
	anim_player.play("GoRide")

	_lock_vehicle_camera()   # 🔥 TAMBAHAN

func exit_kart():

	print("🛑 EXIT KART")

	mode = PlayerMode.WALK

	var pivot = get_active_pivot()
	if is_instance_valid(pivot):
		pivot.is_looking_around = true

	anim_player.stop()
	anim_player.play("Idle")


func _get_item_in_right_hand():
	for child in right_hand_attachment.get_children():
		if child.has_meta("item_id"):
			return child
	return null

func _update_carry_position():
	# ============================
	# 🍽 FOOD SYSTEM
	# ============================
	
	if current_carried_item and current_carried_item is PreparedFood:
		var target_point: Node3D = null
		
		# 🔥 CEK MODE DULU, BARU CEK FOOD_CARRYING
		if mode == PlayerMode.DINING_SIT:
			target_point = get_node_or_null("metarig/FoodSitPoint")
			print("🍽 DINING SIT MODE → FoodSitPoint")
		elif food_carrying:
			target_point = get_node_or_null("metarig/FoodCarryPoint")
			print("🍽 CARRYING MODE → FoodCarryPoint")
		
		if target_point:
			current_carried_item.global_position = target_point.global_position
			current_carried_item.global_rotation = target_point.global_rotation
		else:
			print("⚠️ Target point tidak ditemukan!")
		
		return
	
	# ============================
	# 📦 NORMAL CARRY SYSTEM
	# ============================
	
	if is_carrying and current_carried_item:
		var carry_point: Node3D = get_node_or_null("metarig/CarryPoint")
		
		if carry_point:
			current_carried_item.global_position = carry_point.global_position
			current_carried_item.global_rotation = carry_point.global_rotation


func update_animation(dir: Vector3):
	if mode == PlayerMode.BIKE:
		return

	update_walk_animation(dir)

func update_walk_animation(dir: Vector3):
	# PAKSA KELUAR DARI FOOD STATE
	if !food_carrying:
		if anim_player.current_animation == "FoodIdle":
			anim_player.play("Idle")

		elif anim_player.current_animation == "FoodWalk":
			if dir.length() > 0.01:
				anim_player.play("Walk")
			else:
				anim_player.play("Idle")

	if food_carrying:
		if dir.length() < 0.1:
			if anim_player.current_animation != "FoodIdle":
				anim_player.play("FoodIdle")
		else:
			if anim_player.current_animation != "FoodWalk":
				anim_player.play("FoodWalk")
		return

	if is_playing_fire:
		return

	if is_interacting:
		return

	if is_carrying:
		var carry_anim := ""
		if carry_style == "police":
			carry_anim = "Keep" if dir.length() > 0.01 else "StandStill"
		else:
			carry_anim = "Hold it" if dir.length() > 0.01 else "Brough"

		if anim_player.current_animation != carry_anim:
			anim_player.play(carry_anim)
		return

	if not is_on_floor():
		if anim_player.current_animation != "Jump":
			anim_player.play("Jump")
		return

	# =====================
	# CROUCH MODE
	# =====================
	if is_crouching:

		if dir.length() > 0.01:
			if anim_player.current_animation != "CrouchWalk":
				anim_player.play("CrouchWalk")
		else:
			if anim_player.current_animation != "Crouch":
				anim_player.play("Crouch")

		return

	# =====================
	# NORMAL MODE
	# =====================
	if dir.length() > 0.01:
		var walk_anim := "Run" if is_running else "Walk"

		if anim_player.current_animation != walk_anim:
			anim_player.play(walk_anim)
	else:
		if anim_player.current_animation != "Idle":
			anim_player.play("Idle")


func update_bike_animation(dir: Vector3):
	var is_moving := dir.length_squared() > 0.001

	# 🚴 TRANSISI SAJA, JANGAN REPLAY TIAP FRAME
	if is_moving and bike_anim_state != "Biking":
		anim_player.play("Biking")
		bike_anim_state = "Biking"
		return

	if not is_moving and bike_anim_state != "Idle Step":
		anim_player.play("Idle Step")
		bike_anim_state = "Idle Step"



func enter_bike():

	if mode == PlayerMode.BIKE:
		return

	print("🔥 ENTER BIKE")

	mode = PlayerMode.BIKE
	velocity = Vector3.ZERO
	var pivot = get_active_pivot()
	if is_instance_valid(pivot):
		pivot.is_looking_around = false
	bike_anim_state = ""
	anim_player.stop(true)

	_lock_vehicle_camera()   # 🔥 TAMBAHAN


func exit_bike():

	if exiting_bike:
		return

	exiting_bike = true
	print("🛑 EXIT BIKE")

	mode = PlayerMode.WALK
	bike_anim_state = ""

	var pivot = get_active_pivot()
	if is_instance_valid(pivot):
		pivot.is_looking_around = true

	await get_tree().process_frame
	exiting_bike = false


# ============================================================
# SIT SYSTEM
# ============================================================

func sit_on_chair(chair: Node, point: Node):
	mode = PlayerMode.SIT
	set_input_locked(true)
	sit_point = point
	saved_visual_rotation = visual_root.global_rotation

	global_position = point.global_position
	visual_root.global_rotation.y = point.global_rotation.y

func sit_on_classroom_chair(chair: Node, point: Node, look_target: Node):
	sitting = true
	classroom_sit = true
	mode = PlayerMode.CLASSROOM_SIT

	# 🔥 HANYA LOCK MOVEMENT
	input_context["movement"] = true

	sit_chair = chair
	sit_point = point
	look_at_target = look_target

	saved_visual_rotation = visual_root.global_rotation

	global_position = point.global_position
	velocity = Vector3.ZERO

	var look_dir = (look_at_target.global_position - global_position)
	look_dir.y = 0
	look_dir = look_dir.normalized()
	
	var target_rot_y = atan2(look_dir.x, look_dir.z)
	visual_root.rotation.y = target_rot_y

	camera_default_yaw = target_rot_y

	anim_player.play("Sit")

func stand_up():
	if mode != PlayerMode.SIT \
	and mode != PlayerMode.CLASSROOM_SIT:
		return

	if stand_up_lock:
		return

	sitting = false
	classroom_sit = false
	mode = PlayerMode.WALK

	# 🔥 UNLOCK MOVEMENT
	input_context["movement"] = false
	set_input_locked(false)

	stand_up_lock = true

	visual_root.global_rotation = saved_visual_rotation

	global_position += \
		visual_root.global_transform.basis.z * 1.0

	await get_tree().create_timer(0.8).timeout

	stand_up_lock = false

func sit_on_dining_chair(chair: Node, point: Node, look_target: Node):
	print("DINING CHAIR CALLED")
	print("BEFORE =", mode)

	sitting = true
	dining_sit = true
	mode = PlayerMode.DINING_SIT
	
	print("AFTER =", mode)
	
	# 🔥 HANYA LOCK MOVEMENT, BUKAN SEMUA INPUT
	input_context["movement"] = true
	# input_context["interaction"] dan lainnya tetap false/tidak dilock
	
	sit_chair = chair
	sit_point = point
	self.look_at_target = look_target
	saved_visual_rotation = visual_root.global_rotation

	var final_pos = point.global_position
	if food_carrying and current_carried_item:
		final_pos.y -= 0.5
	
	global_position = final_pos
	velocity = Vector3.ZERO

	var look_dir = (look_target.global_position - global_position)
	look_dir.y = 0
	look_dir = look_dir.normalized()

	var target_rot_y = atan2(look_dir.x, look_dir.z)
	visual_root.rotation.y = target_rot_y
	camera_default_yaw = target_rot_y

	dining_eating = current_carried_item is PreparedFood

	if dining_eating:
		anim_player.play("Eat")
	else:
		anim_player.play("Sit")
	
	call_deferred("_update_carry_position")

func stand_up_dining():
	print("DEBUG: stand_up_dining() START - mode:", mode, " dining_sit:", dining_sit)
	
	if mode != PlayerMode.DINING_SIT:
		print("DEBUG: Mode tidak DINING_SIT, return")
		return

	if stand_up_lock:
		print("DEBUG: stand_up_lock TRUE, return")
		return

	print("DEBUG: PROCEEDING WITH STAND UP DINING")
	
	# 🔥 RESET SEMUA FLAGS
	dining_sit = false
	dining_eating = false
	sitting = false
	food_carrying = false  # 🔥 TAMBAHAN INI
	is_carrying = false     # 🔥 TAMBAHAN INI JUGA
	
	mode = PlayerMode.WALK

	# 🔥 UNLOCK INPUT
	input_context["movement"] = false
	set_input_locked(false)

	stand_up_lock = true

	visual_root.global_rotation = saved_visual_rotation

	global_position += \
		visual_root.global_transform.basis.z * 1.0

	# 🔥 STOP ANIMATION DULU
	anim_player.stop()
	
	await get_tree().create_timer(0.8).timeout

	# 🔥 PLAY IDLE ANIMATION
	anim_player.play("Idle")
	
	stand_up_lock = false
	
	print("DEBUG: stand_up_dining() COMPLETE - mode:", mode)

func start_pickup():
	if is_interacting or is_carrying:
		return

	is_interacting = true
	velocity = Vector3.ZERO

	var anim_name := "Take it"
	if carry_style == "police":
		anim_name = "Pull it"

	anim_player.play(anim_name)
	await anim_player.animation_finished

	is_carrying = true
	is_interacting = false
	
	update_walk_animation(Vector3.ZERO)

func start_drop():
	if is_interacting or not is_carrying:
		return

	if mode == PlayerMode.BIKE or exiting_bike:
		return

	is_interacting = true
	velocity = Vector3.ZERO

	var anim_name := "Take it"
	if carry_style == "police":
		anim_name = "Pull it"

	anim_player.play_backwards(anim_name)
	await anim_player.animation_finished

	is_carrying = false
	is_interacting = false

	carry_style = "default"

func start_food_pickup():
	if is_interacting:
		return
	is_interacting = true
	velocity = Vector3.ZERO
	anim_player.play("FoodPickup")
	await anim_player.animation_finished
	is_interacting = false
	food_carrying = true

func start_food_drop():
	if is_interacting:
		return
	is_interacting = true
	velocity = Vector3.ZERO
	anim_player.play_backwards("FoodPickup")
	await anim_player.animation_finished
	is_interacting = false
	food_carrying = false

func _on_fullmap_waypoint_set(target_position: Vector3) -> void:
	set_waypoint(target_position)

func set_waypoint(pos: Vector3):
	target_waypoint = pos
	if is_instance_valid(arrow_indicator):
		arrow_indicator.visible = true

func _update_waypoint_indicator(delta: float):
	if target_waypoint == Vector3.INF:
		if is_instance_valid(arrow_indicator):
			arrow_indicator.visible = false
		return

	if not is_instance_valid(arrow_indicator):
		return

	var player_world_pos := global_transform.origin
	var target_world_pos := target_waypoint

	player_world_pos.y = 0.0
	target_world_pos.y = 0.0

	var distance := player_world_pos.distance_to(target_world_pos)
	if distance <= arrival_distance:
		target_waypoint = Vector3.INF
		arrow_indicator.visible = false
		return

	arrow_indicator.visible = true

	var world_dir := (target_world_pos - player_world_pos).normalized()

	var local_dir := global_transform.basis.inverse() * world_dir

	var target_yaw := atan2(local_dir.x, local_dir.z)

	var rot = arrow_indicator.rotation
	rot.x = 0.0
	rot.z = 0.0
	rot.y = lerp_angle(rot.y, target_yaw, delta * rotation_speed)
	arrow_indicator.rotation = rot


func force_unlock():
	# 🚴 BIKE ADALAH MODE TERKUNCI
	if mode == PlayerMode.BIKE:
		return

	sitting = false
	classroom_sit = false
	set_input_locked(false)

	# ❌ JANGAN PERNAH SENTUH stand_up_lock DI SINI
	# stand_up_lock = false  <-- HAPUS

	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
