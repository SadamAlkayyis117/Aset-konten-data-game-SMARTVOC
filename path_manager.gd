extends Node

var paths : Array[Path3D] = []
# Jarak maksimum yang dianggap "dekat" untuk path awal
const MAX_ENTRY_DISTANCE: float = 10.0 

func _ready():
    # Menunggu satu frame memastikan semua node di Scene Tree sudah siap
    await get_tree().process_frame 
    _collect_paths()
    print("PathManager ready. Total path ditemukan: ", paths.size())

# ---------------------------------------------------------
# ✅ Ambil semua Path3D di group "paths"
# ---------------------------------------------------------
func _collect_paths():
    paths.clear()
    
    # Ambil semua node dalam group "paths"
    var list = get_tree().get_nodes_in_group("paths")
    
    if list.is_empty():
        push_error("Tidak ada Path3D yang ditemukan dalam grup 'paths'!")
        return

    for p in list:
        if p is Path3D:
            paths.append(p)
        else:
            # Peringatan jika ada node non-Path3D di grup "paths"
            push_warning("Node '" + p.name + "' ada di grup 'paths' tetapi bukan Path3D.")
            
    if paths.is_empty():
        push_error("Semua node dalam grup 'paths' tidak valid.")


# ---------------------------------------------------------
# ✅ Spawner pakai ini untuk path awal (Nearest Path Logic)
# ---------------------------------------------------------
func get_entry_path_for(spawner: Node3D) -> Path3D:
    var nearest : Path3D = null
    var nearest_dist := INF
    var spawner_pos = spawner.global_transform.origin # Ambil posisi spawner sekali

    if paths.is_empty():
        push_error("PathManager tidak memiliki path. _collect_paths() mungkin gagal.")
        return null # Kembalikan null jika tidak ada path

    for p in paths:
        # PENTING: Hitung jarak dari posisi Spawner ke posisi awal Path
        var d = spawner_pos.distance_to(p.global_transform.origin)
        
        if d < nearest_dist:
            nearest_dist = d
            nearest = p
    
    # Validasi Jarak: Pastikan jalur terdekat berada dalam jarak yang masuk akal
    if nearest_dist > MAX_ENTRY_DISTANCE:
        push_warning("Jalur terdekat (" + nearest.name + ") terlalu jauh dari Spawner: " + str(nearest_dist) + "m")
        return null # Kembalikan null jika terlalu jauh

    return nearest
