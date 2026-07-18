extends Node3D

@onready var anim = $AnimationPlayer

var can_start := false

func _ready():
	GM.is_opening = true # Set langsung lewat Autoload
	MusicManager.play_opening()
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Sembunyikan kursor jika tidak ingin mengganggu cinematic, 
	# tapi di kasusmu kamu ingin mouse click bisa skip, jadi VISIBLE sudah benar.
	
	anim.play("opening")
	anim.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(name):
	if name == "opening":
		anim.play("hint_blink")
		can_start = true

func _input(event): # Gunakan _input agar lebih prioritas
	if not can_start:
		return

	# Menangani klik mouse, sembarang tombol, TERMASUK ESC
	if event is InputEventMouseButton and event.pressed:
		_go_to_main_menu()
	elif event is InputEventKey and event.pressed:
		_go_to_main_menu()

func _go_to_main_menu():
	can_start = false
	anim.stop()
	GM.is_opening = false
	get_tree().change_scene_to_file("res://main_menu.tscn")
