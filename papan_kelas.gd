extends Node3D

signal word_changed(word_data: Dictionary)

@export var focus_camera_node: NodePath = "Camera3D"
@export var interaction_area: NodePath = "Area3D"
@export var text3d_node: NodePath = "TextAnchor/Label3D"

const PLAYER_GROUP := "Player"

var _words: Array = []
var _word_index: int = 0
var _focus_camera: Camera3D
var _area: Area3D
var _text: Label3D
var _player_camera: Camera3D
var _player_inside := false
var _in_focus := false
var _material_visible := false

func _ready():
	_focus_camera = get_node_or_null(focus_camera_node) as Camera3D
	_area = get_node_or_null(interaction_area) as Area3D
	_text = get_node_or_null(text3d_node) as Label3D

	if _focus_camera: _focus_camera.current = false
	if _text:
		_text.visible = false
		_text.autowrap_mode = TextServer.AUTOWRAP_WORD
		_text.width = 600.0 # Diperlebar agar muat banyak teks

	if _area:
		_area.body_entered.connect(_on_body_enter)
		_area.body_exited.connect(_on_body_exit)

	await _find_player_camera()
	await _connect_teacher()

func _find_player_camera():
	while true:
		var players = get_tree().get_nodes_in_group(PLAYER_GROUP)
		if not players.is_empty():
			_player_camera = _find_cam(players[0])
			if _player_camera: return
		await get_tree().process_frame

func _find_cam(n: Node) -> Camera3D:
	if n is Camera3D: return n
	for c in n.get_children():
		var r = _find_cam(c)
		if r: return r
	return null

func _connect_teacher():
	while true:
		var t = get_tree().get_nodes_in_group("teacher")
		if not t.is_empty():
			if not t[0].teacher_started_teaching.is_connected(_on_teacher_start):
				t[0].teacher_started_teaching.connect(_on_teacher_start)
			if not t[0].teacher_ended_teaching.is_connected(_on_teacher_end):
				t[0].teacher_ended_teaching.connect(_on_teacher_end)
			return
		await get_tree().process_frame

func _on_teacher_start(_class_id: String):
	_material_visible = true
	if _text:
		_text.visible = true
		_load_material()

func _on_teacher_end():
	_material_visible = false
	if _text: _text.visible = false
	if _in_focus: _exit_focus()

func _load_material():
	if not is_instance_valid(ProgressManager): return
	_words = ProgressManager.get_material_full_by_level(ProgressManager.level)
	_word_index = 0
	_show_current_word()

func _show_current_word():
	if _words.is_empty(): 
		if _text: _text.text = "Materi belum siap."
		return
	if _word_index >= _words.size(): _word_index = 0
	var w: Dictionary = _words[_word_index]
	if _text: _text.text = _build_text(w)
	emit_signal("word_changed", w)

func next_word():
	_word_index += 1
	_show_current_word()

# --- BAGIAN PERBAIKAN: MENAMPILKAN SEMUA DATA ---
func _build_text(w: Dictionary) -> String:
	var en = str(w.get("word", w.get("en", "-"))).capitalize()
	var id = str(w.get("meaning", w.get("id", "-"))).capitalize()
	var pos = str(w.get("pos", "-"))
	var syn = ", ".join(w.get("synonym", []))
	var ant = ", ".join(w.get("antonym", []))
	var coll = ", ".join(w.get("collocation", []))
	var prep = ", ".join(w.get("preposition", []))
	var tags = ", ".join(w.get("tags", []))
	
	var txt = "WORD: %s\n" % en
	txt += "Arti: %s (%s)\n" % [id, pos]
	if syn != "": txt += "Sinonim: %s\n" % syn
	if ant != "": txt += "Antonim: %s\n" % ant
	if coll != "": txt += "Frasa: %s\n" % coll
	if prep != "": txt += "Preposisi: %s\n" % prep
	if tags != "": txt += "Kategori: %s" % tags
	return txt

# INTERAKSI CAMERA (TETAP SAMA)
func _on_body_enter(b: Node3D): if b.is_in_group(PLAYER_GROUP): _player_inside = true
func _on_body_exit(b: Node3D):
	if b.is_in_group(PLAYER_GROUP):
		_player_inside = false
		if _in_focus: _exit_focus()

func _input(event: InputEvent):
	if event.is_action_pressed("Interaksi") and _player_inside:
		if _in_focus: _exit_focus()
		else: _enter_focus()

func _enter_focus():
	if _player_camera and _focus_camera:
		_in_focus = true
		_player_camera.current = false
		_focus_camera.current = true

func _exit_focus():
	if _player_camera and _focus_camera:
		_in_focus = false
		_focus_camera.current = false
		_player_camera.current = true
