extends Camera3D

# HAPUS: @onready var player = get_tree().get_first_node_in_group("player")
var player: Node = null # Deklarasi variabel untuk Player

# ======================================================
# HARUS DIKODEKAN KERAS (HARDCODE) AGAR STABIL
const FIXED_Y_POSITION: float = 150.0 
# ======================================================

const FIXED_ORTHOGONAL_SIZE: float = 200.0

# Sudut rotasi untuk melihat ke bawah (90 derajat)
const FIXED_ROTATION: Vector3 = Vector3(deg_to_rad(-90), deg_to_rad(0), deg_to_rad(0))


func _ready():
    # Kunci rotasi dan ukuran sekali di awal.
    if projection == PROJECTION_ORTHOGONAL:
        size = FIXED_ORTHOGONAL_SIZE
    
    global_rotation = FIXED_ROTATION
    
    # Langsung atur posisi Y yang pasti
    global_position.y = FIXED_Y_POSITION


func _physics_process(_delta):
    # PERBAIKAN STABILITAS: Cari Player jika belum ada
    if not is_instance_valid(player):
        # PENTING: Gunakan nama grup yang benar, yaitu "Player" (huruf besar)
        player = get_tree().get_first_node_in_group("Player")
        if not is_instance_valid(player):
            return # Keluar jika Player belum ditemukan
        
    var target_pos = player.global_position
    
    # 1. Atur Posisi Kamera: Ikuti Player di X dan Z, tetapi Kunci Y
    global_position.x = target_pos.x
    global_position.z = target_pos.z
    global_position.y = FIXED_Y_POSITION # Paksa Y ke nilai aman 150.0

    # 2. Pastikan rotasi dan size tidak berubah
    global_rotation = FIXED_ROTATION
    if projection == PROJECTION_ORTHOGONAL:
        size = FIXED_ORTHOGONAL_SIZE
