extends Node3D

@export var bob_height: float = 0.7
@export var bob_speed: float = 0.6

var start_y: float

func _ready():
	start_y = position.y

func _process(_delta):
	position.y = start_y + sin(Time.get_ticks_msec() * 0.001 * bob_speed) * bob_height

	rotation.z = sin(Time.get_ticks_msec() * 0.001 * bob_speed * 0.7) * deg_to_rad(3.0)
