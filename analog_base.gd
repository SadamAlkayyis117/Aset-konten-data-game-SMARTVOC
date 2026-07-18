extends TextureRect

# Variabel yang bisa disetel di Inspector
@export var max_move_radius: float = 200.0 # Radius maksimum pergeseran Base dari titik Stay
@export var return_speed: float = 15.0      # Kecepatan kembali ke posisi stay

# Variabel internal
var stick_icon: Sprite2D                    # Referensi ke node stick (diambil dari parent)
var initial_base_global_position_tl: Vector2 # Posisi Top-Left Base saat ready (Titik Stay)
var initial_base_center_global_position: Vector2 # Pusat Base saat ready

func _ready():
	# Asumsikan Stick Icon adalah saudara kandung (sibling) atau anak dari parent Base
	# Kita harus mencari Stick Icon dari Root Scene atau Parent.
	
	# Coba cari Stick Icon dari Parent Node
	if get_parent() and get_parent().has_node("Analog Stick"):
		stick_icon = get_parent().get_node("Analog Stick") as Sprite2D
	
	if stick_icon == null:
		push_error("ERROR: Node 'Analog Stick' tidak ditemukan di Parent. Skrip Base tidak bisa berjalan.")
		set_process(false)
		return
		
	# 1. Simpan Posisi Stay (Top-Left dan Center)
	initial_base_global_position_tl = self.global_position
	initial_base_center_global_position = self.global_position + (self.size / 2)


func _process(delta):
	# KUNCI 1: Dapatkan posisi pusat Stick saat ini yang dihitung oleh skrip lain
	var current_stick_center = stick_icon.global_position

	# Hitung vektor pergeseran dari Titik Stay Base ke posisi Stick saat ini
	var vector_to_stay = current_stick_center - initial_base_center_global_position
	var distance = vector_to_stay.length()
	
	# Cek apakah Base aktif (Stick digeser keluar dari pusat stay)
	var is_base_active = (distance > 1.0) # Sedikit toleransi

	if is_base_active:
		# --- LOGIKA PERGERAKAN ---
		
		var vector = vector_to_stay.normalized()
		
		# Batasi Pergerakan Base dengan max_move_radius
		var base_move_distance = min(distance, max_move_radius)
		
		# Hitung Pusat Base yang baru
		var new_global_center = initial_base_center_global_position + vector * base_move_distance
		
		# Pindahkan Base ke posisi Top-Left yang baru
		self.global_position = new_global_center - (self.size / 2)
		
	else:
		# --- LOGIKA KEMBALI KE STAY ---
		if self.global_position != initial_base_global_position_tl:
			
			var target_tl = initial_base_global_position_tl
			
			# Lerp posisi global Base kembali ke posisi stay (Top-Left)
			self.global_position = self.global_position.lerp(target_tl, return_speed * delta)
			
			# Memastikan Base berhenti tepat di posisi awal
			if self.global_position.distance_to(target_tl) < 1.0:
				self.global_position = target_tl
