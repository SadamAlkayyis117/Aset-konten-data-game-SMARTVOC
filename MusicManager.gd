extends Node

const OPENING_THEME := preload("res://Smartvoc Opening.wav")
const GAMEPLAY_THEME_1 := preload("res://Smartvoc Main Theme.wav")
const GAMEPLAY_THEME_2 := preload("res://Smartvoc Second Theme.wav")

@export var gameplay_volume_offset := -6.0
@export_range(0.1, 5.0)
var fade_duration := 1.5

var bgm_player: AudioStreamPlayer
var current_stream: AudioStream
var fade_tween: Tween
var is_gameplay_mode := false


func _ready():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Music"
	bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(bgm_player)
	SettingManager.apply_music_volume(
		SettingManager.audio_settings.music_volume
	)
	SettingManager.set_music_mute(
		SettingManager.audio_settings.music_mute
	)
	call_deferred("_connect_time_manager")


#==================================================
# PUBLIC
#==================================================

func _update_bus(stream: AudioStream):

	if stream == OPENING_THEME:
		bgm_player.bus = "Opening"
	else:
		bgm_player.bus = "Music"

func _on_game_time_changed(hour: int, minute: int):
	if !is_gameplay_mode:
		return

	_update_gameplay_theme()

func _connect_time_manager():
	if has_node("/root/TimeManager"):
		TimeManager.game_time_changed.connect(_on_game_time_changed)

func start_gameplay_music():
	is_gameplay_mode = true
	_update_gameplay_theme()

func stop_gameplay_music():
	is_gameplay_mode = false

func _update_gameplay_theme():

	var hour := TimeManager.current_hour

	# Siang 06:00 - 17:59
	if hour >= 6 and hour < 18:

		if current_stream != GAMEPLAY_THEME_1:
			fade_to(GAMEPLAY_THEME_1)

	# Malam 18:00 - 05:59
	else:

		if current_stream != GAMEPLAY_THEME_2:
			fade_to(GAMEPLAY_THEME_2)

func _get_target_volume(stream: AudioStream) -> float:
	if stream == GAMEPLAY_THEME_1 or stream == GAMEPLAY_THEME_2:
		return gameplay_volume_offset

	return 0.0

func play_opening():
	play(OPENING_THEME)


func play(stream: AudioStream):
	if stream == null:
		return

	# Jangan restart lagu yang sama
	if bgm_player.playing and current_stream == stream:
		return

	_stop_tween()

	current_stream = stream

	_update_bus(stream)

	bgm_player.stream = stream
	bgm_player.volume_db = _get_target_volume(stream)
	bgm_player.play()


func stop():
	_stop_tween()

	bgm_player.stop()
	current_stream = null


func fade_out():
	if !bgm_player.playing:
		return

	_stop_tween()

	fade_tween = create_tween()

	fade_tween.tween_property(
		bgm_player,
		"volume_db",
		-40.0,
		fade_duration
	)

	fade_tween.finished.connect(func():
		bgm_player.stop()
		current_stream = null
	)


func fade_to(stream: AudioStream):
	if stream == null:
		return

	if bgm_player.playing and current_stream == stream:
		return

	_stop_tween()

	# ==========================
	# Kalau belum ada lagu yang diputar
	# ==========================
	if !bgm_player.playing:

		current_stream = stream

		_update_bus(stream)

		bgm_player.stream = stream
		bgm_player.volume_db = -40
		bgm_player.play()

		fade_tween = create_tween()

		fade_tween.tween_property(
			bgm_player,
			"volume_db",
			_get_target_volume(stream),
			fade_duration
		)

		return

	# ==========================
	# Fade Out lagu lama
	# ==========================
	fade_tween = create_tween()

	fade_tween.tween_property(
		bgm_player,
		"volume_db",
		-40.0,
		fade_duration
	)

	fade_tween.finished.connect(func():

		bgm_player.stop()

		current_stream = stream

		_update_bus(stream)

		bgm_player.stream = stream
		bgm_player.volume_db = -40

		bgm_player.play()

		fade_tween = create_tween()

		fade_tween.tween_property(
			bgm_player,
			"volume_db",
			_get_target_volume(stream),
			fade_duration
		)
	)


func is_playing(stream: AudioStream) -> bool:
	return bgm_player.playing and current_stream == stream


#==================================================
# PRIVATE
#==================================================

func _stop_tween():
	if fade_tween:
		fade_tween.kill()
		fade_tween = null
