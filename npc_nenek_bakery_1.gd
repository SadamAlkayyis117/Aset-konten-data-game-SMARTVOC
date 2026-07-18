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
    # Spawn state
    if anim.has_animation("Baking"):
        anim.play("Baking")

    interact_area.body_entered.connect(_on_body_entered)
    interact_area.body_exited.connect(_on_body_exited)

    # listen mission finish
    if MissionManager.has_signal("mission_ui_updated"):
        MissionManager.mission_ui_updated.connect(_on_mission_ui_update)


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
        if anim.has_animation("Baking"):
            anim.play("Baking")


func _trigger_mission() -> void:
    # 📝 LAPORAN SETELAH OBJEKTIF SELESAI
    if MissionManager.current_state == MissionManager.MissionState.REPORT_READY:
        MissionManager.complete_mission_report(self)
        return

    if anim.has_animation("Baking"):
        anim.play("Baking")

    if MissionManager.current_state != MissionManager.MissionState.IDLE:
        return

    MissionManager.start_mission_by_id(mission_id)



# === MISSION FINISH LISTENER ===
func _on_mission_ui_update(_desc: String, current: int, total: int) -> void:
    if current >= total and MissionManager.current_state == MissionManager.MissionState.MISSION_OBJECTIVE_COMPLETE:
        _start_cooldown()


func _start_cooldown() -> void:
    hide()
    await get_tree().create_timer(cooldown_time).timeout
    show()
    available = true

    if anim.has_animation("Baking"):
        anim.play("Baking")
