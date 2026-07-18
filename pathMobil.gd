extends PathFollow3D

@export var speed: float = 15.0
@export var rotation_correction: Vector3 = Vector3(0, 180, 0)
@export var scale_correction: Vector3 = Vector3(4, 4, 4)
@export var car_root_path: NodePath

@onready var car_root: Node3D = get_node(car_root_path)
var waiting_red_light: bool = false

func notify_stop_zone(must_stop: bool):
    waiting_red_light = must_stop

func _physics_process(delta):
    if not waiting_red_light:
        progress += speed * delta

    if car_root:
        # update posisi
        car_root.global_transform = global_transform

        # koreksi rotasi
        car_root.rotate_object_local(Vector3.UP, deg_to_rad(rotation_correction.y))
        car_root.rotate_object_local(Vector3.RIGHT, deg_to_rad(rotation_correction.x))
        car_root.rotate_object_local(Vector3.FORWARD, deg_to_rad(rotation_correction.z))

        # koreksi scale
        car_root.scale = scale_correction
