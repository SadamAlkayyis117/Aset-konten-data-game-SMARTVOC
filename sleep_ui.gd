extends CanvasLayer

@onready var spin_hour = $Panel/HboxHour/SpinBoxHour
@onready var spin_minute = $Panel/HboxMinute/SpinBoxMinute

var current_player = null
var current_bed = null

func _ready():

	visible = false

	$Panel/HBoxButton/ButtonConfirm.pressed.connect(_on_confirm)
	$Panel/HBoxButton/ButtonCancel.pressed.connect(_on_cancel)

	$Panel/ButtonMorning.pressed.connect(_sleep_until_morning)

func open_sleep_menu(player, bed):

	current_player = player
	current_bed = bed

	spin_hour.value = 1
	spin_minute.value = 0

	visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_confirm():

	if current_player == null:
		return

	current_player.sleep_point = current_bed.sleep_point
	current_player.wake_point = current_bed.wake_point

	current_player.start_sleep(
		int(spin_hour.value),
		int(spin_minute.value)
	)

	visible = false

func _sleep_until_morning():

	if current_player == null:
		return

	var current_hour = TimeManager.current_hour

	var sleep_hours = 6 - current_hour

	if sleep_hours <= 0:
		sleep_hours += 24

	current_player.sleep_point = current_bed.sleep_point
	current_player.wake_point = current_bed.wake_point

	current_player.start_sleep(sleep_hours)

	visible = false

func _on_cancel():

	visible = false
