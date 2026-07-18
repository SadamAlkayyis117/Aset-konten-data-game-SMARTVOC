extends Node3D
class_name ItemPickups

@export var item_data: ItemData  # ← Drag & drop .tres langsung di inspector
@onready var interact_area: Area3D = $InteractArea

func _ready():
    if not item_data:
        print("ERROR: ItemPickup", name, "tidak punya ItemData! Tambahkan di inspector.")
        return
    
    interact_area.body_entered.connect(_on_body_entered)
    interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
    if body.is_in_group("player"):
        var player = body
        player.current_interactable = self
        print("DEBUG: Player masuk area item:", item_data.item_name)

func _on_body_exited(body):
    if body.is_in_group("player"):
        var player = body
        if player.current_interactable == self:
            player.current_interactable = null
        print("DEBUG: Player keluar area item:", item_data.item_name)

func get_item_data() -> ItemData:
    return item_data
