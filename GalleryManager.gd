extends Node

var photo_path := "user://gallery/photo/"
var video_path := "user://gallery/video/"

var export_path := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/SMARTVOC DCIM/"

func _ready():

    DirAccess.make_dir_recursive_absolute(photo_path)
    DirAccess.make_dir_recursive_absolute(video_path)
    DirAccess.make_dir_recursive_absolute(export_path)
