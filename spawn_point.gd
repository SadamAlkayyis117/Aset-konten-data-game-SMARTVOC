extends Node3D

@export var car_scenes: Array[PackedScene]       # semua jenis mobil
@export var path_nodes: Array[NodePath]          # Path3D jalur masing-masing
@export var spawn_interval: float = 3.0          # interval spawn tiap mobil

@onready var timer: Timer = Timer.new()

func _ready():
    # Tambahkan Timer ke SpawnManager
    add_child(timer)
    timer.wait_time = spawn_interval
    timer.one_shot = false
    timer.autostart = true
    timer.timeout.connect(_spawn_car)

func _spawn_car():
    # Pastikan ada mobil dan jalur
    if car_scenes.is_empty() or path_nodes.is_empty():
        return

    # Pilih mobil & jalur (misal statis, bisa diubah untuk random)
    var car_scene: PackedScene = car_scenes[0]   # contoh: selalu MobilBiru
    var car_instance = car_scene.instantiate()
    add_child(car_instance)                      # mobil jadi root World

    # Ambil Path3D sesuai jalur
    var path_node: Path3D = get_node(path_nodes[0])
    if path_node == null:
        push_warning("Path node tidak ditemukan!")
        car_instance.queue_free()
        return

    # Pasang PathFollow3D mobil ke jalur
    if car_instance.has_node("PathFollow3D"):
        car_instance.start_on_path(path_node)
    else:
        push_warning("Mobil tidak punya PathFollow3D")
        car_instance.queue_free()
        return

    # Hubungkan finished_path -> queue_free() otomatis
    if car_instance.has_signal("finished_path"):
        if not car_instance.finished_path.is_connected(car_instance.queue_free):
            car_instance.finished_path.connect(car_instance.queue_free)
