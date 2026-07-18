extends Node3D

@onready var world_anim: AnimationPlayer = $"World Anim"
@onready var ui_anim: AnimationPlayer = $"UI Anim"

@onready var btn_mulai = $CanvasLayer/Root/MainMenu/Menu/Mulai
@onready var btn_pengaturan = $CanvasLayer/Root/MainMenu/Menu/Pengaturan
@onready var btn_extras = $CanvasLayer/Root/MainMenu/Menu/Extras
@onready var btn_devlog = $"CanvasLayer/Root/MainMenu/Dev Log"
@onready var btn_keluar = $CanvasLayer/Root/MainMenu/Menu/Keluar
@onready var btn_load = $"CanvasLayer/Root/MainMenu/Menu/Load game"

@onready var devlog_popup = $CanvasLayer/DevlogBG
@onready var devlog_close = $CanvasLayer/DevlogBG/ButtonClose


func _ready():
	GM.is_opening = true
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	devlog_popup.visible = false

	if world_anim.has_animation("Jalanan"):
		world_anim.play("Jalanan")

	ui_anim.play("UI")
	ui_anim.animation_finished.connect(_on_ui_anim_finished)

	_connect_buttons()


func _on_ui_anim_finished(anim_name: String):
	if anim_name == "UI":
		ui_anim.play("Main Menu Entrance")


func _connect_buttons():
	btn_mulai.pressed.connect(_on_mulai_pressed)
	btn_pengaturan.pressed.connect(_on_pengaturan_pressed)
	btn_extras.pressed.connect(_on_extras_pressed)
	btn_devlog.pressed.connect(_on_devlog_pressed)
	btn_keluar.pressed.connect(_on_keluar_pressed)
	btn_load.pressed.connect(_on_load_pressed)
	devlog_close.pressed.connect(_close_devlog)

func _on_mulai_pressed():
	GM.is_new_game = true
	GM.is_opening = false
	get_tree().change_scene_to_file("res://loading_screen.tscn")

func _on_load_pressed() -> void:
	var menu = preload("res://saveloaddata.tscn").instantiate()
	menu.name = "SaveLoadMenu" # BERI NAMA TETAP
	menu.mode = menu.Mode.SAVE # atau .LOAD
	get_tree().root.add_child(menu)

func _on_pengaturan_pressed():
	# GM.is_opening tetap true agar kursor mouse aktif
	var settings = preload("res://settingsmenu.tscn").instantiate()
	settings.open_source = settings.OpenSource.MAIN_MENU
	
	# Tambahkan ke root
	get_tree().root.add_child(settings)
	
	# Opsional: Sembunyikan UI Main Menu agar tidak terlihat di belakang
	$CanvasLayer/Root.visible = false
	
	# Hubungkan agar saat Setting ditutup, UI Main Menu muncul lagi
	settings.tree_exited.connect(func(): $CanvasLayer/Root.visible = true)

func _on_extras_pressed():
	GM.is_opening = false
	get_tree().change_scene_to_file("res://Extras.tscn")

func _on_devlog_pressed():
	devlog_popup.visible = true

func _close_devlog():
	devlog_popup.visible = false

func _on_keluar_pressed():
	get_tree().quit()
