extends Control

@onready var label = $LabelDescription

func _ready():
    visible = false  # mulai hidden
    if FunMissionManager.has_signal("fun_mission_ui_update"):
        FunMissionManager.fun_mission_ui_update.connect(_update)
        print("DEBUG: FunMissionLabel connected to signal")
    else:
        printerr("DEBUG: Signal fun_mission_ui_update tidak ditemukan!")

func _update(text:String):
    visible = true
    label.text = text
    print("DEBUG: Label updated:", text)
