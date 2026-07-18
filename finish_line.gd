extends Area3D

func _ready():
    body_entered.connect(_on_enter)

func _on_enter(body):

    if not GoKartMissionController.mission_running:
        return

    if body != GoKartMissionController.current_kart:
        return

    var timer = get_tree().get_first_node_in_group("mission_timer")
    if timer:
        timer.stop_timer()

    print("🏁 FINISH LINE - Time:", GoKartMissionController.mission_time)

    GoKartMissionController.finish_mission()
