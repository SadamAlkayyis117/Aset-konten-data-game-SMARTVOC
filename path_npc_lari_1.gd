extends PathFollow3D

# --- PROPERTI YANG DAPAT DIATUR DI INSPECTOR ---
@export var run_speed: float = 6           # Kecepatan lari konstan
@export var pause_time: float = 4.0          # Durasi istirahat/lelah
@export var pause_points: Array[float] = [0.0, 0.5] # Titik PathFollow.progress_ratio untuk berhenti
@export var tolerance: float = 0.01          # Toleransi jarak untuk deteksi titik berhenti
@export var rotation_correction: float = 90.0 # Koreksi rotasi awal (derajat) - NILAI INI AKAN DIGUNAKAN DI ROTATE_TO_PATH

# --- NODE ONREADY (Struktur Tetap Sama) ---
@export var anim_player_path: NodePath = "NPC Kota 11/AnimationPlayer" 
@onready var anim_player: AnimationPlayer = get_node(anim_player_path)
@onready var mesh: Node3D = anim_player.get_parent() 

# --- STATE MACHINE, TIMER, ETC. (Tidak Berubah) ---
enum State { RUNNING, PAUSE }
var current_state = State.RUNNING

var timer = Timer.new()
var is_paused_at_point = false
var curve_length = 0.0 

func _ready():
    add_child(timer)
    timer.timeout.connect(self._resume_movement)
    timer.one_shot = true
    
    curve_length = get_parent().curve.get_baked_length()
    pause_points.sort()
    
    if progress_ratio <= 0.0 and tolerance > 0.0:
        progress_ratio = 0.001 

    # --- PERBAIKAN ROTASI OTOMATIS PATHFOLLOW3D (PENTING) ---
    rotation_mode = ROTATION_NONE
    
    # --- KOREKSI ROTASI AWAL DIHAPUS DARI SINI ---
    # mesh.rotate_y(deg_to_rad(rotation_correction)) <--- DIHAPUS!

    _change_state(State.RUNNING)

func _physics_process(delta):
    if current_state == State.RUNNING:
        progress += run_speed * delta 
        _rotate_to_path()
        _check_for_pause_point()
            
    elif current_state == State.PAUSE:
        pass

func _check_for_pause_point():
    if is_paused_at_point: return

    for point in pause_points:
        if abs(progress_ratio - point) < tolerance:
            _change_state(State.PAUSE)
            is_paused_at_point = true
            break

func _change_state(new_state: State):
    current_state = new_state
    
    match current_state:
        State.PAUSE:
            anim_player.play("Idle") 
            timer.start(pause_time)
            
        State.RUNNING:
            anim_player.play("Run")
            is_paused_at_point = false 


func _resume_movement():
    progress_ratio += tolerance * 2 
    _change_state(State.RUNNING)

# --- FUNGSI ROTASI YANG DIPERBAIKI (MENGGANTI look_at) ---
func _rotate_to_path():
    if mesh == null:
        return
    
    var baked_curve = get_parent().curve
    var current_length = baked_curve.get_baked_length() * progress_ratio
    
    # 1. Dapatkan posisi saat ini dan posisi di depan
    var current_position = baked_curve.sample_baked(current_length)
    var next_position_length = current_length + 0.1
    
    if next_position_length > baked_curve.get_baked_length():
        next_position_length -= baked_curve.get_baked_length()
        
    var next_position = baked_curve.sample_baked(next_position_length)
    
    # 2. Hitung vektor arah dari current_position ke next_position
    var direction = (next_position - current_position).normalized()
    
    # 3. Hitung sudut target (Yaw) menggunakan Atan2
    # Atan2(X, Z) memberikan sudut di sumbu Y (rotasi horizontal)
    var target_angle = atan2(direction.x, direction.z)
    
    # 4. Tambahkan koreksi rotasi yang diekspor
    var corrected_target_angle = target_angle + deg_to_rad(rotation_correction)
    
    # 5. Lakukan interpolasi (Slerp) untuk rotasi yang halus
    var current_angle = mesh.rotation.y
    var interpolated_angle = lerp_angle(current_angle, corrected_target_angle, 0.2) # 0.2 adalah kecepatan putar
    
    # 6. Terapkan rotasi
    mesh.rotation.y = interpolated_angle

# Helper function untuk interpolasi sudut secara mulus
func lerp_angle(from: float, to: float, weight: float) -> float:
    # Mengambil jalur rotasi terpendek (wajib untuk rotasi 360 derajat)
    return from + wrapf(to - from, -PI, PI) * weight
