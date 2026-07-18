extends Area3D

signal challenge_triggered

var used := false

func _ready():
    body_entered.connect(_on_enter)

func _on_enter(body):
    if used:
        return
    if body != GoKartMissionController.current_kart:
        return
    if not GoKartMissionController.mission_running:
        return
    used = true
    Engine.time_scale = 0.3
    emit_signal("challenge_triggered")
    GoKartMissionController.trigger_type_challenge()
    FunMissionManager.next_objective()
