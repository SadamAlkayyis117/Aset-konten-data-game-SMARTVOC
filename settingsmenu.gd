extends CanvasLayer

enum OpenSource { MAIN_MENU, PAUSE_MENU }
var open_source : OpenSource = OpenSource.MAIN_MENU

const RESOLUTIONS := [
	Vector2i(1280, 720),
	Vector2i(1024, 768),
	Vector2i(1024, 600),
	Vector2i(960, 720),
	Vector2i(960, 640),
	Vector2i(800, 600)
]


@onready var label_info = $"Root/Main Panel/TabDetail/LabelInfo"
@onready var content_display = $"Root/Main Panel/display"
@onready var content_audio = $"Root/Main Panel/audio"
@onready var scroll_controller = $"Root/Main Panel/ScrollContainer"
@onready var content_controller = $"Root/Main Panel/ScrollContainer/controller"
@onready var tab_display = $"Root/Main Panel/TabMain/ButtonDisplay"
@onready var tab_audio = $"Root/Main Panel/TabMain/ButtonAudio"
@onready var tab_controller = $"Root/Main Panel/TabMain/ButtonController"
@onready var option_resolution: OptionButton = $"Root/Main Panel/display/OptionResolution"
@onready var option_screen_mode: OptionButton = $"Root/Main Panel/display/OptionScreenmode"
@onready var slider_music = $"Root/Main Panel/audio/HSliderMusic"
@onready var slider_sfx = $"Root/Main Panel/audio/HSliderSFX"
@onready var check_music = $"Root/Main Panel/audio/Musicmute"
@onready var check_sfx = $"Root/Main Panel/audio/SFXmute"
@onready var keyboard = $"Root/Main Panel/Keyboard View"
@onready var brightness_overlay = get_node_or_null("../BrightnessOverlay") # Sesuaikan pathnya
@onready var btn_back = $"Root/Main Panel/ButtonBack"

var waiting_for_rebind := false
var current_action := ""
var current_button : Button = null
var is_rebinding := false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS 
	
	if open_source == OpenSource.MAIN_MENU:
		GM.is_opening = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# --- TAMBAHKAN DUA BARIS INI ---
	_setup_resolution_options()
	_setup_screen_modes()
	await get_tree().process_frame
	set_process_unhandled_input(true)
	_hide_all_contents()
	_sync_ui_with_settings()
	_connect_signals()

func _setup_resolution_options():
	option_resolution.clear()

	for r in RESOLUTIONS:
		option_resolution.add_item("%d x %d" % [r.x, r.y])

	var current = SettingManager.display_settings.resolution
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == current:
			option_resolution.select(i)
			break

	option_resolution.item_selected.connect(
		func(i): SettingManager.apply_resolution(RESOLUTIONS[i])
	)

func _setup_screen_modes():
	option_screen_mode.clear()

	var modes = ["Windowed", "Fullscreen", "Borderless"]
	for m in modes:
		option_screen_mode.add_item(m)

	match SettingManager.display_settings.screen_mode:
		"windowed": option_screen_mode.select(0)
		"fullscreen": option_screen_mode.select(1)
		"borderless": option_screen_mode.select(2)

	option_screen_mode.item_selected.connect(_on_screen_mode_selected)

func _on_screen_mode_selected(index: int) -> void:
	SfxManager.play_click()
	match index:
		0: SettingManager.apply_screen_mode("windowed")
		1: SettingManager.apply_screen_mode("fullscreen")
		2: SettingManager.apply_screen_mode("borderless")


func _sync_ui_with_settings():
	slider_music.value = SettingManager.audio_settings.music_volume
	check_music.button_pressed = SettingManager.audio_settings.music_mute
	slider_sfx.value = SettingManager.audio_settings.sfx_volume
	check_sfx.button_pressed = SettingManager.audio_settings.sfx_mute
	_refresh_keybind_ui()

func _connect_signals():

	#==========================
	# TAB
	#==========================

	tab_display.mouse_entered.connect(func():
		SfxManager.play_hover()
	)

	tab_audio.mouse_entered.connect(func():
		SfxManager.play_hover()
	)

	tab_controller.mouse_entered.connect(func():
		SfxManager.play_hover()
	)

	tab_display.pressed.connect(func():
		SfxManager.play_click()
		_open_tab("display")
	)

	tab_audio.pressed.connect(func():
		SfxManager.play_click()
		_open_tab("audio")
	)

	tab_controller.pressed.connect(func():
		SfxManager.play_click()
		_open_tab("controller")
	)


	#==========================
	# AUDIO
	#==========================

	slider_music.value_changed.connect(func(v):
		SettingManager.apply_music_volume(v)
	)

	slider_sfx.value_changed.connect(func(v):
		SettingManager.apply_sfx_volume(v)
	)

	slider_music.drag_ended.connect(func(_changed):
		SfxManager.play_click()
	)

	slider_sfx.drag_ended.connect(func(_changed):
		SfxManager.play_click()
	)

	check_music.toggled.connect(func(v):
		SfxManager.play_click()
		SettingManager.set_music_mute(v)
	)

	check_sfx.toggled.connect(func(v):
		SfxManager.play_click()
		SettingManager.set_sfx_mute(v)
	)


	#==========================
	# DISPLAY
	#==========================

	option_resolution.item_selected.connect(func(i):
		SfxManager.play_click()
		SettingManager.apply_resolution(RESOLUTIONS[i])
	)

	option_screen_mode.item_selected.connect(_on_screen_mode_selected)


	#==========================
	# BACK
	#==========================

	if btn_back:

		btn_back.mouse_entered.connect(func():
			SfxManager.play_hover()
		)

		btn_back.pressed.connect(func():
			SfxManager.play_click()
			_on_back_pressed()
		)

	_connect_rebind_btn("Maju", "ScrollContainer/controller/LabelForward/ButtonKeyForward")
	_connect_rebind_btn("Mundur", "ScrollContainer/controller/LabelBackward/ButtonKeyBackward")
	_connect_rebind_btn("Kiri", "ScrollContainer/controller/LabelLeft/ButtonKeyLeft")
	_connect_rebind_btn("Kanan", "ScrollContainer/controller/LabelRight/ButtonKeyRight")
	_connect_rebind_btn("Lompat", "ScrollContainer/controller/LabelJump/ButtonKeyJump")
	_connect_rebind_btn("Lari", "ScrollContainer/controller/LabelSprint/ButtonKeySprint")
	_connect_rebind_btn("Interaksi", "ScrollContainer/controller/LabelInteract/ButtonKeyInteract")
	_connect_rebind_btn("Inventory", "ScrollContainer/controller/LabelInventory/ButtonKeyInventory")
	_connect_rebind_btn("Drop", "ScrollContainer/controller/LabelDrop/ButtonKeyDrop")
	_connect_rebind_btn("open_smartphone", "ScrollContainer/controller/LabelSmartphone/ButtonKeySmartphone")
	_connect_rebind_btn("QuickUse1", "ScrollContainer/controller/LabelQuickUse1/ButtonKeyQuickUse1")
	_connect_rebind_btn("QuickUse2", "ScrollContainer/controller/LabelQuickUse2/ButtonKeyQuickUse2")
	_connect_rebind_btn("QuickUse3", "ScrollContainer/controller/LabelQuickUse3/ButtonKeyQuickUse3")
	_connect_rebind_btn("QuickUse4", "ScrollContainer/controller/LabelQuickUse4/ButtonKeyQuickUse4")
	_connect_rebind_btn("QuickUse5", "ScrollContainer/controller/LabelQuickUse5/ButtonKeyQuickUse5")
	_connect_rebind_btn("Sheathe", "ScrollContainer/controller/LabelSheathe/ButtonKeySheathe")
	_connect_rebind_btn("fullmap", "ScrollContainer/controller/LabelMap/ButtonKeyMap")
	_connect_rebind_btn("toggle_needs", "ScrollContainer/controller/LabelNeeds/ButtonKeyNeeds")
	_connect_rebind_btn("Fire", "ScrollContainer/controller/LabelFire/ButtonKeyFire")
	_connect_rebind_btn("AltFire", "ScrollContainer/controller/LabelAltFire/ButtonKeyAltFire")
	_connect_rebind_btn("SwitchCamera", "ScrollContainer/controller/LabelSwitchPOV/ButtonKeySwitchPOV")
	_connect_rebind_btn("Crouch", "ScrollContainer/controller/LabelCrouch/ButtonKeyCrouch")

func _connect_rebind_btn(action: String, path: String):
	var full_path = "Root/Main Panel/" + path
	var btn = get_node_or_null(full_path)

	if btn == null:
		print("❌ BUTTON GA KETEMU:", full_path)
		return

	btn.pressed.connect(func(): _start_rebind(action, btn))

func _start_rebind(action: String, btn: Button):
	if is_rebinding:
		return

	is_rebinding = true
	waiting_for_rebind = true
	current_action = action
	current_button = btn
	btn.text = "..."

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		print("KEY DETECTED:", event.physical_keycode, OS.get_keycode_string(event.physical_keycode))

	if waiting_for_rebind:
		if event is InputEventKey and event.pressed and not event.echo:
			_apply_key(event)
			return

	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _apply_key(event: InputEventKey):
	if not is_rebinding:
		return

	is_rebinding = false

	var new_event := InputEventKey.new()
	new_event.physical_keycode = event.physical_keycode

	# 🔥 VALIDASI DULU
	if new_event.physical_keycode == 0:
		print("❌ Rebind gagal, key kosong")
		return

	# 🔥 BARU HAPUS SETELAH VALID
	InputMap.action_erase_events(current_action)
	InputMap.action_add_event(current_action, new_event)

	print("🎯 Rebind:", current_action, "->", new_event.physical_keycode)

	waiting_for_rebind = false

	SettingManager.save_settings()

	_refresh_keybind_ui()
	_refresh_keyboard_view()

	get_viewport().set_input_as_handled()

func _refresh_keybind_ui():
	_update_btn_text("Maju", "ScrollContainer/controller/LabelForward/ButtonKeyForward")
	_update_btn_text("Mundur", "ScrollContainer/controller/LabelBackward/ButtonKeyBackward")
	_update_btn_text("Kiri", "ScrollContainer/controller/LabelLeft/ButtonKeyLeft")
	_update_btn_text("Kanan", "ScrollContainer/controller/LabelRight/ButtonKeyRight")
	_update_btn_text("Lompat", "ScrollContainer/controller/LabelJump/ButtonKeyJump")
	_update_btn_text("Lari", "ScrollContainer/controller/LabelSprint/ButtonKeySprint")
	_update_btn_text("Interaksi", "ScrollContainer/controller/LabelInteract/ButtonKeyInteract")
	_update_btn_text("Inventory", "ScrollContainer/controller/LabelInventory/ButtonKeyInventory")
	_update_btn_text("Drop", "ScrollContainer/controller/LabelDrop/ButtonKeyDrop")
	_update_btn_text("open_smartphone", "ScrollContainer/controller/LabelSmartphone/ButtonKeySmartphone")
	_update_btn_text("QuickUse1", "ScrollContainer/controller/LabelQuickUse1/ButtonKeyQuickUse1")
	_update_btn_text("QuickUse2", "ScrollContainer/controller/LabelQuickUse2/ButtonKeyQuickUse2")
	_update_btn_text("QuickUse3", "ScrollContainer/controller/LabelQuickUse3/ButtonKeyQuickUse3")
	_update_btn_text("QuickUse4", "ScrollContainer/controller/LabelQuickUse4/ButtonKeyQuickUse4")
	_update_btn_text("QuickUse5", "ScrollContainer/controller/LabelQuickUse5/ButtonKeyQuickUse5")
	_update_btn_text("Sheathe", "ScrollContainer/controller/LabelSheathe/ButtonKeySheathe")
	_update_btn_text("fullmap", "ScrollContainer/controller/LabelMap/ButtonKeyMap")
	_update_btn_text("toggle_needs", "ScrollContainer/controller/LabelNeeds/ButtonKeyNeeds")
	_update_btn_text("Fire", "ScrollContainer/controller/LabelFire/ButtonKeyFire")
	_update_btn_text("AltFire", "ScrollContainer/controller/LabelAltFire/ButtonKeyAltFire")
	_update_btn_text("SwitchCamera", "ScrollContainer/controller/LabelSwitchPOV/ButtonKeySwitchPOV")
	_update_btn_text("Crouch", "ScrollContainer/controller/LabelCrouch/ButtonKeyCrouch")
	if keyboard:
		var keys = SettingManager.get_all_used_keys()
		keyboard.apply_keys_from_actions(keys)

func _update_btn_text(action: String, path: String):
	var btn = get_node_or_null("Root/Main Panel/" + path)
	if btn: btn.text = SettingManager.get_action_key_text(action)

func _on_back_pressed():
	SettingManager.save_settings()
	
	if open_source == OpenSource.MAIN_MENU:
		queue_free()
	else:
		queue_free()

func _hide_all_contents():
	label_info.visible = true
	content_display.visible = false
	content_audio.visible = false
	scroll_controller.visible = false
	if keyboard:
		keyboard.visible = false

func _open_tab(tab):
	_hide_all_contents()
	label_info.visible = false

	if tab == "display":
		content_display.visible = true

	elif tab == "audio":
		content_audio.visible = true

	elif tab == "controller":
		scroll_controller.visible = true
		scroll_controller.scroll_vertical = 0

		if keyboard:
			keyboard.visible = true

		# 🔥 refresh keyboard langsung
		_refresh_keyboard_view()

func _refresh_keyboard_view():
	if keyboard:
		var keys = SettingManager.get_all_used_keys()
		keyboard.apply_keys_from_actions(keys)
