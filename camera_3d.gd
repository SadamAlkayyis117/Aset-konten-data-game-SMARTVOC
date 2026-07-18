# File: Camera3D.gd
extends Camera3D

@onready var spring_arm = get_parent() 

@export var lerp_power: float = 1.8

func _process(delta: float) -> void:
    # PAUSE GUARD
    if Engine.time_scale == 0.0:
        return
        
    if is_instance_valid(spring_arm):
        position = lerp(position, Vector3.ZERO, delta * lerp_power)
