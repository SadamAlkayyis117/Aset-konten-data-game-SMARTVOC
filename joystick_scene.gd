extends Control

# Sinyal kustom yang akan kita pancarkan ke Player
signal move_input(direction) 

var stick_base: TextureRect
var stick_icon: Sprite2D 
var max_distance: float = 0.0 
var is_active: bool = false
var touch_idx: int = -1

var initial_stick_global_position: Vector2 # Posisi stay dalam koordinat GLOBAL
var base_center_global_position: Vector2   # Pusat base dalam koordinat GLOBAL
var stick_size: Vector2 

func _ready():
	stick_base = $"Analog Base"
	stick_icon = $"Analog Stick" 
	
	stick_size = stick_icon.texture.get_size()
	
	# Perhitungan Max Distance yang benar
	var base_radius = stick_base.size.x / 2.0
	var stick_radius = stick_size.x / 2.0
	var margin_safe = 5.0 
	max_distance = (base_radius - stick_radius) - margin_safe 

	# --- KUNCI: HITUNG POSISI STAY HANYA BERDASARKAN GLOBAL ---
	
	# Pusat base dalam koordinat GLOBAL (Ini adalah titik referensi mutlak)
	base_center_global_position = stick_base.get_global_position() + (stick_base.size / 2)
	
	# initial_stick_global_position adalah posisi stick saat dilepas (pusat base)
	initial_stick_global_position = base_center_global_position
	
	# Terapkan posisi stay awal menggunakan GLOBAL_POSITION
	stick_icon.global_position = initial_stick_global_position 


func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if stick_base.get_global_rect().has_point(event.position):
				is_active = true
				touch_idx = event.index
		elif event.index == touch_idx:
			is_active = false
			touch_idx = -1
			
			# Mengatur kembali ke global position
			stick_icon.global_position = initial_stick_global_position 
			emit_signal("move_input", Vector2.ZERO)

	elif event is InputEventScreenDrag and event.index == touch_idx and is_active:
		
		# 1. Hitung Vektor Arah Murni (Global)
		var vector_global = event.position - base_center_global_position 
		
		var vector = vector_global.normalized()
		var distance = vector_global.length()
		
		# Batasi pergerakan stik menggunakan max_distance
		distance = min(distance, max_distance)

		# 2. KUNCI POSISI STICK (Gerak - GLOBAL)
		# Posisi Stick = Pusat Base Global + Vektor Gerak
		var new_global_position = base_center_global_position + vector * distance 
		
		# Terapkan global position
		stick_icon.global_position = new_global_position


		# --- KOREKSI PEMBALIKAN SUMBU X ---
		var corrected_x = -vector.x
		
		# Hitung input_dir (VECTOR X, Y)
		var input_vec = Vector2(corrected_x, vector.y).normalized() * (distance / max_distance)
		emit_signal("move_input", input_vec)
