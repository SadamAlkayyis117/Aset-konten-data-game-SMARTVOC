extends Node3D

@onready var area = $Area3D
@onready var top_exit = $TopPoint
@onready var bottom_exit = $BottomPoint
@onready var mount_point = $MountPoint

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.set_interactable(self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		body.clear_interactable(self)

func get_mount_position():
	return mount_point.global_position

func interact(player):
	player.enter_ladder(self)
