extends Node

signal result_ready(rank, time)

var running := false
var time := 0.0
var total_time := 0.0

@export var total_minutes := 10.0

func _ready():
    add_to_group("archery_timer")
    set_process(true)

func start_timer():
    running = true
    total_time = total_minutes * 60.0
    time = total_time

func _process(delta):
    if not running:
        return

    time -= delta

    if time <= 0:
        time = 0
        stop_timer()

func stop_timer():
    running = false

    emit_signal("result_ready", "TIME_UP", total_time - time)
