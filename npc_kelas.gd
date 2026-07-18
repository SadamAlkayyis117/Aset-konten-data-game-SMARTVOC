extends CharacterBody3D

enum State { WALK, IDLE, REVERSE }

# =============== PATH INPUT ===============
@export var walk_path_1: NodePath
@export var walk_path_2: NodePath
@export var walk_path_3: NodePath
@export var walk_path_4: NodePath
@export var walk_path_5: NodePath

# PATH KHUSUS KELAS
@export var class_path: NodePath

# =============== SETTINGS ===============
@export var speed := 15.0
@export var idle_duration := 1.5
@export var rotation_correction_deg: float = 90.0

# ROTASI DUDUK (derajat). Hanya rotasi Y; posisi tidak diubah.
@export var seat_rotation_y: float = 180.0

# =============== INTERNAL ===============
var current_state = State.WALK
var current_path: Path3D
var follower: PathFollow3D
var is_in_class_time := false
var is_sitting := false

@onready var anim: AnimationPlayer = $AnimationPlayer

# =============== TIME MANAGER ===============
var _tm_connected := false

func _ready():
	randomize()
	choose_random_path()
	show()
	_schedule_connect_time_manager()

func _schedule_connect_time_manager():
	# tunggu beberapa frame singkat supaya autoload siap
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_connect_time_manager()

func _connect_time_manager():
	if _tm_connected:
		return

	# retry otomatis sampai TimeManager siap
	if TimeManager == null:
		_schedule_connect_time_manager()
		return

	var tm = TimeManager
	if not tm.has_signal("game_time_changed"):
		_schedule_connect_time_manager()
		return

	var cb = Callable(self, "_on_time_changed")
	if not tm.game_time_changed.is_connected(cb):
		tm.game_time_changed.connect(cb)

	_tm_connected = true

# ======================== MAIN PROCESS =========================
func _process(delta):
	if _tm_connected:
		var tm = TimeManager
		_check_schedule_polling(tm.current_hour, tm.current_minute)

	if is_sitting:
		return

	state_machine(delta)
	rotate_to_velocity(delta)

# ======================== SCHEDULE =============================
func _check_schedule_polling(h, m):
	var in_class := false

	# MASA BELAJAR -> jika jam berada dalam interval kelas
	if (h >= 7 and h < 10) or (h >= 11 and h < 14):
		in_class = true

	if in_class and not is_in_class_time:
		enter_class_time()
	elif not in_class and is_in_class_time:
		exit_class_time()

	is_in_class_time = in_class

func _on_time_changed(hour, minute):
	_check_schedule_polling(hour, minute)

# ======================== CLASS TIME BEHAVIOR =============================
func enter_class_time():
	if class_path == NodePath():
		push_warning("NPC: class_path belum di-assign!")
		return

	_start_class_path()

func exit_class_time():
	if is_sitting:
		finish_sitting()

	choose_random_path()

func _start_class_path():
	var cp: Path3D = get_node_or_null(class_path)
	if cp == null:
		push_error("NPC ERROR: class_path tidak valid!")
		return

	if follower != null and is_instance_valid(follower):
		follower.queue_free()

	current_path = cp
	follower = PathFollow3D.new()
	follower.loop = false
	cp.add_child(follower)
	follower.progress_ratio = 0.0

	current_state = State.WALK

# ====================== FSM, ROTATION, MOVEMENT ==========================
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
	if is_in_class_time:
		return

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
	if follower == null:
		return

	follower.progress += speed * delta

	var pos = follower.global_position
	global_position.x = pos.x
	global_position.z = pos.z

	# ✅ Arah berdasarkan posisi berikutnya di path (lebih stabil)
	var next_progress = follower.progress + 0.5
	var next_pos = current_path.curve.sample_baked(next_progress)

	var dir = (next_pos - global_position)
	dir.y = 0

	if dir.length() > 0.01:
		velocity = dir.normalized() * speed
	else:
		velocity = Vector3.ZERO

	if follower.progress_ratio >= 1.0:
		if is_in_class_time:
			start_sitting()
		else:
			start_idle_before_reverse()

func follow_path_reverse(delta):
	if follower == null:
		return

	follower.progress -= speed * delta

	var pos = follower.global_position
	global_position.x = pos.x
	global_position.z = pos.z

	# ✅ Ambil arah mundur dari path
	var prev_progress = max(follower.progress - 0.1, 0.0)
	var prev_pos = current_path.curve.sample_baked(prev_progress)

	var dir = (prev_pos - global_position)
	dir.y = 0

	if dir.length() > 0.01:
		velocity = dir.normalized() * speed
	else:
		velocity = Vector3.ZERO

	if follower.progress_ratio <= 0.0:
		start_idle_before_new_path()

func start_idle_before_reverse():
	current_state = State.IDLE
	velocity = Vector3.ZERO
	idle_timer(true)

func start_idle_before_new_path():
	current_state = State.IDLE
	velocity = Vector3.ZERO
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

	if follower == null:
		return

	var dir: Vector3

	if current_state == State.REVERSE:
		dir = follower.global_transform.basis.z
	else:
		dir = -follower.global_transform.basis.z

	dir.y = 0

	if dir.length() < 0.01:
		return

	var target_y = atan2(dir.x, dir.z)

	target_y += deg_to_rad(rotation_correction_deg)

	rotation.y = lerp_angle(
		rotation.y,
		target_y,
		delta * 10.0
	)

# ====================== SIT (KHUSUS DI KELAS) ======================
func start_sitting():
	# jika sudah duduk, abaikan
	if is_sitting:
		return

	is_sitting = true
	current_state = State.IDLE
	velocity = Vector3.ZERO

	# Atur rotasi duduk (HANYA rotasi Y sesuai seat_rotation_y)
	rotation.y = deg_to_rad(seat_rotation_y)

	# Putar animasi duduk 'Sit' (bukan Sit_2)
	if anim and anim.has_animation("Sit"):
		anim.play("Sit")
	else:
		anim.play("Idle")

func finish_sitting():
	is_sitting = false
	current_state = State.WALK

# ===================== HELPERS ======================
func lerp_angle(from: float, to: float, weight: float) -> float:
	return from + wrapf(to - from, -PI, PI) * weight
