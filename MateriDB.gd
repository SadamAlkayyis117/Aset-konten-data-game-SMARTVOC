extends Node

var data := {}

func _ready():
    load_json()

func load_json():
    var file = FileAccess.open("res://Materi.json", FileAccess.READ)
    if file:
        var text = file.get_as_text()
        data = JSON.parse_string(text)
        if typeof(data) != TYPE_DICTIONARY:
            push_error("JSON materi tidak valid!")
