extends CharacterBody3D
@export var mission_id: String
@export var npc_name: String = "NPC"
@export var cooldown_time: float = 30.0
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var interact_area: Area3D = $InteractArea
var player_in_range := false
var available := true

func _ready() -> void:
    add_to_group("mission_npc")
    if anim.has_animation("Scared"):
        anim.play("Scared")
    interact_area.body_entered.connect(_on_body_entered)
    interact_area.body_exited.connect(_on_body_exited)
    if MissionManager.has_signal("mission_ui_updated"):
        MissionManager.mission_ui_updated.connect(_on_mission_ui_update)
    print("DEBUG NPC Scriptwriter: Ready, mission_id =", mission_id)

func _process(_delta):
    if not available:
        return
    if player_in_range and Input.is_action_just_pressed("Interaksi"):
        _trigger_mission()

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("player"):
        player_in_range = true
        if anim.has_animation("Idle"):
            anim.play("Idle")

func _on_body_exited(body: Node) -> void:
    if body.is_in_group("player"):
        player_in_range = false
        if anim.has_animation("Scared"):
            anim.play("Scared")

func _trigger_mission() -> void:
    print("DEBUG NPC Scriptwriter: Interaksi ditekan | current_state:", MissionManager.current_state)
    
    # SAFETY: Jangan panggil report kalau misi belum dimulai
    if MissionManager.current_state == MissionManager.MissionState.REPORT_READY:
        if MissionManager.current_mission.is_empty() or MissionManager.current_mission.get("id", "") != mission_id:
            print("DEBUG NPC Scriptwriter: ERROR - REPORT_READY tapi current_mission kosong atau id salah! Force start mission")
            MissionManager.start_mission_by_id(mission_id)
            await get_tree().create_timer(0.5).timeout  # tunggu sedikit biar mission set
        print("DEBUG NPC Scriptwriter: Panggil complete_mission_report dengan id:", MissionManager.current_mission.get("id", "KOSONG"))
        MissionManager.complete_mission_report(self)
        return
    
    if anim.has_animation("Scared"):
        anim.play("Scared")
    
    if MissionManager.current_state != MissionManager.MissionState.IDLE:
        print("DEBUG NPC Scriptwriter: State bukan IDLE, skip start mission")
        return
    
    print("DEBUG NPC Scriptwriter: Start mission dengan id:", mission_id)
    MissionManager.start_mission_by_id(mission_id)

# === MISSION FINISH LISTENER ===
func _on_mission_ui_update(_desc: String, current: int, total: int) -> void:
    print("DEBUG NPC Scriptwriter: mission_ui_updated | current:", current, "/", total, "| state:", MissionManager.current_state)
    if current >= total and MissionManager.current_state == MissionManager.MissionState.MISSION_OBJECTIVE_COMPLETE:
        print("DEBUG NPC Scriptwriter: Objektif selesai - mulai cooldown")
        _start_cooldown()

func _start_cooldown() -> void:
    hide()
    await get_tree().create_timer(cooldown_time).timeout
    show()
    available = true
    if anim.has_animation("Scared"):
        anim.play("Scared")
