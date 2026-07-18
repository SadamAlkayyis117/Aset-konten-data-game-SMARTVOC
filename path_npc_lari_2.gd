extends PathFollow3D

# --- PROPERTI YANG DAPAT DIATUR DI INSPECTOR ---
@export var run_speed: float = 8.0           # Kecepatan lari konstan
@export var pause_time: float = 4.0          # Durasi istirahat di ujung jalur
@export var rotation_correction: float = -90.0 # Koreksi rotasi awal (sesuaikan nilai ini)

@export var anim_player_path: NodePath = "NPC Kota 17/AnimationPlayer" 

# --- STATE MACHINE ---
enum State { FORWARD, PAUSE, BACKWARD }
var current_state = State.FORWARD

# --- NODE ONREADY ---
@onready var anim_player: AnimationPlayer = get_node(anim_player_path)
@onready var mesh: Node3D = anim_player.get_parent() 

var timer = Timer.new()
var current_progress_direction = 1 
var curve_length = 0.0

func _ready():
    add_child(timer)
    timer.timeout.connect(self._resume_movement)
    timer.one_shot = true
    
    # ✅ PERBAIKAN: Harus FALSE untuk jalur bolak-balik agar tidak teleport
    loop = false 
    
    curve_length = get_parent().curve.get_baked_length() 
    
    # Perbaikan Stuck Awal
    if progress_ratio <= 0.0:
        progress_ratio = 0.01 
    
    if mesh != null:
        mesh.rotation_degrees.y = rotation_correction
    
    _change_state(State.FORWARD)

func _physics_process(delta):
    # Periksa dan inisialisasi curve_length
    if curve_length == 0.0:
        var path_curve = get_parent().curve
        if path_curve != null:
            curve_length = path_curve.get_baked_length()
        if curve_length == 0.0:
            return 
    
    if current_state == State.FORWARD or current_state == State.BACKWARD:
        
        var ratio_change = run_progress_speed() * delta
        
        # 🎯 PERGERAKAN UTAMA: Menggunakan progress_ratio
        progress_ratio += ratio_change 
        
        # Cek batas di setiap frame. Kita biarkan progress_ratio melampaui 0 atau 1
        # sebentar sebelum di-clamping di _check_path_bounds().
        _check_path_bounds() 

        _rotate_to_path()
        

func run_progress_speed() -> float:
    if curve_length == 0: return 0.0
    return current_progress_direction * run_speed / curve_length


# Fungsi baru untuk mengecek batas jalur
func _check_path_bounds():
    # Cek Ujung (Maju): Jika progress_ratio >= 1.0 (melampaui batas akhir)
    if current_progress_direction == 1 and progress_ratio >= 1.0:
        # ✅ CLAMPING: Kunci di 1.0 agar tidak teleport/terlalu jauh
        progress_ratio = 1.0 
        _change_state(State.PAUSE)
        
    # Cek Awal (Mundur): Jika progress_ratio <= 0.0 (melampaui batas awal)
    elif current_progress_direction == -1 and progress_ratio <= 0.0:
        # ✅ CLAMPING: Kunci di 0.0 agar tidak teleport/terlalu jauh
        progress_ratio = 0.0 
        _change_state(State.PAUSE)


# Fungsi untuk mengelola transisi state
func _change_state(new_state: State):
    current_state = new_state
    
    match current_state:
        State.PAUSE:
            anim_player.play("Idle") 
            timer.start(pause_time) 
            
        State.FORWARD:
            current_progress_direction = 1
            anim_player.play("Run")
            
        State.BACKWARD:
            current_progress_direction = -1
            anim_player.play("Run") 


func _resume_movement():
    # Dipanggil setelah PAUSE selesai.
    # Tidak perlu mendorong progress_ratio di sini, cukup ubah arah.
    if current_progress_direction == 1:
        _change_state(State.BACKWARD)
    else:
        _change_state(State.FORWARD)

func _rotate_to_path():
    if mesh == null:
        return
    
    # ⚠️ Rotasi hanya dilakukan jika NPC tidak PAUSE (bergerak)
    if current_state == State.PAUSE:
        return
        
    var baked_curve = get_parent().curve
    var current_length = baked_curve.get_baked_length() * progress_ratio
    
    var current_position = baked_curve.sample_baked(current_length)
    
    # Menggunakan look-ahead yang lebih stabil
    var look_ahead_distance = 0.5 * current_progress_direction 
    var next_position_length = current_length + look_ahead_distance
    
    # Clamp harus menggunakan baked_length()
    next_position_length = clamp(next_position_length, 0.0, baked_curve.get_baked_length())
        
    var next_position = baked_curve.sample_baked(next_position_length)
    
    var direction = (next_position - current_position).normalized()
    
    # Jika vektor arah terlalu kecil (NPC diam), jangan putar
    if direction.length_squared() < 0.0001:
        return
        
    var target_angle = atan2(direction.x, direction.z)
    var corrected_target_angle = target_angle + deg_to_rad(rotation_correction)
    
    var current_angle = mesh.rotation.y
    var interpolated_angle = lerp_angle(current_angle, corrected_target_angle, 0.2)
    
    mesh.rotation.y = interpolated_angle

func lerp_angle(from: float, to: float, weight: float) -> float:
    return from + wrapf(to - from, -PI, PI) * weight
