extends Node3D

@onready var anim_player = $AnimationPlayer

var can_start := false

func _ready():
	GM.is_opening = true
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	anim_player.play("opening") 
	anim_player.animation_finished.connect(_pindah_ke_menu)

func _pindah_ke_menu(_nama_animasi):
	get_tree().change_scene_to_file("res://opening.tscn")
