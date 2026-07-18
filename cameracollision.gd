extends Area3D

@onready var spring_arm = get_parent()
@onready var camera = spring_arm.get_node_or_null("Camera3D")

var default_z_offset: float = 0.0
var target_z_offset: float = 0.0
var collision_detected: bool = false

func _ready():
    # Pastikan Area3D posisi di ujung camera (Z = 0 relatif SpringArm)
    position = Vector3.ZERO
    default_z_offset = 0.0

func _physics_process(delta: float):
    if not is_instance_valid(spring_arm) or not is_instance_valid(camera):
        return
    
    # === POSISI AREA3D SELALU MENGIKUTI CAMERA ===
    # Area3D harus selalu di posisi camera (ujung SpringArm)
    global_position = camera.global_position
    
    # === CHECK COLLISION ===
    var overlapping_bodies = get_overlapping_bodies()
    var overlapping_areas = get_overlapping_areas()
    
    if overlapping_bodies.size() > 0 or overlapping_areas.size() > 0:
        # Ada collision! Tarik camera maju
        collision_detected = true
        
        # Hitung jarak ke objek terdekat
        var min_distance = 999.0
        var collider_name = "Unknown"
        
        for body in overlapping_bodies:
            var dist = global_position.distance_to(body.global_position)
            if dist < min_distance:
                min_distance = dist
                collider_name = body.name
        
        for area in overlapping_areas:
            var dist = global_position.distance_to(area.global_position)
            if dist < min_distance:
                min_distance = dist
                collider_name = area.name
        
        # Target offset = mundur lebih dekat ke player
        target_z_offset = min(0.5, min_distance * 0.8)
        print("💥 Camera Collision Detected! | Objek: %s | Offset: %.2f" % [collider_name, target_z_offset])
    else:
        # Tidak ada collision, kembali normal
        collision_detected = false
        target_z_offset = 0.0
        print("✅ Camera Clear")
    
    # === SMOOTH MOVEMENT ===
    default_z_offset = lerp(default_z_offset, target_z_offset, delta * 10.0)
    
    # === GERAKIN CAMERA ===
    if is_instance_valid(camera):
        camera.position.z = lerp(camera.position.z, default_z_offset, delta * 10.0)
