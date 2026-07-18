extends Node3D

@onready var anim = $AnimationPlayer
@onready var collision = $Armature/Skeleton3D/Cube/StaticBody3D/CollisionShape3D
@onready var door_open_sfx: AudioStreamPlayer3D = $DoorOpen
@onready var door_close_sfx: AudioStreamPlayer3D = $DoorClose
var player_inside := false
var is_open := false


func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)


func _input(event):

	if not player_inside:
		return

	if event.is_action_pressed("Interaksi"):
		interact()


func interact():

	if is_open:
		close_door()
	else:
		open_door()


func open_door():

	is_open = true

	collision.disabled = true

	if door_open_sfx:
		door_open_sfx.play()

	anim.play("Buka")

func close_door():

	is_open = false

	collision.disabled = false

	if door_close_sfx:
		door_close_sfx.play()

	anim.play("Tutup")

func _on_body_entered(body):

	if body.is_in_group("player"):
		player_inside = true


func _on_body_exited(body):

	if body.is_in_group("player"):
		player_inside = false
