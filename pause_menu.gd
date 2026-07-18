extends CanvasLayer

# --- VARIABEL ONREADY ---
# Asumsi nama node anak tombol di dalam ColorRect/menu
@onready var resume_button = $ColorRect/Resume
@onready var quit_button = $ColorRect/Quit
@onready var settings_button = $ColorRect/Setting
@onready var ke_menu = $"ColorRect/Ke menu"
@onready var tutorial_button = $ColorRect/Tutorial

# Referensi Autoload (Singleton)
var performance_settings: Node = null
var global_manager: Node = null # Ini akan menampung node Autoload "GM"


# --- INITIALISASI ---

func _initialize_settings_panel():
	# Asumsi Autoload PerformanceSettings bernama "PerformanceSettings"
	performance_settings = get_node_or_null("/root/Performancesettings")
	if performance_settings == null:
		push_error("ERROR: Autoload PerformanceSettings tidak ditemukan!")
		return
		

func _ready():
	# Inisialisasi GM (Ambil referensi Autoload)
	global_manager = get_node_or_null("/root/GM")
	
	# ===== BLOKADE SAAT OPENING (Koreksi Sintaks) =====
	# Kita cek apakah variabel 'is_opening' ada di dalam global_manager
	if global_manager and ("is_opening" in global_manager) and global_manager.is_opening:
		visible = false
		set_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		return

	# Jika bukan opening, lanjut seperti biasa
	process_mode = Node.PROCESS_MODE_ALWAYS 
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$ColorRect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	if global_manager == null:
		push_error("ERROR: Autoload GM TIDAK DITEMUKAN.")
		
	_initialize_settings_panel()
	


# 🌟 LEVEL 2 DEBUG: MENDETEKSI INPUT DI AREA MENU (Control Node) 🌟
func _gui_input(event):
	if global_manager and global_manager.is_opening:
		return

	if event is InputEventMouseButton and event.pressed:
		print(">>> DEBUG LEVEL 2: KLIK MOUSE TERDETEKSI DI AREA PAUSE MENU! <<<")
		get_viewport().set_input_as_handled()

func _on_resume_pressed():
	if global_manager and global_manager.is_opening:
		return

	print(">>> DEBUG LEVEL 3: KLIK RESUME DITERIMA DI HANDLER. Tombol Berfungsi! <<<") 
	
	# Memanggil toggle_pause di Autoload GM
	if is_instance_valid(global_manager) and global_manager.has_method("toggle_pause"):
		global_manager.toggle_pause()
	else:
		push_error("ERROR: Autoload GM tidak valid atau toggle_pause tidak ditemukan.")


func _on_quit_pressed():
	print(">>> DEBUG LEVEL 3: KLIK QUIT DITERIMA DI HANDLER. Keluar... <<<") 
	# Tombol ini memanggil quit(), yang memicu _notification di GlobalManager (GM)
	get_tree().quit()

func _on_setting_pressed() -> void:
	var settings = preload("res://settingsmenu.tscn").instantiate()
	settings.open_source = settings.OpenSource.PAUSE_MENU
	settings.name = "SettingMenu"
	get_tree().root.add_child(settings)
	self.visible = false
	settings.tree_exited.connect(func():
		self.visible = true
	)

func _on_ke_menu_pressed() -> void:
	print(">>> Kembali ke Main Menu... Membersihkan status pause. <<<")
	Engine.time_scale = 1.0
	get_tree().paused = false
	if global_manager:
		global_manager.is_game_paused = false
		global_manager.pause_menu_instance = null
	get_tree().change_scene_to_file("res://main_menu.tscn")
	queue_free()


func _on_load_pressed() -> void:
	var menu = preload("res://saveloaddata.tscn").instantiate()
	menu.parent_menu = self   
	get_tree().root.add_child(menu)
	self.hide()

func _on_tutorial_pressed() -> void:

	var tutorial = preload("res://tutorial.tscn").instantiate()

	tutorial.name = "TutorialMenu"

	get_tree().root.add_child(tutorial)

	self.visible = false

	tutorial.tree_exited.connect(func():

		self.visible = true

	)
