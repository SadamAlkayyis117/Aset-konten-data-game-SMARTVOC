extends Node3D

@export var green_duration: float = 30.0
@export var yellow_duration: float = 5.0

@onready var light_A = $"../Rambu A"
@onready var light_B = $"../Rambu B"
@onready var timer = $Timer

enum LightState { RED, YELLOW, GREEN }
enum Phase { A_GREEN, A_YELLOW, B_GREEN, B_YELLOW }

var current_phase = Phase.A_GREEN

func _ready():
    timer.timeout.connect(_next_phase)
    _apply_phase(current_phase)
    timer.start(green_duration)

func _next_phase():
    match current_phase:
        Phase.A_GREEN:
            current_phase = Phase.A_YELLOW
            _apply_phase(current_phase)
            timer.start(yellow_duration)
        Phase.A_YELLOW:
            current_phase = Phase.B_GREEN
            _apply_phase(current_phase)
            timer.start(green_duration)
        Phase.B_GREEN:
            current_phase = Phase.B_YELLOW
            _apply_phase(current_phase)
            timer.start(yellow_duration)
        Phase.B_YELLOW:
            current_phase = Phase.A_GREEN
            _apply_phase(current_phase)
            timer.start(green_duration)

func _apply_phase(phase):
    if not (light_A and light_B):
        push_error("Rambu A/B tidak valid di scene tree")
        timer.stop()
        return

    match phase:
        Phase.A_GREEN:
            light_A.set_state(LightState.GREEN)
            light_B.set_state(LightState.RED)
        Phase.A_YELLOW:
            light_A.set_state(LightState.YELLOW)
            light_B.set_state(LightState.RED)
        Phase.B_GREEN:
            light_A.set_state(LightState.RED)
            light_B.set_state(LightState.GREEN)
        Phase.B_YELLOW:
            light_A.set_state(LightState.RED)
            light_B.set_state(LightState.YELLOW)
