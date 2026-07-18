extends Node3D

# --- Daftar NPC Scene yang dipanggil lewat preload ---
var npc_scenes: Array = [
    preload("res://npc_kota_1.tscn"),
]

@export var npc_count: int = 1
@export var spawn_search_radius: float = 30.0

func _ready():
    await get_tree().process_frame
    while NavigationServer3D.get_maps().is_empty():
        await get_tree().process_frame
    _spawn_all_npcs()

func _spawn_all_npcs():
    for i in range(npc_count):
        _spawn_random_npc(i)

func _spawn_random_npc(_index: int):
    var npc_scene = npc_scenes.pick_random()
    if npc_scene == null:
        push_error("❌ Tidak ada NPC scene yang valid!")
        return
    
    var npc_instance = npc_scene.instantiate()
    add_child(npc_instance)
    
    var spawn_pos = _get_random_navmesh_point()
    npc_instance.global_position = spawn_pos

func _get_random_navmesh_point() -> Vector3:
    var maps = NavigationServer3D.get_maps()
    if maps.is_empty():
        return global_position
    
    var map = maps[0]
    
    for i in range(10):
        var rnd = Vector3(
            randf_range(-spawn_search_radius, spawn_search_radius),
            0,
            randf_range(-spawn_search_radius, spawn_search_radius)
        )
        var sample_point = global_position + rnd
        var point = NavigationServer3D.map_get_closest_point(map, sample_point)
        if point != Vector3.ZERO:
            return point
    
    # fallback bila gagal
    return NavigationServer3D.map_get_closest_point(map, global_position)
