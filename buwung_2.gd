extends Node3D

@export var animation_name := "Take 001"

@export var bob_height := 0.4
@export var bob_speed := 0.8

@export var sway_distance := 0.3
@export var sway_speed := 0.45

@export var roll_amount := 7.0
@export var pitch_amount := 3.5

@onready var anim: AnimationPlayer = $AnimationPlayer

var start_position: Vector3
var t := 0.0

func _ready():

	start_position = position

	if anim:
		anim.play(animation_name)
		anim.speed_scale = randf_range(0.9,1.15)

func _process(delta):

	t += delta

	# Naik turun
	position.y = start_position.y + sin(t * bob_speed) * bob_height

	# Geser kiri kanan
	position.x = start_position.x + sin(t * sway_speed) * sway_distance

	# Sedikit miring
	rotation.z = deg_to_rad(
		sin(t * bob_speed * 0.8) * roll_amount
	)

	# Pitch
	rotation.x = deg_to_rad(
		cos(t * bob_speed) * pitch_amount
	)

	# Belok sedikit
	rotation.y = deg_to_rad(
		sin(t * 0.25) * 5.0
	)
