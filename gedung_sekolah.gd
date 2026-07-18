extends Node3D

@onready var crowd: AudioStreamPlayer3D = $CrowdSFX
@onready var bell: AudioStreamPlayer3D = $BellSFX

var last_hour := -1
var last_minute := -1

func _ready():
	MusicManager.start_gameplay_music()
	add_to_group("school_ambient")

	if TimeManager.game_time_changed.is_connected(_on_time_changed) == false:
		TimeManager.game_time_changed.connect(_on_time_changed)

	_update_state(
		TimeManager.current_hour,
		TimeManager.current_minute
	)

func _on_time_changed(hour:int, minute:int):

	if hour == last_hour and minute == last_minute:
		return

	last_hour = hour
	last_minute = minute

	_update_state(hour, minute)

func _update_state(hour:int, minute:int):

	#==========================
	# JAM MASUK
	#==========================
	if hour == 7 and minute == 0:
		_ring_bell()

	#==========================
	# ISTIRAHAT
	#==========================
	elif hour == 10 and minute == 0:
		_ring_bell()

	#==========================
	# MASUK LAGI
	#==========================
	elif hour == 11 and minute == 0:
		_ring_bell()

	#==========================
	# PULANG
	#==========================
	elif hour == 14 and minute == 0:
		_ring_bell()

	_update_crowd(hour)

func _update_crowd(hour:int):

	var class_time := (
		(hour >= 7 and hour < 10)
		or
		(hour >= 11 and hour < 14)
	)

	if class_time:

		if crowd.playing:
			crowd.stop()

	else:

		if !crowd.playing:
			crowd.play()

func _ring_bell():

	if bell.playing:
		bell.stop()

	bell.play()
