extends Node

signal fun_mission_started
signal fun_mission_finished
signal fun_mission_ui_update(text:String)

enum FunMissionState {
    IDLE,
    DIALOG_INTRO,
    WAITING_FINAL_CONFIRM,  # baru: tunggu dialog terakhir selesai
    MISSION_RUNNING,
    MISSION_COMPLETE,
    RESULT_SCREEN
}

var mission_cooldown := 0.0
var cooldown_duration := 300.0
var objective_index := 0
var current_state : FunMissionState = FunMissionState.IDLE
var current_mission : Dictionary = {}
var time_elapsed : float = 0
var mission_result : FunMissionResultData

var mission_database_path := "res://FunMissionManager.json"
var dialog_scene := preload("res://fun_mission_dialog.tscn")
var label_scene := preload("res://funmissionlabel.tscn")
var result_scene := preload("res://fun_mission_result_panel.tscn")
var label_instance : Control = null

func start_fun_mission_by_id(id:String):
    if current_state != FunMissionState.IDLE:
        return
    var mission = _load_mission_from_db(id)
    if mission.is_empty():
        push_error("FunMission not found: " + id)
        return
    current_mission = mission
    time_elapsed = 0
    _ensure_label()   # ✅ TAMBAHKAN DI SINI
    change_state(FunMissionState.DIALOG_INTRO)
    objective_index = 0

func _process(delta):

    if mission_cooldown > 0:
        mission_cooldown -= delta

func _load_mission_from_db(id:String) -> Dictionary:
    if not FileAccess.file_exists(mission_database_path):
        push_error("FunMission DB not found")
        return {}
    var file = FileAccess.open(mission_database_path, FileAccess.READ)
    var json = JSON.parse_string(file.get_as_text())
    file.close()
    for m in json.get("fun_missions", []):
        if m.get("id","") == id:
            return m
    return {}

func update_objective():
    var objectives = current_mission.get("objectives", [])
    if objective_index < objectives.size():
        emit_signal("fun_mission_ui_update", objectives[objective_index])

func next_objective():
    var objectives = current_mission.get("objectives", [])
    objective_index += 1
    print("OBJECTIVE INDEX:", objective_index)
    if objective_index >= objectives.size():
        return
    print("OBJECTIVE TEXT:", objectives[objective_index])
    print("NEXT OBJECTIVE CALLED FROM:")
    print_stack()
    emit_signal("fun_mission_ui_update", objectives[objective_index])
    
    
func change_state(new_state):
    if current_state == new_state:
        return

    current_state = new_state

    match current_state:

        FunMissionState.DIALOG_INTRO:
            _start_intro_dialog()

        FunMissionState.WAITING_FINAL_CONFIRM:
            pass

        FunMissionState.MISSION_RUNNING:
            _start_gameplay()

        FunMissionState.MISSION_COMPLETE:
            _finish_gameplay()

        FunMissionState.RESULT_SCREEN:
            _show_result()

func _start_intro_dialog():
    var dialog = dialog_scene.instantiate()
    dialog.dialog_id = current_mission.get("intro_dialog","")
    dialog.dialog_finished.connect(_on_intro_dialog_finished)
    get_tree().root.add_child(dialog)

func _on_intro_dialog_finished():
    next_objective()

    var scene_path = current_mission.get("gameplay_scene","")
    if scene_path != "":
        get_tree().change_scene_to_file(scene_path)

func _start_gameplay():
    emit_signal("fun_mission_started")
    update_objective()

func finish_gameplay(result : FunMissionResultData):
    mission_result = result
    change_state(FunMissionState.WAITING_FINAL_CONFIRM)

func _finish_gameplay():
    change_state(FunMissionState.RESULT_SCREEN)

func start_final_dialog():
    var dialog = dialog_scene.instantiate()
    dialog.dialog_id = current_mission.get("final_dialog","")
    dialog.dialog_finished.connect(_on_final_dialog_finished)
    get_tree().root.add_child(dialog)

func _on_final_dialog_finished():
    change_state(FunMissionState.RESULT_SCREEN)

func _show_result():
    if label_instance:
        label_instance.queue_free()
        label_instance = null
    var result = result_scene.instantiate()
    get_tree().root.add_child(result)
    await get_tree().process_frame
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    result.setup(mission_result)
    result.result_closed.connect(_on_result_closed)

func _on_result_closed():
    mission_cooldown = cooldown_duration
    current_mission = {}
    change_state(FunMissionState.IDLE)
    emit_signal("fun_mission_finished")
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player.set_input_locked(false)
    var gm = get_node_or_null("/root/GM")
    if gm:
        gm.mission_ui_open = false
    get_tree().change_scene_to_file("res://world.tscn")

func _ensure_label():
    if label_instance and is_instance_valid(label_instance):
        return

    label_instance = label_scene.instantiate()
    get_tree().root.add_child(label_instance)

    update_objective() # ambil dari objectives array
