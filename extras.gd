extends CanvasLayer

@onready var Extras_close = $Root/ButtonBack

func _ready() -> void:
    GM.is_opening = true
    get_tree().paused = false
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    _connect_buttons()

func _connect_buttons():
    if not Extras_close.pressed.is_connected(_on_Close_pressed):
        Extras_close.pressed.connect(_on_Close_pressed)

func _on_Close_pressed():
    GM.is_opening = false 
    
    get_tree().change_scene_to_file("res://main_menu.tscn")
