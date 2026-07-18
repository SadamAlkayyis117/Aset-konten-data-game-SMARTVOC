extends Control

signal waypoint_set(target_position: Vector3)

# ======================================================
# KONFIGURASI UMUM
# ======================================================
const WAYPOINT_MARKER_SCENE = preload("res://waymarker_3.tscn")
const DESTINATION_TOLERANCE: float = 4.0
const MAP_SCALE: float = 1.2
const IS_Z_FLIPPED: bool = false 

# Referensi Node yang di-assign via Inspector
@export var world_node_path: NodePath
@export var minimap_rendering_node: Node

# Variabel yang dideklarasikan di awal (akan disetel di _ready)
var world: Node = null
var player: Node = null
var arrow_indicator: Node = null
var camera_full_map: Camera3D = null
var map_icons_container: Node2D = null

var current_marker: Node3D = null

# --- Variabel Penanganan State ---
var _previous_tree_paused := false
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
# ======================================================


# ======================================================
# KONFIGURASI IKON BANGUNAN
# ======================================================
const BUILDING_ICON_SCENE = preload("res://school_building_icon.tscn")

const BUILDING_LOCATIONS = [
    { "position": Vector3(467.4, 0.0, 37.9), "texture": preload("res://Gedung kelas.png") },
    { "position": Vector3(413.0, 0.0, 343.0), "texture": preload("res://Toilet.png") },
    { "position": Vector3(416.5, 0.0, 440.6), "texture": preload("res://Warehouse.png") },
    { "position": Vector3(83.2, 0.0, 414.6), "texture": preload("res://Teacher Room.jpg") },
    { "position": Vector3(-224.16, 0.0, 302.7), "texture": preload("res://School Stage.png") },
    { "position": Vector3(-222.4, 0.0, -111.0), "texture": preload("res://Gymnasium.png") }
]
# ======================================================


# ======================================================
# FUNGSI INIT (PERBAIKAN KRITIS)
# ======================================================
func _ready():
    # Gunakan call_deferred untuk memastikan semua node dimuat sebelum pencarian Player
    call_deferred("_initialize_map")

func _initialize_map():
    # 1. Mencari Node yang TIDAK Bergantung pada Player (sudah aman)
    world = get_node(world_node_path)
    camera_full_map = $SubViewportContainer/SubViewport/CameraFullMap as Camera3D
    map_icons_container = $SubViewportContainer/SubViewport/MapIcon as Node2D

    # 2. Mencari Player dan Dependensi (Solusi Error Null Instance)
    player = get_tree().get_first_node_in_group("Player") # Asumsi Grup adalah "Player"
    
    if is_instance_valid(player):
        arrow_indicator = player.get_node_or_null("ArrowIndicator")
        
        # KONEKSI SINYAL OTOMATIS: Hubungkan sinyal dari Map ke Player.
        # Sinyal ini akan memanggil player.set_waypoint(target_pos)
        if player.has_method("set_waypoint"):
            waypoint_set.connect(player.set_waypoint.bind())
            print("✅ INFO: Sinyal 'waypoint_set' FullMap berhasil terhubung ke Player.")
        else:
            push_error("ERROR: Player tidak memiliki fungsi 'set_waypoint'. Waypoint tidak akan berfungsi.")
    else:
        push_error("FATAL: Player tidak ditemukan di Scene Tree. Waypoint tidak berfungsi.")

    # 3. Memuat Ikon (Setelah semua referensi ditemukan)
    if is_instance_valid(camera_full_map) and is_instance_valid(map_icons_container):
        print("✅ DEBUG IKON: MapIcons container dan CameraFullMap ditemukan. Memuat ikon...")
        place_building_icons()
    else:
        push_warning("⚠️ DEBUG IKON: Node FullMap Camera/Container tidak ditemukan. Ikon bangunan tidak dimuat.")


# ======================================================
# FUNGSI BANTUAN: BUKA & TUTUP FULL MAP
# ======================================================
func open_fullmap():
    _previous_tree_paused = get_tree().paused
    _previous_mouse_mode = Input.get_mouse_mode()
    get_tree().paused = true
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    
    # KRITIS: Mengunci input Player saat peta terbuka
    if is_instance_valid(player) and player.has_method("set_input_locked"):
        player.set_input_locked(true)
    
    visible = true

func close_fullmap():
    # 1. Mengembalikan state paused
    get_tree().paused = _previous_tree_paused
    
    # 2. KRITIS: Memaksa Mouse Mode Player (Movement Fix)
    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    # 3. Membuka kunci input Player
    if is_instance_valid(player) and player.has_method("set_input_locked"):
        player.set_input_locked(false)
    
    # 4. Menutup visual peta besar
    visible = false

    # 5. Memastikan Minimap kembali terlihat
    if is_instance_valid(minimap_rendering_node):
        minimap_rendering_node.visible = true

# ======================================================
# FUNGSI LAIN (Waypoints dan Collision Check)
# ======================================================
func set_waypoint_marker(target_position: Vector3) -> void:
    if is_instance_valid(current_marker):
        current_marker.queue_free()
        current_marker = null
        
    var waypoint_marker = WAYPOINT_MARKER_SCENE.instantiate()
    var target_parent = world if is_instance_valid(world) else get_tree().get_root()
    target_parent.add_child(waypoint_marker)
    waypoint_marker.global_position = target_position + Vector3(0, 0.5, 0)
    current_marker = waypoint_marker
    
    # Sinyal dikirimkan di _input, tidak perlu di sini lagi
    pass 

func _physics_process(_delta: float) -> void:
    # Tambahkan pengecekan player dan arrow_indicator untuk keamanan
    if not (is_instance_valid(current_marker) and is_instance_valid(player) and is_instance_valid(arrow_indicator)): return
    
    var marker_pos_flat = current_marker.global_position; marker_pos_flat.y = 0.0
    var player_pos_flat = player.global_position; player_pos_flat.y = 0.0
    
    if marker_pos_flat.distance_to(player_pos_flat) < DESTINATION_TOLERANCE:
        current_marker.queue_free(); current_marker = null
        
        # Asumsi ArrowIndicator memiliki properti 'visible'
        arrow_indicator.visible = false 


# ======================================================
# FUNGSI IKON BANGUNAN (BARU)
# ======================================================
func project_3d_to_map(position_3d: Vector3) -> Vector2:
    # Harus ada pengecekan kamera
    if not is_instance_valid(camera_full_map): return Vector2.ZERO 
    return camera_full_map.unproject_position(position_3d)

func place_building_icons():
    if not is_instance_valid(map_icons_container): return

    # Hapus ikon lama jika ada 
    for child in map_icons_container.get_children():
        child.queue_free()
            
    var i = 0
    for building_data in BUILDING_LOCATIONS:
        # 1. Instancing Scene Template
        var icon_instance = BUILDING_ICON_SCENE.instantiate()
        icon_instance.name = "BuildingIcon_%d" % i
        
        # 2. Mengatur Tekstur
        var texture_rect: TextureRect = icon_instance.get_child(0)
        if not is_instance_valid(texture_rect):
            push_error("❌ DEBUG IKON: Child pertama dari BuildingIcon bukan TextureRect atau tidak ditemukan!")
            continue
        
        texture_rect.texture = building_data.texture
        
        # 3. Mengatur Posisi
        var projected_pos = project_3d_to_map(building_data.position)
        
        # Penyesuaian agar ikon berpusat di lokasi yang diproyeksikan (3D -> 2D)
        var offset = texture_rect.size / 2.0
        icon_instance.position = projected_pos - offset
        
        # 4. Tambahkan ke Container Peta
        map_icons_container.add_child(icon_instance)
        i += 1
# ======================================================

# ======================================================
# INPUT MAP (Logika Peta Statis/Absolut)
# ======================================================
func _input(event: InputEvent) -> void:
    if not visible: return
    if not is_instance_valid(player): return
    
    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        if not is_instance_valid(world): return # Pastikan World ada sebelum Raycast

        var click_pos_local = get_local_mouse_position()
        
        if not Rect2(Vector2.ZERO, size).has_point(click_pos_local): return

        var map_center_2d = size / 2.0
        var click_pos_from_center = click_pos_local - map_center_2d

        var dir_x = click_pos_from_center.x
        var dir_z = click_pos_from_center.y
        
        # PERHITUNGAN PALING SEDERHANA DAN STABIL
        var world_x = (dir_x * MAP_SCALE)
        var scaled_z = (dir_z * MAP_SCALE)
        
        # KOREKSI Z-FLIP (Jika diperlukan)
        if IS_Z_FLIPPED:
            scaled_z = -scaled_z
        
        var world_z = scaled_z
        
        # Gunakan posisi Raycast yang lebih tinggi dan rendah
        var from = Vector3(world_x, 1000.0, world_z) # Dari ketinggian 1000
        var to = Vector3(world_x, -100.0, world_z) # Hingga di bawah tanah sedikit

        var world_3d = get_viewport().get_world_3d()
        if world_3d == null: return
        var physics_state = world_3d.get_direct_space_state()
        
        # Collision Mask 1 (Layer 1) digunakan untuk raycasting (tanah)
        var ray_query = PhysicsRayQueryParameters3D.create(from, to)
        ray_query.collision_mask = 1 << 0
        ray_query.exclude = [player]
        
        var result = physics_state.intersect_ray(ray_query)

        if result:
            var target_pos = result.position
            print("✅ Waypoint diset: ", target_pos)
            set_waypoint_marker(target_pos)
            
            # KIRIM SINYAL KE PLAYER (set_waypoint)
            emit_signal("waypoint_set", target_pos) 
            
            call_deferred("close_fullmap")
        else:
            print("⚠️ Raycast gagal. Tidak ada obyek di Layer 1 di XZ:", Vector2(world_x, world_z))
            get_viewport().set_input_as_handled()
