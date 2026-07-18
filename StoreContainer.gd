extends Node3D
class_name StoreContainer

@export var items_for_sale : Array[ItemData]

@onready var interact_area = $InteractArea

var ui_scene : PackedScene
var current_ui = null

func _ready():
    ui_scene = preload("res://scroll_container_ui.tscn")
    interact_area.body_entered.connect(_on_body_entered)
    interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.is_in_group("player"):   # ⚠ huruf kecil, sesuai Player._ready()
        body.set_interactable(self)

func _on_body_exited(body):
    if body.is_in_group("player"):
        body.clear_interactable(self)

func open_container(player):
    if current_ui != null:
        return
    
    current_ui = ui_scene.instantiate()
    get_tree().root.add_child(current_ui)
    current_ui.setup(self, player)

    # 🔥 TAMBAHAN PENTING
    player.input_locked = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
func close_container():
    if current_ui:
        current_ui.queue_free()
        current_ui = null
