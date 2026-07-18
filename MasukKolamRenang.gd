extends Area3D

@export var target_scene_path: String = "res://kolam_renang_interior.tscn"
@export var target_spawn_point_name: String = "MasukKolam"

func _on_body_entered(body: Node3D):
	if body.is_in_group("Player"):
		var scene_switcher = get_tree().get_root().get_node_or_null("Sceneswitcher")
		
		if scene_switcher and scene_switcher.has_method("change_scene_with_transition"):
			 # Panggil SceneSwitcher untuk kembali ke World.tscn
			scene_switcher.change_scene_with_transition(target_scene_path, target_spawn_point_name)
		else:
			push_error("SceneSwitcher global tidak ditemukan!")
