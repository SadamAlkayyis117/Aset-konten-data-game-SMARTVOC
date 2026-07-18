extends Area3D

# --- PROPERTI YANG HARUS DIATUR DI INSPECTOR ---
@export var door_open_animation_name: String = "Open Door"
@export var model_instance_name: String = "pintu sekolah" # Nama node 3D yang berisi AnimationPlayer

# Asumsi Anda punya scene Label sederhana
const INTERACTION_LABEL = preload("res://interaction_label.tscn") 

# --- REFERENSI NODE ---
# 🌟 KOREKSI: Gunakan get_node_or_null untuk navigasi yang lebih aman 🌟
@onready var animation_player: AnimationPlayer = get_node_or_null(model_instance_name).get_node_or_null("AnimationPlayer")
# 🌟 KOREKSI: Pastikan path ke collider geser akurat 🌟
@onready var collider_geser: CollisionShape3D = $"StaticBody3D/Pintu Buka" # Asumsi Pintu_Buka adalah nama CollisionShape3D

# --- STATE ---
var player_can_interact: bool = false
var door_is_open: bool = false
var is_animating: bool = false 
var interaction_ui = null 

func _ready():
    if !animation_player or !collider_geser:
        push_error("ERROR: Konfigurasi Pintu tidak lengkap. Cek AnimationPlayer atau CollisionShape.")
        set_process(false)
        return
        
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    animation_player.animation_finished.connect(_on_animation_finished)
    collider_geser.set_deferred("disabled", false) 
    hide_interaction_prompt()


func _input(event):
    # 🚨 GUARD BARU: Blokir interaksi jika game di-pause (pengaman)
    if get_tree().paused:
        return
        
    if is_animating:
        print_debug("INPUT [E] DIBLOKIR: Pintu sedang bergerak.")
        return 
    
    if player_can_interact and event.is_action_pressed("Interaksi"):
        print_debug("INPUT [E] DITERIMA. State pintu: " + str(door_is_open))
        if not door_is_open:
            open_door()
        else:
            close_door()

# --- DETEKSI & UI ---

func _on_body_entered(body: Node3D):
    if body.is_in_group("Player"): 
        print_debug("Area Entered: Player terdeteksi. Interaksi AKTIF.")
        player_can_interact = true
        
        if not is_animating:
            show_interaction_prompt()

func _on_body_exited(body: Node3D):
    if body.is_in_group("Player"):
        print_debug("Area Exited: Player keluar. Interaksi DINONAKTIFKAN.")
        player_can_interact = false
        hide_interaction_prompt()

func show_interaction_prompt():
    hide_interaction_prompt() 
    
    interaction_ui = INTERACTION_LABEL.instantiate()
    # 🌟 KOREKSI PENTING: Tambahkan ke Root untuk Layering UI yang benar 🌟
    get_tree().get_root().add_child(interaction_ui) 
    
    var action = "Buka" if not door_is_open else "Tutup"
    print_debug("UI SHOW: Prompt muncul: [E] untuk " + action)
    
    # Asumsi Label berada di root scene INTERACTION_LABEL atau memiliki path yang sama
    var label_node = interaction_ui.get_node_or_null("Label")
    if is_instance_valid(label_node):
        label_node.text = "[E] untuk " + action

func hide_interaction_prompt():
    # 🌟 KOREKSI: Cleanup yang lebih aman dan eksplisit 🌟
    if is_instance_valid(interaction_ui):
        interaction_ui.queue_free()
    interaction_ui = null 

# --- ANIMASI & FISIKA ---

func open_door():
    if animation_player.is_playing() or door_is_open or is_animating: return 
    
    print_debug("ACTION: Memulai animasi BUKA.")
    is_animating = true 
    
    animation_player.play(door_open_animation_name)
    door_is_open = true
    
    if collider_geser:
        # PENTING: Gunakan set_deferred untuk menghindari masalah fisika
        collider_geser.set_deferred("disabled", true) 

func close_door():
    if animation_player.is_playing() or not door_is_open or is_animating: return 
    
    print_debug("ACTION: Memulai animasi TUTUP (mundur).")
    is_animating = true 
    
    # PENTING: Aktifkan collider saat menutup, tapi harus dilakukan setelah animasi selesai
    # Mari kita lakukan ini di _on_animation_finished jika ini adalah animasi menutup
    
    # KOREKSI UTAMA: Gunakan fungsi khusus untuk pemutaran mundur
    animation_player.play_backwards(door_open_animation_name) 
    
    door_is_open = false

# ==========================================================
# --- FUNGSI KONSISTENSI STATE ---
# ==========================================================

func _on_animation_finished(anim_name):
    print_debug("ANIMASI SELESAI: " + anim_name)
    is_animating = false 
    
    # Jika pintu baru saja selesai menutup, aktifkan collision
    if not door_is_open and collider_geser:
         collider_geser.set_deferred("disabled", false)
        
    # Cek apakah Player masih ada di dalam Area3D
    var overlapping_bodies = get_overlapping_bodies()
    var player_still_here = false
    
    for body in overlapping_bodies:
        if body.is_in_group("Player"):
            player_still_here = true
            break
            
    if player_still_here:
        print_debug("POST-ANIMATION CHECK: Player masih di area. Interaksi di-refresh.")
        player_can_interact = true 
        show_interaction_prompt() # Refresh UI
    else:
        print_debug("POST-ANIMATION CHECK: Player keluar selama animasi. Interaksi di-set mati.")
        player_can_interact = false
        hide_interaction_prompt()
        
# ==========================================================
# --- FUNGSI UNTUK INPUT UI (TOMBOL LAYAR) ---
# ==========================================================

func on_ui_interact():
    # 🚨 GUARD BARU: Blokir interaksi jika game di-pause (pengaman)
    if get_tree().paused:
        return

    if is_animating: 
        print_debug("INPUT [UI] DIBLOKIR: Pintu sedang bergerak.")
        return 
    
    if player_can_interact:
        print_debug("INPUT [UI] DITERIMA. State pintu: " + str(door_is_open))
        if not door_is_open:
            open_door()
        else:
            close_door()
