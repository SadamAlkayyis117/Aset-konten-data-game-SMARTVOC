extends PathFollow3D

# --- PROPERTI YANG DAPAT DIATUR DI INSPECTOR ---
@export var run_speed: float = 10
@export var pause_time: float = 4.0
# 🟢 BARU: Titik jeda untuk animasi "Idle"
@export var idle_points: Array[float] = [0.0] 
# 🟢 BARU: Titik jeda untuk animasi "Boxing"
@export var boxing_points: Array[float] = [0.5] 
@export var tolerance: float = 0.01
@export var rotation_correction: float = 90.0

# --- NODE ONREADY (Struktur Tetap Sama) ---
@export var anim_player_path: NodePath = "NPC Kota 19/AnimationPlayer" 
@onready var anim_player: AnimationPlayer = get_node(anim_player_path)
@onready var mesh: Node3D = anim_player.get_parent() 

# --- STATE MACHINE, TIMER, ETC. (Revisi) ---
enum State { RUNNING, PAUSE_IDLE, PAUSE_BOXING } # 🟢 State Pause Baru
var current_state = State.RUNNING

var timer = Timer.new()
var is_paused_at_point = false
var curve_length = 0.0

func _ready():
    add_child(timer)
    timer.timeout.connect(self._resume_movement)
    timer.one_shot = true
    
    curve_length = get_parent().curve.get_baked_length()
    
    # Sortir dan gabungkan semua titik jeda untuk inisialisasi yang lebih bersih
    idle_points.sort()
    boxing_points.sort()
    
    if progress_ratio <= 0.0 and tolerance > 0.0:
        progress_ratio = 0.001 

    rotation_mode = ROTATION_NONE

    _change_state(State.RUNNING)

func _physics_process(delta):
    if current_state == State.RUNNING:
        progress += run_speed * delta 
        _rotate_to_path()
        _check_for_pause_point()
        
    # 🟢 Tambahkan cek untuk State Pause baru
    elif current_state == State.PAUSE_IDLE or current_state == State.PAUSE_BOXING:
        pass # Diam saat pause

func _check_for_pause_point():
    if is_paused_at_point: return

    # 🟢 Cek Titik Boxing
    for point in boxing_points:
        if abs(progress_ratio - point) < tolerance:
            _change_state(State.PAUSE_BOXING) # Pindah ke state BOXING
            is_paused_at_point = true
            return # Langsung keluar setelah menemukan titik

    # 🟢 Cek Titik Idle (Jika tidak ada titik Boxing yang ditemukan)
    for point in idle_points:
        if abs(progress_ratio - point) < tolerance:
            _change_state(State.PAUSE_IDLE) # Pindah ke state IDLE
            is_paused_at_point = true
            return
            
    # 🟢 Cek Akhir Jalur (Jika loop = true)
    if loop and progress_ratio >= 1.0 - tolerance:
        # Jika jalur looping, kita akan menganggap ujung jalur adalah PAUSE_IDLE
        if not is_paused_at_point:
             _change_state(State.PAUSE_IDLE)
             is_paused_at_point = true


func _change_state(new_state: State):
    current_state = new_state
    
    match current_state:
        State.PAUSE_IDLE: # 🟢 Pause Idle
            anim_player.play("Boxing") 
            timer.start(pause_time)
            
        State.PAUSE_BOXING: # 🟢 Pause Boxing
            anim_player.play("Idle") # 🥊 Animasi Baru
            timer.start(pause_time)
            
        State.RUNNING:
            anim_player.play("Run")
            is_paused_at_point = false 


func _resume_movement():
    # Dorong progress ratio sedikit agar tidak langsung terjebak di titik jeda lagi
    progress_ratio += tolerance * 2 
    _change_state(State.RUNNING)

# --- FUNGSI ROTASI (Tidak Berubah) ---
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
    
    # 2. Hitung vektor arah
    var direction = (next_position - current_position).normalized()
    
    # 3. Hitung sudut target (Yaw)
    var target_angle = atan2(direction.x, direction.z)
    
    # 4. Tambahkan koreksi rotasi yang diekspor
    var corrected_target_angle = target_angle + deg_to_rad(rotation_correction)
    
    # 5. Lakukan interpolasi (Slerp) untuk rotasi yang halus
    var current_angle = mesh.rotation.y
    var interpolated_angle = lerp_angle(current_angle, corrected_target_angle, 0.2)
    
    # 6. Terapkan rotasi
    mesh.rotation.y = interpolated_angle

func lerp_angle(from: float, to: float, weight: float) -> float:
    return from + wrapf(to - from, -PI, PI) * weight
