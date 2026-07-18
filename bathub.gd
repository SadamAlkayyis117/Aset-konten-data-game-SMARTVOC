extends Node3D

@onready var area = $Area3D

@export var bath_point : Marker3D
@export var exit_point : Marker3D

@onready var water_mesh = $Water

func _ready():

	water_mesh.visible = false

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):

	if body.is_in_group("player"):
		body.set_interactable(self)

func _on_body_exited(body):

	if body.is_in_group("player"):
		body.clear_interactable(self)

func interact(player):
	player.start_bath(self)
