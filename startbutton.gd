extends Area3D

var player_inside := false
var player_ref = null

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    set_process_input(true)

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_inside = true
        player_ref = body
        print("PLAYER MASUK AREA START")

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_inside = false
        player_ref = null
        print("PLAYER KELUAR AREA START")

func _input(event):
    if not player_inside:
        return
    if not event.is_action_pressed("Interaksi"):
        return
    if FunMissionManager.objective_index < 2:
        print("BELUM BOLEH START - HARUS DIALOG DULU")
        return
    print("START BUTTON PRESSED")
    var controller = get_tree().get_first_node_in_group("archery_controller")
    if controller:
        controller.start_mission(player_ref)
    else:
        print("ERROR: archery_controller tidak ditemukan")
