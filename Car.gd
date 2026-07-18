extends CharacterBody3D

signal finished_path

@export var speed: float = 3.0
@export var stop_distance: float = 3.0
@export var turn_signal_time: float = 1.2

var follower: PathFollow3D
var waiting_red_light: bool = false

@onready var ray: RayCast3D = $RayCast3D
@onready var sen_left: Node3D = $"Sen Kiri"
@onready var sen_right: Node3D = $"Sen Kanan"

func _ready():
    add_to_group("vehicle")
    ray.target_position = Vector3(0,0,-stop_distance)
    ray.force_raycast_update()
    sen_left.visible = false
    sen_right.visible = false

func start_on_path(path: Path3D):
    follower = get_node("PathFollow3D")
    path.add_child(follower)  # follower sekarang child path
    follower.progress_ratio = 0.0
    follower.global_transform = path.global_transform
    global_transform = follower.global_transform

func _physics_process(delta):
    if follower == null:
        return

    # Periksa obstacle
    var blocked = ray.is_colliding()
    var must_stop = blocked or waiting_red_light

    # Jika tidak terhalang, maju
    if not must_stop:
        follower.progress += speed * delta

    # Update posisi mobil
    global_transform = follower.global_transform

    # Emit sinyal jika sampai ujung path
    if follower.progress_ratio >= 0.99:
        emit_signal("finished_path")

func notify_stop_zone(is_red: bool):
    waiting_red_light = is_red
