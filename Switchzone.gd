extends Area3D

# Pastikan di editor Godot, Collision Mask disetel ke Mask 1
@export var next_straight : Path3D
@export var turn_left : Path3D
@export var turn_right : Path3D
@export var allow_turn : bool = true    

func _ready():
    # Mengganti CONNECT_UNIQUE dengan pengecekan is_connected()
    if not body_entered.is_connected(_on_body_entered):
        body_entered.connect(_on_body_entered)
    if not body_exited.is_connected(_on_body_exited):
        body_exited.connect(_on_body_exited) 


func _on_body_entered(body):
    if not body.is_in_group("vehicle"):
        return

    if body.has_method("enter_switch_zone"):
        body.enter_switch_zone(self)

func _on_body_exited(body):
    if not body.is_in_group("vehicle"):
        return
