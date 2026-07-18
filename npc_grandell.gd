extends CharacterBody3D

enum NPCMode {
    WORLD_NPC,
    MAP_NPC
}

@export var npc_mode : NPCMode = NPCMode.WORLD_NPC
@export var gokart_scene: String = "res://MapGoKart.tscn"

@onready var interact_area = $InteractArea
@onready var anim = $AnimationPlayer

var player_in_range := false
var mission_active := false
var player_finished := false  
var dialog_active := false
var cooldown_active := false
var cooldown_time := 300.0
var cooldown_timer := 0.0

var dialog_scene = preload("res://fun_mission_dialog.tscn")
@export var mission_id : String = "go_kart_race"
@export var intro_2_dialog_id : String = "kart_intro_2"
@export var final_dialog_id : String = "kart_final"
@export var gameplay_scene : String = "res://MapGoKart.tscn"

func _ready():
    interact_area.body_entered.connect(_enter)
    interact_area.body_exited.connect(_exit)
    GoKartMissionController.mission_started.connect(_on_mission_started)
    GoKartMissionController.mission_finished.connect(_on_mission_finished)
    await get_tree().process_frame
    _check_player_in_area()
    # 🔥 cek cooldown saat spawn
    if npc_mode == NPCMode.WORLD_NPC and FunMissionManager.mission_cooldown > 0:
        start_cooldown_from_manager()
        
func _process(delta):
    if cooldown_active:
        cooldown_timer -= delta
        if cooldown_timer <= 0:
            cooldown_active = false
            visible = true
            print("NPC respawn")
        return
    if dialog_active:
        return
    if _is_dialog_open():
        return
    if player_in_range and Input.is_action_just_pressed("Interaksi"):
        if npc_mode == NPCMode.WORLD_NPC:
            start_dialog_1()
        elif npc_mode == NPCMode.MAP_NPC:
            if FunMissionManager.objective_index == 1:
                start_dialog_2()
            elif player_finished and FunMissionManager.current_state != FunMissionManager.FunMissionState.MISSION_COMPLETE:
                start_final_dialog()
                
                
func start_cooldown_from_manager():

    cooldown_active = true
    cooldown_timer = FunMissionManager.mission_cooldown

    visible = false

    print("NPC hidden because cooldown:", cooldown_timer)
    

func _check_player_in_area():
    for body in interact_area.get_overlapping_bodies():
        if body.is_in_group("player"):
            player_in_range = true

func _is_dialog_open() -> bool:
    return dialog_active

func _enter(body):
    if body.is_in_group("player"):
        player_in_range = true
        anim.play("Talk")

func _exit(body):
    if body.is_in_group("player"):
        player_in_range = false
        anim.play("Idle")

func start_dialog_1():
    if dialog_active:
        return
    if FunMissionManager.current_state != FunMissionManager.FunMissionState.IDLE:
        return
    dialog_active = true
    FunMissionManager.start_fun_mission_by_id(mission_id)

func _on_dialog_1_finished():
    dialog_active = false
    await get_tree().process_frame
    load_gokart_scene()

func load_gokart_scene():
    get_tree().change_scene_to_file(gokart_scene)

func start_dialog_2():

    dialog_active = true

    var dialog = dialog_scene.instantiate()
    dialog.dialog_id = intro_2_dialog_id
    dialog.dialog_finished.connect(_on_dialog_2_finished)

    get_tree().root.add_child(dialog)

func _on_dialog_2_finished():
    dialog_active = false
    FunMissionManager.next_objective()   # ✅ TAMBAHKAN
    await get_tree().process_frame

func start_final_dialog():
    dialog_active = true
    var dialog = dialog_scene.instantiate()
    dialog.dialog_id = final_dialog_id
    dialog.dialog_finished.connect(_on_final_dialog_finished)
    get_tree().root.add_child(dialog)

func _on_final_dialog_finished():
    dialog_active = false
    player_finished = false

    FunMissionManager.change_state(
        FunMissionManager.FunMissionState.RESULT_SCREEN
    )
    await get_tree().process_frame

func _on_mission_started():
    mission_active = true

func _on_mission_finished():
    mission_active = false
    player_finished = true

func start_cooldown():
    cooldown_active = true
    cooldown_timer = cooldown_time
    visible = false
    set_physics_process(true)
    print("NPC cooldown started (5 minutes)")
