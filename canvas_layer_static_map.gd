extends CanvasLayer 

# --- PATH KE NODE UI ---
# HAPUS: @onready var minimap_container_root = $MinimapContainer
@onready var full_map_canvas = $fullmap2 # Pastikan nama Node ini "$fullmap"

func _ready():
    # Pastikan Full Map disembunyikan dan Mouse Filter diatur ke IGNORE saat game dimulai
    if is_instance_valid(full_map_canvas):
        full_map_canvas.visible = false
        full_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
        
    # HAPUS: if is_instance_valid(minimap_container_root): ...

# Fungsi ini dipanggil untuk mengganti tampilan (toggle)
func toggle_full_map(visible: bool):
    
    # 1. Mengatur Visibilitas dan Mouse Filter pada Full Map
    if is_instance_valid(full_map_canvas):
        full_map_canvas.visible = visible
        
        # MENGATUR MOUSE FILTER DI RUNTIME
        if visible:
            full_map_canvas.mouse_filter = Control.MOUSE_FILTER_STOP
        else:
            full_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
            
    # HAPUS: Logika minimap_container_root.visible = !visible

    # 2. MENGATUR KUNCI INPUT PEMAIN
    # Pastikan grup Player Anda menggunakan huruf besar "Player" sesuai Stack Trace sebelumnya.
    var player_node = get_tree().get_first_node_in_group("Player")
    
    if player_node:
        if player_node.has_method("set_input_locked"):
            player_node.set_input_locked(visible)
        elif player_node.has_member("input_locked"):
            player_node.input_locked = visible
