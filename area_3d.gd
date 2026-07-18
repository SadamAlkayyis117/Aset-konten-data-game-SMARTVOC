extends Area3D

@export var target_scene: String

func _on_body_entered(body):
    if body is CharacterBody3D:
        call_deferred("_change_scene")


func _change_scene():
    get_tree().change_scene_to_file(target_scene)
