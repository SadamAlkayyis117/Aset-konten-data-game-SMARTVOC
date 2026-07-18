extends CharacterBody3D

enum State { WALK, IDLE, REVERSE }

# =============== PATH INPUT ===============
@export var walk_path_1: NodePath
@export var walk_path_2: NodePath
@export var walk_path_3: NodePath
@export var walk_path_4: NodePath
@export var walk_path_5: NodePath

# =============== SETTINGS ===============
@export var speed := 15.0
@export var idle_duration := 1.5
@export var rotation_correction_deg: float = 90.0
@export var default_sit_duration: float = 7.0

# =============== INTERNAL ===============
var current_state = State.WALK
var current_path: Path3D
var follower: PathFollow3D
var is_sitting: bool = false

@onready var anim: AnimationPlayer = $AnimationPlayer

# =============== BEHAVIOR OBJECT (EXPORT) ===============
@export var phone_node: NodePath
@export var book_node: NodePath
@export var laptop_node: NodePath
@export var drink_node: NodePath

var obj_phone: Node3D
var obj_book: Node3D
var obj_laptop: Node3D
var obj_drink: Node3D

# =============== TIME MANAGER FIX (PERBAIKAN UTAMA) ===============
var _tm_connected := false


func _ready():
	randomize()
	choose_random_path()

	obj_phone = get_node_or_null(phone_node)
	obj_book = get_node_or_null(book_node)
	obj_laptop = get_node_or_null(laptop_node)
	obj_drink = get_node_or_null(drink_node)

	_hide_all_behavior_objects()
	
	# DIHAPUS: show(). Status visual ditentukan oleh TimeManager saat koneksi.

	print("[NPC] Ready → Scheduling TimeManager connect...")
	_schedule_connect_time_manager()


# mencoba koneksi setelah scene benar-benar stabil
func _schedule_connect_time_manager():
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_connect_time_manager()


# koneksi aman, retry otomatis sampai sukses
func _connect_time_manager():
	if _tm_connected:
		return

	print("\n======= NPC CONNECT DEBUG =======")
	
	# PERBAIKAN: Menggunakan akses global variabel TimeManager (GDScript Autoload)
	if TimeManager == null:
		print("[NPC] TimeManager NOT accessible (Global var is null) → retrying...")
		_schedule_connect_time_manager()
		return

	var tm = TimeManager # Akses langsung Autoload

	if not tm.has_method("debug_ping"):
		print("[NPC] TimeManager script missing 'debug_ping' method → retrying...")
		_schedule_connect_time_manager()
		return

	if not tm.has_signal("game_time_changed"):
		print("[NPC] TimeManager missing 'game_time_changed' signal → retrying...")
		_schedule_connect_time_manager()
		return

	var cb = Callable(self, "_on_time_changed")
	if not tm.game_time_changed.is_connected(cb):
		tm.game_time_changed.connect(cb)
		print("[NPC] CONNECTED to TimeManager!")
	else:
		print("[NPC] Already connected")

	_tm_connected = true
	print("=================================\n")
	
	# 🟢 PERBAIKAN KRUSIAL: Setelah berhasil terhubung, segera cek jadwal saat ini
	# Ini menyelesaikan masalah hide/show saat pindah scene dan kembali.
	_check_schedule_polling(tm.current_hour, tm.current_minute)


func _process(delta):
	# Polling hanya jika TimeManager sudah terhubung
	if _tm_connected:
		var tm = TimeManager
		_check_schedule_polling(tm.current_hour, tm.current_minute)

	if is_sitting:
		return
	state_machine(delta)
	rotate_to_velocity(delta)


# =========================================================
# POLLING FALLBACK / INITIAL CHECK (Diperbaiki)
# =========================================================
func _check_schedule_polling(h, m):
	# Tentukan rentang waktu harus bersembunyi (Hide)
	var is_hide_time = (
		(h >= 7 and h < 10) or                  # 7:00 - 9:59
		(h >= 11 and h < 14) or                 # 11:00 - 13:59
		(h >= 14 and m >= 30 and h <= 23) or    # 14:30 - 23:59
		(h >= 0 and h < 4)                      # 00:00 - 03:59
	)
	
	# Tentukan rentang waktu harus terlihat (Show)
	var is_show_time = (
		(h >= 4 and h < 7) or                   # 4:00 - 6:59
		(h >= 10 and h < 11) or                 # 10:00 - 10:59
		(h == 14 and m < 30)                    # 14:00 - 14:29
	)
	
	if is_hide_time and visible:
		# print("[NPC SCHEDULE] Hiding at %02d:%02d (Initial/Polling check)" % [h, m])
		hide()
	elif is_show_time and not visible:
		# print("[NPC SCHEDULE] Showing at %02d:%02d (Initial/Polling check)" % [h, m])
		show()


# =========================================================
# TIME MANAGER EVENT (Hanya menangani titik perubahan spesifik)
# =========================================================
func _on_time_changed(hour: int, minute: int) -> void:
	# print("[NPC] SIGNAL RECEIVED → %02d:%02d" % [hour, minute])

	if hour == 7 and minute == 0:
		hide()
	elif hour == 10 and minute == 0:
		show()
	elif hour == 11 and minute == 0:
		hide()
	elif hour == 14 and minute == 0:
		show()
	elif hour == 14 and minute == 30:
		hide()
	elif hour == 4 and minute == 0:
		show()


# ===================== FSM, PATH, ROTATION, BEHAVIOR ======================
# FUNGSI DI BAWAH INI TIDAK DIUBAH SAMA SEKALI
# ==========================================================================

func state_machine(delta):
	match current_state:
		State.WALK:
			if anim: anim.play("Walk")
			follow_path_forward(delta)

		State.IDLE:
			if anim: anim.play("Idle")
			velocity = Vector3.ZERO

		State.REVERSE:
			if anim: anim.play("Walk")
			follow_path_reverse(delta)


func choose_random_path():
	var paths: Array = []

	if walk_path_1 != NodePath(): paths.append(get_node_or_null(walk_path_1))
	if walk_path_2 != NodePath(): paths.append(get_node_or_null(walk_path_2))
	if walk_path_3 != NodePath(): paths.append(get_node_or_null(walk_path_3))
	if walk_path_4 != NodePath(): paths.append(get_node_or_null(walk_path_4))
	if walk_path_5 != NodePath(): paths.append(get_node_or_null(walk_path_5))

	paths = paths.filter(func(p): return p != null)

	if paths.is_empty():
		push_error("NPC ERROR: No valid walk paths assigned!")
		return

	current_path = paths.pick_random()

	if follower != null and is_instance_valid(follower):
		follower.queue_free()

	follower = PathFollow3D.new()
	follower.loop = false
	current_path.add_child(follower)
	follower.progress_ratio = 0.0

	current_state = State.WALK


func get_path_direction(reverse: bool) -> Vector3:
	if follower == null: return Vector3.ZERO
	var dir = follower.transform.basis.z
	return dir if reverse else -dir


func follow_path_forward(delta):
	if follower == null: return
	follower.progress += speed * delta

	var pos = follower.global_position
	global_position.x = pos.x
	global_position.z = pos.z

	velocity = get_path_direction(false) * speed

	if follower.progress_ratio >= 1.0:
		start_idle_before_reverse()


func follow_path_reverse(delta):
	if follower == null: return
	follower.progress -= speed * delta

	var pos = follower.global_position
	global_position.x = pos.x
	global_position.z = pos.z

	velocity = get_path_direction(true) * speed

	if follower.progress_ratio <= 0.0:
		start_idle_before_new_path()


func start_idle_before_reverse():
	current_state = State.IDLE
	velocity = Vector3.ZERO
	rotation.y += PI
	idle_timer(true)


func start_idle_before_new_path():
	current_state = State.IDLE
	velocity = Vector3.ZERO
	rotation.y += PI
	idle_timer(false)


func idle_timer(reverse_first: bool) -> void:
	await get_tree().create_timer(idle_duration).timeout
	if reverse_first:
		current_state = State.REVERSE
	else:
		choose_random_path()


func rotate_to_velocity(delta):
	if current_state == State.IDLE:
		return

	var hv = Vector3(velocity.x, 0, velocity.z)
	if hv.length() < 0.1:
		return

	var target_y = atan2(hv.x, hv.z)
	var corrected = target_y + deg_to_rad(rotation_correction_deg)
	rotation.y = lerp_angle(rotation.y, corrected, delta * 5.0)


func start_sitting(sit_duration: float = -1.0) -> void:
	if is_sitting:
		return

	is_sitting = true
	current_state = State.IDLE
	velocity = Vector3.ZERO
	_hide_all_behavior_objects()

	if anim and anim.has_animation("Sit_2"):
		anim.play("Sit_2")

	await get_tree().create_timer(2.0).timeout

	var duration = sit_duration if sit_duration > 0 else default_sit_duration
	var remaining = max(0.0, duration - 2.0)

	var choice = randi() % 4

	match choice:
		0: _apply_behavior("View", obj_phone)
		1: _apply_behavior("Read", obj_book)
		2: _apply_behavior("Type", obj_laptop)
		3: _apply_behavior("Drink", obj_drink)

	await get_tree().create_timer(remaining).timeout
	finish_sitting()


func finish_sitting():
	is_sitting = false
	_hide_all_behavior_objects()
	current_state = State.WALK


func _apply_behavior(anim_name: String, obj_node):
	_hide_all_behavior_objects()

	if is_instance_valid(obj_node):
		obj_node.visible = true

	if anim and anim.has_animation(anim_name):
		anim.play(anim_name)
	else:
		anim.play("Sit")


func _hide_all_behavior_objects():
	if is_instance_valid(obj_phone): obj_phone.visible = false
	if is_instance_valid(obj_book): obj_book.visible = false
	if is_instance_valid(obj_laptop): obj_laptop.visible = false
	if is_instance_valid(obj_drink): obj_drink.visible = false

# Fungsi Helper (lerp_angle)
func lerp_angle(from: float, to: float, weight: float) -> float:
	return from + wrapf(to - from, -PI, PI) * weight
