extends Control

# Sinyal ini yang akan dihubungkan ke Player.gd
signal analog_output(direction: Vector2) 

# --- Variabel UI ---
@onready var stick_base = $Base 
@onready var stick_icon = $Stick 

# --- Variabel Pergerakan ---
var posVector: Vector2 = Vector2.ZERO
@export var maxLength: float = 200.0
@export var deadzone: float = 5.0 

# --- Variabel Multitouch ---
var is_active: bool = false
var touch_idx: int = -1 
var base_center_global_position: Vector2 

func _ready():
    var base_size: Vector2 = Vector2.ZERO
    var is_base_centered: bool = false
    
    if stick_base is Sprite2D and stick_base.texture:
        base_size = stick_base.texture.get_size()
        if stick_base.centered:
            is_base_centered = true
    else:
        push_error("Stick Base tidak memiliki Texture atau bukan Sprite2D.")
        base_size = Vector2(200, 200)

    # 1. Tentukan Pusat Base
    if is_base_centered:
        base_center_global_position = stick_base.global_position
    else:
        base_center_global_position = stick_base.global_position + (base_size / 2)
    
    # 2. Set posisi awal Stick ke Pusat Base
    stick_icon.global_position = base_center_global_position

    # 3. Sesuaikan maxLength
    if maxLength > base_size.x / 2.0:
        maxLength = base_size.x / 2.0


func _calculate_vector(current_stick_pos: Vector2):
    # Hitung vektor normalisasi dan terapkan deadzone
    var offset_vector = current_stick_pos - base_center_global_position
    
    var new_pos_vector = offset_vector.limit_length(maxLength) / maxLength
    
    # Terapkan Deadzone
    if new_pos_vector.length() * maxLength < deadzone:
        new_pos_vector = Vector2.ZERO
        
    posVector = new_pos_vector
    
    # MEMANCARKAN SINYAL DENGAN OUTPUT BARU
    emit_signal("analog_output", posVector)


func _input(event):
    if event is InputEventScreenTouch:
        if event.pressed:
            var base_texture_size = stick_base.texture.get_size() if stick_base.texture else Vector2(200, 200)
            
            var rect_start_pos: Vector2
            if stick_base.centered:
                rect_start_pos = stick_base.global_position - (base_texture_size / 2)
            else:
                rect_start_pos = stick_base.global_position
                
            var base_rect = Rect2(rect_start_pos, base_texture_size)
            
            if touch_idx == -1 and base_rect.has_point(event.position):
                is_active = true
                touch_idx = event.index
                
                # Tambahkan perhitungan dan pemancaran sinyal saat SENTUHAN PERTAMA
                _calculate_vector(event.position.clamp(rect_start_pos, rect_start_pos + base_texture_size))
                
                get_viewport().set_input_as_handled()
                
        elif event.index == touch_idx:
            # Jari diangkat: Reset semua dan kirim vektor NOL
            is_active = false
            touch_idx = -1 
            
            stick_icon.global_position = base_center_global_position
            
            posVector = Vector2.ZERO 
            emit_signal("analog_output", posVector) # Kirim Vektor NOL segera
            
            get_viewport().set_input_as_handled()


    elif event is InputEventScreenDrag and event.index == touch_idx and is_active:
        
        var current_pos = event.position
        var distance = current_pos.distance_to(base_center_global_position)
        
        # 1. Batasi Posisi Stick Icon
        if distance <= maxLength:
            stick_icon.global_position = current_pos
        else:
            var vector_to_center = current_pos - base_center_global_position
            stick_icon.global_position = base_center_global_position + vector_to_center.normalized() * maxLength
            
        # 2. Hitung Vektor Output dan Pancarkan Sinyal
        _calculate_vector(stick_icon.global_position)
        
        get_viewport().set_input_as_handled()

func _process(delta):
    if not is_active:
        stick_icon.global_position = stick_icon.global_position.lerp(base_center_global_position, delta * 20)
