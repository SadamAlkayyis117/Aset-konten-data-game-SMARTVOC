extends CanvasLayer

@onready var timer_label = $Speedometer/LabelTimer
@onready var speed_label = $Speedometer/LabelSpeed
@onready var speed_bar = $Speedometer/TextureProgressBar

var timer_ref = null
var kart_ref = null

func _ready():
    add_to_group("gokart_ui")
    visible = false

func setup(timer, kart):
    timer_ref = timer
    kart_ref = kart
    visible = true

func hide_ui():
    visible = false

func _process(delta):
    if timer_ref:
        var t = timer_ref.time
        var minutes = int(t) / 60
        var seconds = int(t) % 60
        timer_label.text = "%02d:%02d" % [minutes, seconds]

    if kart_ref:
        var spd = abs(kart_ref.speed)
        var max_display_speed = 120.0
        var ratio = spd / max_display_speed
        ratio = clamp(ratio, 0.0, 1.0)
        speed_label.text = str(int(spd))
        speed_bar.value = ratio * 100.0
