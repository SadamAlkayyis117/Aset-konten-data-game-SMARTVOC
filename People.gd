extends CharacterBody3D

@export var speed: float = 2.0
@export var acceleration: float = 10.0
@export var gravity: float = 9.8
@export var rotation_speed: float = 8.0
@export var debug_text: bool = true
@export var npc_scale: float = 0.5
@export var flip_rotation: bool = false

@export var target_marker: Marker3D
@export var visual_node_path: NodePath = NodePath("metarig")  # Path ke node visual (mesh/skeleton parent)

@onready var anim_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var debug_label := Label3D.new()
@onready var visual_node: Node3D = get_node_or_null(visual_node_path)

var velocity_h: Vector3 = Vector3.ZERO
var moving := false

func _ready():
    print("========================================")
    print("DEBUG: _ready() dipanggil pada NPC:", name)
    print("Visual Node:", visual_node)
    print("Target Marker:", target_marker)
    print("========================================")
    
    scale = Vector3(npc_scale, npc_scale, npc_scale)
    
    # Disable AnimationPlayer untuk test
    if anim_player:
        anim_player.active = false
        print("⚠️ AnimationPlayer DISABLED untuk testing rotasi")
    
    if debug_text:
        debug_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        debug_label.text = "INIT"
        debug_label.position = Vector3(0, 2.0 * npc_scale, 0)
        debug_label.modulate = Color(0, 1, 0)
        add_child(debug_label)

    if target_marker:
        print("🎯 Target NPC:", target_marker.name)
    else:
        print("⚠️ Belum ada target_marker!")

func _physics_process(delta):
    # --- GRAVITY ---
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0.0

    if target_marker == null:
        velocity_h = velocity_h.lerp(Vector3.ZERO, acceleration * delta)
        velocity.x = velocity_h.x
        velocity.z = velocity_h.z
        move_and_slide()
        return

    # --- Hitung arah menuju target ---
    var dir = (target_marker.global_position - global_position)
    dir.y = 0.0
    var dist = dir.length()

    # --- ROTASI VISUAL NODE (bukan CharacterBody3D) ---
    if dist > 0.01 and visual_node != null:
        var dir_norm = dir.normalized()
        var target_angle = atan2(dir_norm.x, dir_norm.z)
        
        if flip_rotation:
            target_angle += PI
        
        target_angle = wrapf(target_angle, -PI, PI)
        var current_angle = wrapf(visual_node.rotation.y, -PI, PI)
        
        var new_angle = lerp_angle(current_angle, target_angle, delta * rotation_speed)
        visual_node.rotation.y = new_angle
        
        print("ROTASI VISUAL | Target: %.0f° | Current: %.0f° | New: %.0f°" % [
            rad_to_deg(target_angle),
            rad_to_deg(current_angle),
            rad_to_deg(new_angle)
        ])

    # --- Movement ---
    if dist < 0.3:
        moving = false
        velocity_h = velocity_h.lerp(Vector3.ZERO, acceleration * delta)
    else:
        moving = true
        var dir_norm = dir.normalized()
        var target_vel = dir_norm * speed
        velocity_h = velocity_h.lerp(target_vel, acceleration * delta)

    velocity.x = velocity_h.x
    velocity.z = velocity_h.z
    move_and_slide()

    if debug_text and visual_node:
        debug_label.text = "Dist: %.2f\nVisual Rot: %.0f°\nVel: %.2f" % [
            dist, 
            rad_to_deg(visual_node.rotation.y),
            velocity_h.length()
        ]
