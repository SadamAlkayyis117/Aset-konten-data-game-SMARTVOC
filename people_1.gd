extends Node3D

# ====== EXPORTED PROPERTIES ======
@export var run_speed: float = 6.0
@export var rotation_correction: float = 90.0

@export var npc: Node3D
@export var path_a: Path3D
@export var path_b: Path3D
@export var path_c: Path3D
@export var anim_player_path: NodePath

# ====== ONREADY ======
@onready var anim_player: AnimationPlayer = get_node(anim_player_path)
@onready var mesh: Node3D = anim_player.get_parent()

# ====== INTERNAL ======
var paths: Array[Path3D] = []
var current_path: Path3D
var follow: PathFollow3D
var curve: Curve3D


func _ready():
    paths = [path_a, path_b, path_c]

    _pick_new_path(true)
    anim_player.play("Walk")


func _physics_process(delta):
    if follow == null:
        return

    follow.progress += run_speed * delta

    # Jika sudah lewat ujung path → pindah path
    if follow.progress_ratio >= 1.0:
        _pick_new_path()

    _update_npc_position()
    _update_npc_rotation()


# =====================================================================
#                  PICK NEW PATH (RANDOM)
# =====================================================================
func _pick_new_path(first := false):
    var new_path = paths[randi() % paths.size()]

    if not first:
        while new_path == current_path:
            new_path = paths[randi() % paths.size()]

    current_path = new_path
    curve = current_path.curve

    # Ambil PathFollow di dalam path
    follow = current_path.get_child(0) as PathFollow3D
    follow.progress_ratio = 0.0
    follow.loop = false

    # TELEPORT NPC ke posisi PathFollow awal
    npc.global_position = follow.global_position

    anim_player.play("Walk")


# =====================================================================
#                       NPC POSITION UPDATE
# =====================================================================
func _update_npc_position():
    npc.global_position = follow.global_position


# =====================================================================
#                       ROTATION (VERSI FIXED)
# =====================================================================
func _update_npc_rotation():
    if mesh == null:
        return

    var baked_curve := curve
    var total_len := baked_curve.get_baked_length()
    var cur_len := total_len * follow.progress_ratio
    var next_len := cur_len + 0.1

    if next_len > total_len:
        next_len = total_len

    var pos_now = baked_curve.sample_baked(cur_len)
    var pos_next = baked_curve.sample_baked(next_len)

    var dir = (pos_next - pos_now).normalized()
    var target_angle = atan2(dir.x, dir.z)

    # Koreksi rotasi
    target_angle += deg_to_rad(rotation_correction)

    # Rotasi halus
    mesh.rotation.y = lerp_angle(mesh.rotation.y, target_angle, 0.18)


# Helper
func lerp_angle(from: float, to: float, weight: float) -> float:
    return from + wrapf(to - from, -PI, PI) * weight
