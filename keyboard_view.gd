extends Control

@onready var keys_root: Panel = $Panel

const COLOR_DIM := Color(1, 1, 1, 0.15)
const COLOR_ACTIVE := Color(0.3, 0.9, 1.0, 1.0)

func reset_all_keys() -> void:
    for key in keys_root.get_children():
        if key is Sprite2D:
            key.modulate = COLOR_DIM

func activate_key(key_name: String) -> void:
    for key in keys_root.get_children():
        if key is Sprite2D:
            if key.name.to_lower() == key_name.to_lower():
                key.modulate = COLOR_ACTIVE
                return

func apply_keys_from_actions(actions: Array) -> void:
    reset_all_keys()

    for key_name in actions:
        activate_key(key_name)
