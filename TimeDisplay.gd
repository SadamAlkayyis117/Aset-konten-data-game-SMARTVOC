extends Label

@onready var time_manager := get_node_or_null("/root/TimeManager")

func _ready():
    if not is_instance_valid(time_manager):
        return

    # --- BAGIAN PERBAIKAN VISUAL (KUNCI AGAR TAMPIL) ---
    # 1. Buat CanvasLayer lewat code supaya jam selalu di depan (front-most)
    var cl = CanvasLayer.new()
    cl.layer = 100 # Angka tinggi agar tidak tertutup UI lain
    get_tree().root.call_deferred("add_child", cl)
    
    # 2. Pindahkan Label ini ke dalam CanvasLayer tersebut
    reparent.call_deferred(cl)
    
    # 3. Setting posisi dan gaya (agar tidak numpuk di pojok kiri atas 0,0)
    position = Vector2(550, 0) 
    add_theme_font_size_override("font_size", 55) # Pastikan ukuran terlihat
    add_theme_color_override("font_color", Color.WHITE) # Pastikan warna putih
    
    # --- KONEKSI SINYAL ---
    time_manager.game_time_changed.connect(_on_game_time_changed)
    
    # Render awal
    text = time_manager.get_formatted_time()

func _process(_delta):
    # Agar otomatis sembunyi saat di Main Menu atau Loading
    if GM.is_opening or GM.is_loading:
        visible = false
    else:
        visible = true

func _on_game_time_changed(_hour: int, _minute: int):
    # Update teks setiap ada perubahan sinyal dari TimeManager
    text = time_manager.get_formatted_time()
