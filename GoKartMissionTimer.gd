extends Node

signal timer_started
signal timer_stopped
signal result_ready(rank, time)

var running := false
var time := 0.0

@export var perfect_time := 116.0
@export var best_time := 127.0

func _ready():
    add_to_group("mission_timer")

func start_timer():

    running = true
    time = 0.0

    emit_signal("timer_started")


func stop_timer():

    running = false

    var rank = calculate_rank()

    emit_signal("result_ready", rank, time)


func _process(delta):

    if not running:
        return

    time += delta


func calculate_rank():

    if time <= perfect_time:
        return "PERFECT"

    if time <= best_time:
        return "BEST"

    return "GOOD"
