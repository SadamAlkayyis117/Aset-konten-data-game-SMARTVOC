extends CharacterBody3D

# =========================================================
# SIGNAL
# =========================================================
signal teacher_started_teaching(class_id: String)
signal teacher_ended_teaching

# =========================================================
# ENUM
# =========================================================
enum State { WALK, IDLE, REVERSE }

# =========================================================
# PATH INPUT
# =========================================================
@export var path_datang_A: NodePath
@export var path_datang_B: NodePath

@export var path_teach_A_1: NodePath
@export var path_teach_A_2: NodePath
@export var path_teach_A_3: NodePath
@export var teach1_path: NodePath
@export var teach2_path: NodePath
@export var teach3_path: NodePath
@export var path_teach_B_1: NodePath
@export var path_teach_B_2: NodePath
@export var path_teach_B_3: NodePath
@onready var teach1: Marker3D = get_node_or_null(teach1_path)
@onready var teach2: Marker3D = get_node_or_null(teach2_path)
@onready var teach3: Marker3D = get_node_or_null(teach3_path)

# =========================================================
# INTERACT UI
# =========================================================
@export var interaction_area: NodePath
var _player_in_range := false

@export var dialog_guru_scene: PackedScene
var _active_dialog: Node = null

# =========================================================
# DIALOG UI
# =========================================================
@export var dialog_ui: NodePath
var _dialog_ui: CanvasLayer 

# =========================================================
# SETTINGS
# =========================================================
@export var speed: float = 15.0
@export var idle_duration: float = 1.5
@export var rotation_correction_deg: float = 90.0
@export var teaching_pause_seconds: float = 75.0 

# =========================================================
# INTERNAL STATE
# =========================================================
var current_state: State = State.WALK
var current_path: Path3D = null
var follower: PathFollow3D = null

var _tm_connected: bool = false
var is_in_class_time: bool = false
var current_class: String = ""
var _teaching_loop: bool = false
var _current_teach_path_nodepath: NodePath = NodePath()
var _last_arrive_path: NodePath = NodePath()
var _is_playing_teach_anim: bool = false

# =========================================================
# OBJECTS
# =========================================================
@onready var anim: AnimationPlayer = $AnimationPlayer

@export var book_node: NodePath
@export var pointer_node: NodePath
var obj_book: Node3D = null
var obj_pointer: Node3D = null

# =========================================================
# WHITEBOARD & DIALOG SEGMENTATION
# =========================================================
@export var whiteboard_node: NodePath
var _whiteboard: Node = null

# Sistem Antrean Dialog agar bisa muncul bergantian
var _dialogue_queue: Array[String] = []
var _dialogue_timer: Timer

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	var area = get_node_or_null(interaction_area)
	if area:
		area.body_entered.connect(_on_body_entered)
		area.body_exited.connect(_on_body_exited)

	randomize()
	add_to_group("teacher")

	obj_book = get_node_or_null(book_node) as Node3D
	obj_pointer = get_node_or_null(pointer_node) as Node3D
	_hide_all_behavior_objects()

	if dialog_ui != NodePath():
		_dialog_ui = get_node_or_null(dialog_ui) as CanvasLayer

	if whiteboard_node != NodePath():
		_whiteboard = get_node_or_null(whiteboard_node)
		if _whiteboard and _whiteboard.has_signal("word_changed"):
			if not _whiteboard.word_changed.is_connected(_on_word_changed):
				_whiteboard.word_changed.connect(_on_word_changed)

	# Setup timer internal untuk pergantian dialog otomatis
	_dialogue_timer = Timer.new()
	_dialogue_timer.one_shot = true
	add_child(_dialogue_timer)
	_dialogue_timer.timeout.connect(_show_next_dialogue_segment)

	hide()
	_schedule_connect_time_manager()
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		_player_in_range = false

func _open_teacher_dialog():
	if dialog_guru_scene == null: return
	if _active_dialog != null: return

	_active_dialog = dialog_guru_scene.instantiate()
	get_tree().root.add_child(_active_dialog)
	_active_dialog.open(self)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_teacher_dialog():
	if _active_dialog:
		_active_dialog.queue_free()
		_active_dialog = null

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
 # Atau MOUSE_MODE_HIDDEN tergantung game kamu

# =========================================================
# WORD FROM WHITEBOARD → DIALOG SEGMENTATION
# =========================================================
func _on_word_changed(w: Dictionary):
	if not is_in_class_time:
		return
	
	# Reset dan buat antrean dialog baru
	_dialogue_queue = _generate_segmented_dialogue(w)
	_show_next_dialogue_segment()

func _generate_segmented_dialogue(w: Dictionary) -> Array[String]:
	var queue: Array[String] = []
	var en: String = str(w.get("word", w.get("en", ""))).capitalize()
	var id: String = str(w.get("meaning", w.get("id", "")))
	var pos: String = str(w.get("pos", w.get("part_of_speech", "")))
	var tags: Array = w.get("tags", [])
	var syns: Array = w.get("synonym", [])
	var ants: Array = w.get("antonym", [])
	var colls: Array = w.get("collocation", [])

	# SEGMENT 1: Kosakata, Arti, dan Jenis Kata
	var s1 = "Anak-anak, kata '%s' artinya '%s'. " % [en, id]
	match pos:
		"noun": s1 += "Kata ini termasuk **Kata Benda** (Noun) untuk menamai objek atau ide."
		"verb": s1 += "Ini adalah **Kata Kerja** (Verb) yang menyatakan sebuah aksi atau tindakan."
		"adjective": s1 += "Ini **Kata Sifat** (Adjective), digunakan untuk menjelaskan ciri dari sebuah benda."
		_: s1 += "Ini adalah kosakata dasar yang penting untuk kalian pahami."
	queue.append(s1)

	# SEGMENT 2: Sinonim & Antonim (Jika ada)
	if not syns.is_empty() or not ants.is_empty():
		var s2 = "Nah, kalian juga harus tahu. "
		if not syns.is_empty():
			s2 += "Sinonim dari '%s' adalah: %s. " % [en, ", ".join(syns)]
		if not ants.is_empty():
			s2 += "Sedangkan antonim atau lawan katanya yaitu: %s." % [", ".join(ants)]
		queue.append(s2)

	# SEGMENT 3: Penggunaan & Collocation
	if not colls.is_empty():
		queue.append("Dalam kalimat, kita sering menggunakannya seperti ini: " + ", ".join(colls) + ".")

	# SEGMENT 4: Fun Fact & Tags
	var s4 = ""
	if tags.has("food"): s4 = "Karena berkaitan dengan makanan, kata ini sering muncul di dapur atau restoran! "
	elif tags.has("animal"): s4 = "Kata ini berhubungan dengan dunia hewan dan alam sekitar. "
	elif tags.has("action"): s4 = "Gunakan kata ini saat kalian menceritakan aktivitas sehari-hari."
	
	s4 += "Coba diingat baik-baik ya, kosakata ini akan muncul di latihan nanti!"
	queue.append(s4)

	return queue

func _show_next_dialogue_segment():
	if _dialogue_queue.is_empty() or not is_in_class_time:
		return
		
	var current_text = _dialogue_queue.pop_front()
	_show_teacher_dialog(current_text)
	
	# Berikan waktu jeda sebelum segmen berikutnya muncul (misal 12 detik)
	# Anda bisa mengatur ini agar pas dengan teaching_pause_seconds
	_dialogue_timer.start(15.0) 

func _show_teacher_dialog(text: String):
	if _dialog_ui == null: return
	if _dialog_ui.has_method("show_dialog"):
		_dialog_ui.show_dialog("Guru: " + text)

# =========================================================
# TIME MANAGER
# =========================================================
func _schedule_connect_time_manager():
	await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout
	_connect_time_manager()

func _connect_time_manager():
	if _tm_connected or TimeManager == null:
		_schedule_connect_time_manager()
		return
	if not TimeManager.game_time_changed.is_connected(_on_time_changed):
		TimeManager.game_time_changed.connect(_on_time_changed)
	_tm_connected = true
	_check_schedule_polling(TimeManager.current_hour, TimeManager.current_minute)

func _on_time_changed(h: int, m: int):
	_check_schedule_polling(h, m)

func _check_schedule_polling(h: int, _m: int):
	var in_A: bool = (h >= 7 and h < 10)
	var in_B: bool = (h >= 11 and h < 14)
	if in_A and current_class != "A": _enter_class("A")
	elif in_B and current_class != "B": _enter_class("B")
	elif not in_A and not in_B and current_class != "": _exit_all_classes()

# =========================================================
# CLASS FLOW
# =========================================================
func _enter_class(class_id: String):

	current_class = class_id
	is_in_class_time = true
	show()

	var minute_of_day = TimeManager.current_hour * 60 + TimeManager.current_minute

	var lesson_start := 420 # 07:00

	if class_id == "B":
		lesson_start = 660 # 11:00

	var elapsed = minute_of_day - lesson_start

	if elapsed >= 2:
		emit_signal("teacher_started_teaching", current_class)
		_start_teaching_loop()
		return

	var arrive = path_datang_A if class_id == "A" else path_datang_B

	_last_arrive_path = arrive

	_start_path(arrive)

func _exit_all_classes():
	is_in_class_time = false
	current_class = ""
	_dialogue_queue.clear()
	_dialogue_timer.stop()
	emit_signal("teacher_ended_teaching")
	if _dialog_ui and _dialog_ui.has_method("hide_dialog"): _dialog_ui.hide_dialog()
	if _last_arrive_path != NodePath(): _start_path(_last_arrive_path)

# =========================================================
# PATH SYSTEM (UTUH)
# =========================================================
func _start_path(path_np: NodePath):
	var p: Path3D = get_node_or_null(path_np) as Path3D
	if not p: return
	if follower: follower.queue_free()
	follower = PathFollow3D.new()
	follower.loop = false
	p.add_child(follower)
	current_path = p
	current_state = State.WALK

func _process(delta: float):
	if _is_playing_teach_anim: return
	state_machine(delta)
	rotate_to_velocity(delta)

func state_machine(delta: float):
	match current_state:
		State.WALK:
			anim.play("Walk")
			follow_path_forward(delta)
		State.IDLE:
			anim.play("Idle")
		State.REVERSE:
			anim.play("Walk")
			follow_path_reverse(delta)

func follow_path_forward(delta: float):
	if follower == null: return
	follower.progress += speed * delta
	global_position = follower.global_position
	if follower.progress_ratio >= 1.0: _on_path_reached_end()

func follow_path_reverse(delta: float):
	if follower == null: return
	follower.progress -= speed * delta
	global_position = follower.global_position
	if follower.progress_ratio <= 0.0: _on_path_reached_start()

func _on_path_reached_end():
	var arrival_node = get_node_or_null(_last_arrive_path)
	if is_in_class_time and current_path == arrival_node:
		emit_signal("teacher_started_teaching", current_class)
		_start_teaching_loop()
		return
	if _teaching_loop:
		await _play_teach_animation_for_path(_current_teach_path_nodepath)
		current_state = State.REVERSE

func _on_path_reached_start():
	if _teaching_loop: _pick_and_start_teach_path()

# =========================================================
# TEACH LOOP
# =========================================================
func _start_teaching_loop():
	_teaching_loop = true
	_pick_and_start_teach_path()

func _pick_and_start_teach_path():
	var paths: Array[NodePath] = []
	if current_class == "A": paths = [path_teach_A_1, path_teach_A_2, path_teach_A_3]
	else: paths = [path_teach_B_1, path_teach_B_2, path_teach_B_3]
	var valid_paths: Array[NodePath] = []
	for p in paths: if p != NodePath(): valid_paths.append(p)
	if valid_paths.is_empty(): return
	_current_teach_path_nodepath = valid_paths.pick_random()
	_start_path(_current_teach_path_nodepath)

func _play_teach_animation_for_path(_p: NodePath):

	_is_playing_teach_anim = true

	var marker := _get_random_teach_marker()

	if marker:
		rotation.y = marker.global_rotation.y + deg_to_rad(rotation_correction_deg)

	var teach_anims = [
		"Teach",
		"Teach_2",
		"Teach_3"
	]

	anim.play(teach_anims.pick_random())

	if _whiteboard and _whiteboard.has_method("next_word"):
		_whiteboard.call("next_word")

	await get_tree().create_timer(teaching_pause_seconds).timeout

	_dialogue_timer.stop()
	_dialogue_queue.clear()

	if _dialog_ui and _dialog_ui.has_method("hide_dialog"):
		_dialog_ui.hide_dialog()

	_is_playing_teach_anim = false
	
func _play_teach_animation():
	var marker := _get_random_teach_marker()

	if marker:
		rotation.y = marker.global_rotation.y + deg_to_rad(rotation_correction_deg)

	var anims = [
		"Teach",
		"Teach2",
		"Teach3"
	]

	anim.play(anims.pick_random())

	await get_tree().create_timer(75.0).timeout

func _get_random_teach_marker() -> Marker3D:
	var markers := []

	if teach1:
		markers.append(teach1)

	if teach2:
		markers.append(teach2)

	if teach3:
		markers.append(teach3)

	if markers.is_empty():
		return null

	return markers.pick_random()

# =========================================================
# UTIL (UTUH)
# =========================================================
func rotate_to_velocity(delta: float):
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
		delta * 8.0
	)

func _hide_all_behavior_objects():
	if obj_book: obj_book.visible = false
	if obj_pointer: obj_pointer.visible = false
	
# =========================================================
# INPUT INTERACTION
# =========================================================
func _input(event):
	if event.is_action_pressed("Interaksi") and _player_in_range:
		if _active_dialog == null:
			_open_teacher_dialog()
		else:
			_close_teacher_dialog()
