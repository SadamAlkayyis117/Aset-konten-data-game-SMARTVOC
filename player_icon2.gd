extends Node2D

# Referensi ke Player 3D Anda (akan ditemukan saat runtime)
var player_3d: Node3D = null

# Referensi ke Camera Minimap
var camera_minimap: Camera3D = null

# Skala atau Zoom yang Sama dengan yang digunakan Minimap (Size Orthogonal)
# Ganti dengan nilai Size Orthogonal CameraMinimap Anda (contohnya 250.0)
const MINIMAP_SIZE: float = 250.0 
# Ukuran Viewport Minimap (lebar / tinggi dalam piksel UI, misal 500x500)
# Ganti dengan ukuran sebenarnya dari Viewport Minimap Anda
const VIEWPORT_PIXEL_SIZE: float = 512.0 

# Rasio antara World Unit dan Pixel Unit
const WORLD_TO_PIXEL_RATIO: float = VIEWPORT_PIXEL_SIZE / (2.0 * MINIMAP_SIZE)


func _ready():
    # Cari Player (yang ada di Group "player")
    player_3d = get_tree().get_first_node_in_group("Player")
    if not is_instance_valid(player_3d):
        push_error("Player 3D tidak ditemukan di grup 'player'!")
        return

    # Cari Camera Minimap
    camera_minimap = get_parent().find_child("Cameraminimap")
    if not is_instance_valid(camera_minimap):
        push_error("Cameraminimap tidak ditemukan!")
        return
        
    # Pastikan ikon terlihat
    show()


func _process(_delta):
    if not is_instance_valid(player_3d) or not is_instance_valid(camera_minimap):
        return

    # 1. MENDAPATKAN POSISI (X, Z) PLAYER 3D
    var player_3d_pos = player_3d.global_position

    # 2. MENDAPATKAN POSISI KAMERA MINIMAP (X, Z)
    # Kamera Minimap harusnya mengikuti Player di XZ
    var camera_3d_pos = camera_minimap.global_position
    
    # 3. MENGHITUNG POSISI RELATIF di Peta 2D
    # (X_relatif, Z_relatif) = (Posisi Player - Posisi Kamera)
    var relative_pos_3d = player_3d_pos - camera_3d_pos

    # 4. MENGUBAH WORLD UNIT (3D) ke PIXEL UNIT (2D)
    # X World -> X Pixel
    # Z World -> Y Pixel (karena peta top-down)
    var minimap_x = relative_pos_3d.x * WORLD_TO_PIXEL_RATIO
    var minimap_y = relative_pos_3d.z * WORLD_TO_PIXEL_RATIO
    
    # 5. MENGATUR POSISI IKON (di tengah Viewport, 0,0 adalah pusat)
    # Viewport 2D Anda merender dari (0,0) hingga (VIEWPORT_PIXEL_SIZE, VIEWPORT_PIXEL_SIZE)
    # Karena (0,0) adalah sudut kiri atas, kita geser hasil perhitungan ke tengah:
    position.x = minimap_x + (VIEWPORT_PIXEL_SIZE / 2.0)
    position.y = minimap_y + (VIEWPORT_PIXEL_SIZE / 2.0)
    
    # 6. MENGATUR ROTASI (Ikon harus berputar sesuai arah Player)
    # Godot 3D: Rotasi Y (yaw) -> Godot 2D: Rotasi Z (panah)
    rotation = player_3d.global_rotation.y
