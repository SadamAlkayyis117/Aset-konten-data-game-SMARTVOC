extends Node

const SAVE_PATH := "user://settings.json"
var default_bindings := {}

var display_settings := {
	"resolution": Vector2i(1280, 720),
	"screen_mode": "windowed",
	"brightness": 0.0,
	"show_fps": false
}

var audio_settings := {
	"music_volume": 100.0,
	"music_mute": false,
	"sfx_volume": 100.0,
	"sfx_mute": false
}

func _ready():
	await get_tree().process_frame

	cache_default_bindings()

	if FileAccess.file_exists(SAVE_PATH):
		load_settings()
	else:
		reset_controls()

		# Terapkan default audio ke Audio Bus
		apply_music_volume(audio_settings.music_volume)
		set_music_mute(audio_settings.music_mute)
		apply_sfx_volume(audio_settings.sfx_volume)
		set_sfx_mute(audio_settings.sfx_mute)

	_debug_print_all_bindings()

func cache_default_bindings():
	for action in InputMap.get_actions():
		default_bindings[action] = InputMap.action_get_events(action).duplicate(true)

func get_action_key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "N/A"
	var events = InputMap.action_get_events(action)
	if events.is_empty():
		return "-"
	for ev in events:
		if ev is InputEventKey:
			return OS.get_keycode_string(ev.physical_keycode)
		elif ev is InputEventMouseButton:
			return "Mouse " + str(ev.button_index)
	return "???"


func get_all_used_keys() -> Array:
	var keys := []

	for action in InputMap.get_actions():
		if not _is_custom_action(action):
			continue

		var events = InputMap.action_get_events(action)

		for ev in events:
			if ev is InputEventKey:
				var key_name = _normalize_key(OS.get_keycode_string(ev.physical_keycode))
				if key_name != "" and not keys.has(key_name):
					keys.append(key_name)

			elif ev is InputEventMouseButton:
				var mouse_name = _normalize_mouse(ev.button_index)
				if mouse_name != "" and not keys.has(mouse_name):
					keys.append(mouse_name)

	return keys


func _normalize_key(key: String) -> String:
	key = key.strip_edges()

	var map := {
		# NUMBER ROW
		"1": "1", "2": "2", "3": "3", "4": "4", "5": "5",
		"6": "6", "7": "7", "8": "8", "9": "9", "0": "0",

		# LETTERS
		"Q":"Q","W":"W","E":"E","R":"R","T":"T",
		"Y":"Y","U":"U","I":"I","O":"O","P":"P",
		"A":"A","S":"S","D":"D","F":"F","G":"G",
		"H":"H","J":"J","K":"K","L":"L",
		"Z":"Z","X":"X","C":"C","V":"V","B":"B","N":"N","M":"M",

		# SPECIAL (HARUS MATCH NAMA NODE)
		"Minus": "-",
		"Equal": "=",
		"Semicolon": ";",
		"Apostrophe": "'",
		"Comma": ",",
		"Period": ".",
		"Slash": "/",
		"Backslash": "\\",

		# IMPORTANT KEYS
		"Space": "Space",
		"Shift": "Shift",
		"Shift+Left": "Shift",
		"Shift+Right": "Shift",
		"Ctrl": "Ctrl",
		"Alt": "Alt",
		"Enter": "Enter",
		"Escape": "Esc",
		"Tab": "Tab",
		"Backspace": "Backspace"
	}

	if map.has(key):
		return map[key]

	# fallback uppercase
	return key.to_upper()


func _normalize_mouse(index: int) -> String:
	match index:
		MOUSE_BUTTON_LEFT:
			return "MouseLeft"
		MOUSE_BUTTON_RIGHT:
			return "MouseRight"
		MOUSE_BUTTON_MIDDLE:
			return "MouseMiddle"
		_:
			return ""


func reset_controls():
	for action in default_bindings.keys():
		if _is_custom_action(action):
			InputMap.action_erase_events(action)
			for ev in default_bindings[action]:
				InputMap.action_add_event(action, ev)

func _is_custom_action(action: String) -> bool:
	if action.begins_with("ui_"):
		return false
	return true

# --- DISPLAY & AUDIO APPLY ---
func apply_resolution(res: Vector2i):
	display_settings.resolution = res
	DisplayServer.window_set_size(res)

func apply_screen_mode(mode: String):
	display_settings.screen_mode = mode
	match mode:
		"fullscreen": DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
		"windowed":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func apply_brightness(value: float):
	display_settings.brightness = value

func apply_music_volume(value: float):
	audio_settings.music_volume = value

	var bus := AudioServer.get_bus_index("Music")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, _linear_to_db(value))

func set_music_mute(mute: bool):
	audio_settings.music_mute = mute

	var bus := AudioServer.get_bus_index("Music")
	if bus != -1:
		AudioServer.set_bus_mute(bus, mute)

func apply_sfx_volume(value: float):
	audio_settings.sfx_volume = value

	var bus := AudioServer.get_bus_index("SFX")
	if bus != -1:
		AudioServer.set_bus_volume_db(bus, _linear_to_db(value))

func set_sfx_mute(mute: bool):
	audio_settings.sfx_mute = mute

	var bus := AudioServer.get_bus_index("SFX")
	if bus != -1:
		AudioServer.set_bus_mute(bus, mute)

func _linear_to_db(value: float) -> float:
	value = clamp(value / 100.0, 0.0, 1.0)

	if value <= 0.0:
		return -80.0

	return linear_to_db(value)

# --- SAVE & LOAD ---
func save_settings():
	var data := {
		"display": {
			"res_x": display_settings.resolution.x,
			"res_y": display_settings.resolution.y,
			"mode": display_settings.screen_mode,
			"bright": display_settings.brightness,
			"fps": display_settings.show_fps
		},
		"audio": audio_settings,
		"controls": _serialize_controls()
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func _serialize_controls() -> Dictionary:
	var result := {}
	for action in InputMap.get_actions():
		if not _is_custom_action(action):
			continue

		var events = InputMap.action_get_events(action)
		if events.size() > 0 and events[0] is InputEventKey:
			result[action] = events[0].physical_keycode  # ✅ WAJIB
	return result

func load_settings():
	if not FileAccess.file_exists(SAVE_PATH):
		print("❌ Save file ga ada, skip load")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())

	if not data:
		print("❌ Data JSON rusak")
		return

	var d = data.get("display", {})
	if d.has("res_x"): apply_resolution(Vector2i(d.res_x, d.res_y))
	if d.has("mode"): apply_screen_mode(d.mode)
	if d.has("bright"): apply_brightness(d.bright)

	var a = data.get("audio", {})
	if a.has("music_volume"): apply_music_volume(a.music_volume)
	if a.has("music_mute"): set_music_mute(a.music_mute)
	if a.has("sfx_volume"): apply_sfx_volume(a.sfx_volume)
	if a.has("sfx_mute"): set_sfx_mute(a.sfx_mute)

	var c = data.get("controls", {})

	for action in c.keys():
		if not InputMap.has_action(action):
			print("❌ Action ga ada:", action)
			continue

		var keycode = int(c[action])

		if keycode == 0:
			print("❌ Key kosong:", action)
			continue

		var ev := InputEventKey.new()
		ev.physical_keycode = keycode

		# 🔥 JANGAN HAPUS DULU
		InputMap.action_add_event(action, ev)
		print("✅ Loaded:", action, "->", keycode)

func _debug_print_all_bindings():
	print("\n===== DEBUG INPUT MAP =====")

	for action in InputMap.get_actions():
		if not _is_custom_action(action):
			continue

		var events = InputMap.action_get_events(action)

		if events.is_empty():
			print("❌", action, "-> KOSONG")
			continue

		for ev in events:
			if ev is InputEventKey:
				print("✅", action, "->", ev.physical_keycode, "(", OS.get_keycode_string(ev.physical_keycode), ")")

	print("===== END DEBUG =====\n")
