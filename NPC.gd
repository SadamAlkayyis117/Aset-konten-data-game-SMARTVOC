extends CharacterBody3D

enum State { WALK, IDLE, TURN }

@export var move_speed: float = 5.0
@export var idle_time: float = 2.0
@export var rotation_speed: float = 5.0
@export var gravity: float = 9.8 # 🟢 Tambahkan Gravity untuk CharacterBody3D

@export var path_a: Path3D
@export var path_b: Path3D
@export var path_c: Path3D

@export var rotation_correction_deg: float = 90.0

var current_state: State = State.WALK

var current_path: Path3D
var curve: Curve3D
var distance := 0.0
var total_length := 0.0
var traveling_forward := true
var ready_to_reverse := false # 🟢 Variabel dari perbaikan sebelumnya

@onready var anim: AnimationPlayer = $AnimationPlayer

var turn_target_y := 0.0


func _ready():
    current_path = path_a
    curve = current_path.curve
    total_length = curve.get_baked_length()

    safe_play("Walk")
    _set_initial_position() # 🟢 Ganti update_position di ready


func _physics_process(delta):
    # --- 1. GRAVITASI (Wajib untuk CharacterBody3D) ---
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    match current_state:
        State.WALK:
            move_along_path(delta)
            # 🟢 Pindahkan posisi ke jalur di sini
            _align_to_path() 
            rotate_to_path(delta)

        State.TURN:
            rotate_to_turn_target(delta)

        State.IDLE:
            pass
            
    # --- 2. Terapkan Pergerakan Fisika ---
    # move_and_slide harus dipanggil setiap frame untuk CharacterBody3D
    move_and_slide()

    update_animation()


# ---------------------------
# PENGGANTI update_position()
# ---------------------------

# 🟢 Dipanggil saat _ready()
func _set_initial_position():
    var pos = curve.sample_baked(distance)
    global_transform.origin = pos
    
# 🟢 Dipanggil setiap frame saat WALK
func _align_to_path():
    # Hitung posisi baru dari curve
    var pos = curve.sample_baked(distance)
    
    # Atur posisi CharacterBody3D (Hanya X dan Z, biarkan Y untuk gravitasi)
    global_transform.origin.x = pos.x
    global_transform.origin.z = pos.z
    # Y diserahkan ke move_and_slide() yang sudah diperbarui oleh gravitasi
    
    
# ---------------------------
# MOVE ALONG PATH (Logika tetap sama)
# ---------------------------
func move_along_path(delta):
    if traveling_forward:
        distance += move_speed * delta
        if distance >= total_length:
            distance = total_length
            ready_to_reverse = true
            start_turn()
    else:
        distance -= move_speed * delta
        if distance <= 0:
            distance = 0
            ready_to_reverse = true
            start_turn()
            
# ---------------------------
# ROTATE TO FOLLOW PATH (Logika tetap sama)
# ---------------------------
func rotate_to_path(delta):
    var ahead_dist: float

    if traveling_forward:
        ahead_dist = distance + 0.3
    else:
        ahead_dist = distance - 0.3

    ahead_dist = clamp(ahead_dist, 0, total_length)

    var ahead_pos = curve.sample_baked(ahead_dist)
    var dir = (ahead_pos - global_transform.origin).normalized()

    if dir.length_squared() < 0.0001:
        return

    var target_y = atan2(dir.x, dir.z)
    var corrected_y = target_y + deg_to_rad(rotation_correction_deg)

    rotation.y = lerp_angle(rotation.y, corrected_y, delta * rotation_speed)


# ---------------------------
# TURN STATE — PUTAR BADAN DULU (Logika tetap sama)
# ---------------------------
func start_turn():
    current_state = State.TURN
    safe_play("Idle")

    var next_dist: float
    if traveling_forward:
        next_dist = distance - 0.3
    else:
        next_dist = distance + 0.3

    next_dist = clamp(next_dist, 0, total_length)
    var next_pos = curve.sample_baked(next_dist)

    var dir = (next_pos - global_transform.origin).normalized()
    
    turn_target_y = atan2(dir.x, dir.z) + deg_to_rad(rotation_correction_deg)


func rotate_to_turn_target(delta):
    rotation.y = lerp_angle(rotation.y, turn_target_y, delta * rotation_speed * 2.0)

    if abs(wrapf(rotation.y - turn_target_y, -PI, PI)) < 0.05:
        rotation.y = turn_target_y 
        start_idle()


# ---------------------------
# IDLE STATE (Logika tetap sama)
# ---------------------------
func start_idle():
    current_state = State.IDLE
    safe_play("Idle")

    await get_tree().create_timer(idle_time).timeout
    
    if ready_to_reverse:
        _finalize_path_change()
        ready_to_reverse = false

    current_state = State.WALK
    safe_play("Walk")


# ---------------------------
# FINALISASI PERUBAHAN JALUR/ARAH (Logika tetap sama)
# ---------------------------
func _finalize_path_change():
    if traveling_forward:
        traveling_forward = false
        choose_new_path()
    else:
        traveling_forward = true
        choose_new_path()

# ---------------------------
# RANDOM PATH PICK (Logika tetap sama)
# ---------------------------
func choose_new_path():
    var paths = [path_a, path_b, path_c]

    if total_length > 0: 
        var new_path = current_path
        while new_path == current_path:
            new_path = paths[randi() % paths.size()]

        current_path = new_path
        curve = new_path.curve
        total_length = curve.get_baked_length()
        distance = 0.0 
        traveling_forward = true 
    
# --- HELPER LAINNYA ---
func lerp_angle(from: float, to: float, weight: float) -> float:
    return from + wrapf(to - from, -PI, PI) * weight

func update_animation():
    match current_state:
        State.IDLE, State.TURN:
            safe_play("Idle")
        State.WALK:
            safe_play("Walk")

func safe_play(name: String):
    if anim == null:
        return
    if not anim.has_animation(name):
        return
    if anim.current_animation != name:
        anim.play(name)
