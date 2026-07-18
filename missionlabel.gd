extends Control

@onready var label := $LabelDesc

func _ready():
    visible = true

    if MissionManager.has_signal("mission_ui_updated"):
        MissionManager.mission_ui_updated.connect(_on_ui_update)

    # 🔥 FORCE SYNC (DEFERRED, ENGINE-SAFE)
    call_deferred("_sync_from_manager")


func _sync_from_manager() -> void:
    if MissionManager.ui_total > 0:
        _on_ui_update(
            MissionManager.ui_description,
            MissionManager.ui_current,
            MissionManager.ui_total
        )


func _on_ui_update(description: String, current: int, total: int) -> void:
    visible = true
    label.visible = true
    label.text = "%s\nDeliver %d / %d" % [
        description,
        current,
        total
    ]
