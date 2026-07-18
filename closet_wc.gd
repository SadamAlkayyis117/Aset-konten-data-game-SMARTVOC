extends Node3D

@onready var area = $Area3D

@export var sit_point : Marker3D
@export var exit_point : Marker3D

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):

	if body.is_in_group("player"):
		body.set_interactable(self)

func _on_body_exited(body):

	if body.is_in_group("player"):
		body.clear_interactable(self)

func interact(player):

	var ui = get_tree().root.get_node_or_null("ClosetUI")

	if ui:
		ui.open_menu(player, self)
