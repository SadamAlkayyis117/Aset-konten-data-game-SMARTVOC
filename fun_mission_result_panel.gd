extends CanvasLayer

signal result_closed

@onready var score_label = $ResultPanel/LabelScore
@onready var rating_label = $ResultPanel/LabelRating
@onready var button = $ResultPanel/ButtonContinue

var result_data : FunMissionResultData

func _ready():
    button.pressed.connect(_close)

func setup(data : FunMissionResultData):
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    result_data = data
    score_label.text = "Score: %d" % data.score
    rating_label.text = data.rank
    PlayerData.add_money(data.reward_money)
    if data.reward_xp > 0:
        ProgressManager.add_xp(data.reward_xp)

func _close():
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    result_closed.emit()
    queue_free()
