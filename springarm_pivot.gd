extends Node3D

@export var look_sensitivity: float = 0.5 
@export var camera_return_speed: float = 5.0 
@export var rotation_smoothing: float = 20.0 

const MIN_PITCH = deg_to_rad(-80) 
const MAX_PITCH = deg_to_rad(80)
const BACK_OFFSET = PI 

var is_looking_around: bool = false
var target_yaw: float = 0.0      
var target_pitch: float = 0.0    
var look_timeout: float = 0.0
const LOOK_TIMEOUT_DURATION: float = 0.1 

@onready var spring_arm = $SpringArm3D 
@onready var player = get_parent()       

var visual_root_node: Node3D = null 

func _ready():
    target_yaw = rotation.y 
    target_pitch = spring_arm.rotation.x
    
    visual_root_node = player.get_node_or_null("metarig") 
    
    if not is_instance_valid(visual_root_node):
        printerr("ERROR: Node 'metarig' not found on Player. Auto-centering disabled.")


# ==========================================================
# INPUT MOUSE TERKUNCI (Dipanggil dari Player.gd)
# ==========================================================
func handle_mouse_input(event: InputEventMouseMotion):
    # PAUSE GUARD
    if Engine.time_scale == 0.0:
        return
        
    is_looking_around = true 
    look_timeout = LOOK_TIMEOUT_DURATION
    
    var rotation_delta = event.relative * 0.1 
    
    target_yaw -= deg_to_rad(rotation_delta.x) 
    target_pitch -= deg_to_rad(rotation_delta.y) 
    
    target_pitch = clamp(target_pitch, MIN_PITCH, MAX_PITCH)


# ==========================================================
# FUNGSI LAMA: UNTUK INPUT SENTUHAN/DRAG (NON-MOUSE LOCKED)
# ==========================================================
func _unhandled_input(event):
    # PAUSE GUARD
    if Engine.time_scale == 0.0:
        return
        
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
        return
        
    if event is InputEventScreenDrag:
        is_looking_around = true 
        look_timeout = LOOK_TIMEOUT_DURATION
        get_viewport().set_input_as_handled() 
        
        var rotation_delta = event.relative * look_sensitivity * 0.01 
        
        target_yaw -= rotation_delta.x 
        target_pitch -= rotation_delta.y 
        
        target_pitch = clamp(target_pitch, MIN_PITCH, MAX_PITCH)
        
    elif event is InputEventScreenTouch and not event.pressed:
        is_looking_around = false


# ==========================================================
# KONTROL PERGERAKAN KAMERA 
# ==========================================================
func _physics_process(delta):

    if Engine.time_scale == 0.0:
        return
        
    if is_looking_around:
        look_timeout -= delta
        if look_timeout <= 0.0:
            is_looking_around = false

    # APPLY ROTATION
    rotation.y = lerp_angle(rotation.y, target_yaw, delta * rotation_smoothing)
    spring_arm.rotation.x = lerp(spring_arm.rotation.x, target_pitch, delta * rotation_smoothing)

    # AUTO CENTER ONLY WHEN MOVING
    var player_moving = player.velocity.length() > 0.2

    if player_moving and not is_looking_around and is_instance_valid(visual_root_node):
        
        var forward_yaw = visual_root_node.rotation.y
        var target_follow_yaw = wrapf(forward_yaw + BACK_OFFSET, -PI, PI)
        
        target_yaw = lerp_angle(target_yaw, target_follow_yaw, delta * camera_return_speed)
        target_pitch = lerp(target_pitch, 0.0, delta * camera_return_speed)
