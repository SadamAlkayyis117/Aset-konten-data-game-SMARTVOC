extends Node

#=========================================
# UI SFX
#=========================================

const BUTTON_CLICK := preload("res://SFXClick.wav")
const BUTTON_HOVER := preload("res://SFXHover.wav")

var player : AudioStreamPlayer

func _ready():
	player = AudioStreamPlayer.new()
	player.bus = "SFX"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)

func play(stream: AudioStream):
	if stream == null:
		return

	if SettingManager.audio_settings.sfx_mute:
		return

	player.stream = stream
	player.play()

func play_click():
	play(BUTTON_CLICK)

func play_hover():
	play(BUTTON_HOVER)
