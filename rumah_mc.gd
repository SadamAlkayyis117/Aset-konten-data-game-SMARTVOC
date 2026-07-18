extends Node3D

@export var fridge_path : NodePath

@onready var fridge : StaticContainer = get_node(fridge_path)

func _ready():
	MusicManager.start_gameplay_music()
	if GM.is_new_game:

		fridge.initialize_new_game()

		GM.is_new_game = false
