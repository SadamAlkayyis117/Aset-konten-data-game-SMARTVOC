extends CanvasLayer

@onready var label: RichTextLabel = $Panel/Label

func show_dialog(text: String):
    label.text = text
    visible = true

func hide_dialog():
    visible = false
