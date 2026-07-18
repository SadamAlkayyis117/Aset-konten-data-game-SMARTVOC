extends Area3D

signal stop_state_changed(is_red: bool)

var is_red: bool = false

func _ready():
    add_to_group("stop_zone")
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)
    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited)

# Dipanggil dari TrafficLight
func set_red(new_state: bool):
    if new_state == is_red:
        return
    is_red = new_state
    emit_signal("stop_state_changed", is_red)

func _on_body_entered(body):
    if not body.is_in_group("Vehicle"):
        return

    var path_runner: Node = null
    if body.has_node("PathFollow3D"):
        path_runner = body.get_node("PathFollow3D")
    elif body.has_method("notify_stop_zone"):
        path_runner = body
    else:
        return

    path_runner.notify_stop_zone(is_red)

    if not stop_state_changed.is_connected(path_runner.notify_stop_zone):
        stop_state_changed.connect(path_runner.notify_stop_zone)

func _on_body_exited(body):
    if not body.is_in_group("Vehicle"):
        return

    var path_runner: Node = null
    if body.has_node("PathFollow3D"):
        path_runner = body.get_node("PathFollow3D")
    elif body.has_method("notify_stop_zone"):
        path_runner = body
    else:
        return

    path_runner.notify_stop_zone(false)

    if stop_state_changed.is_connected(path_runner.notify_stop_zone):
        stop_state_changed.disconnect(path_runner.notify_stop_zone)
