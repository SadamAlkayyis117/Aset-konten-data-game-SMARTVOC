extends Area3D

# Properti untuk Scene Tujuan (Interior Sekolah)
@export var target_scene_path: String ="res://Gedung 2 Sekolah.tscn"

# Properti untuk Spawn Point di Scene Tujuan
# Ini harus sesuai dengan Node yang Anda buat di interior (Langkah 1B di respons sebelumnya)
@export var target_spawn_point_name: String = "Entrance_Masuk"

func _on_body_entered(body: Node3D) -> void:
    # Pastikan yang masuk adalah Player
    if body.is_in_group("Player"):
        # Cari SceneSwitcher yang ada di Root
        var scene_switcher = get_tree().get_root().get_node_or_null("Sceneswitcher")
        
        if scene_switcher and scene_switcher.has_method("change_scene_with_transition"):
             # Panggil fungsi transisi scene
            scene_switcher.change_scene_with_transition(target_scene_path, target_spawn_point_name)
