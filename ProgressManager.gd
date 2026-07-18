extends Node

# =============================================================
# ====================== SIGNALS ==============================
# =============================================================
signal progress_changed              
signal material_completed(level_id: int) 
signal exam_passed(level_id: int)     
signal vocab_unlocked(word: String)   
signal vocab_batch_unlocked(words: Array) 

# Dictionary<int, Array<Dictionary>>
var level_material_full: Dictionary = {}

# =============================================================
# =============== PLAYER LEVELING SYSTEM ======================
# =============================================================
@export var max_level: int = 100
var level: int = 1
var xp: int = 0
var xp_needed: int = 10        
var xp_growth_rate: float = 1.1
# Level tertinggi vocab yang sudah terbuka
var unlocked_vocab_level : int = 0

# =============================================================
# =============== VOCABULARY MATERIAL PROGRESS ================
# =============================================================
var level_material: Dictionary = {} 
var completed_material: Dictionary = {}
var best_score_material: Dictionary = {}

# =============================================================
# =============== MINI GAME & MISSION STATUS ==================
# =============================================================
var exam_levels: Array[int] = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100] 
var _exam_passed_status: Dictionary = {} 
var best_score_exam: Dictionary = {}
var just_passed_exam: bool = false

# =============================================================
# ===================== VOCAB INDEX DATA ======================
# =============================================================
var vocab_index: Dictionary = {} 

# =============================================================
# =============== CHAPTER EXP COOLDOWN ========================
# =============================================================
var chapter_exp_cooldown: Dictionary = {}
const CHAPTER_EXP_COOLDOWN_TIME := 120 # detik (2 menit)
const CHAPTER_EXP_REWARD := 2

# =============================================================
# ======================== INITIALIZE ==========================
# =============================================================

func _ready():
    _init_material()
    _init_exam()
    _update_xp_needed() 
    print("[ProgressManager] Ready. Level:", level)

func _init_material():
    if not FileAccess.file_exists("res://Materi.json"):
        push_error("[ProgressManager] Materi.json TIDAK DITEMUKAN di res://")
        return
        
    var file = FileAccess.open("res://Materi.json", FileAccess.READ)
    var json_text = file.get_as_text().strip_edges()
    var parsed = JSON.parse_string(json_text)

    if parsed == null or not parsed is Array:
        push_error("[ProgressManager] Gagal parse JSON atau format bukan Array!")
        return

    level_material.clear()
    level_material_full.clear()

    for level_data in parsed:
        if not level_data is Dictionary: continue
        
        var lvl_val := int(level_data.get("level", 0))
        var word_names: Array = []
        var word_full: Array = []

        if level_data.has("words"):
            for w in level_data["words"]:
                var w_name = w.get("word", w.get("en", "unknown"))
                word_names.append(w_name)   
                word_full.append(w)          

        level_material[lvl_val] = word_names
        level_material_full[lvl_val] = word_full

    print("[ProgressManager] Material loaded successfully.")
    
func get_material_full_by_level(level_id: int) -> Array:
    return level_material_full.get(level_id, [])

func _init_exam():
    for e in exam_levels:
        _exam_passed_status[e] = false 
        best_score_exam[e] = 0

func _update_xp_needed():
    # Menghitung ulang XP needed berdasarkan level saat ini
    var current_calc = 10.0 
    for i in range(1, level):
        current_calc *= xp_growth_rate
    xp_needed = int(current_calc)

# =============================================================
# ==================== LEVEL & XP SYSTEM ======================
# =============================================================
func add_xp(amount: int):
    xp += amount
    # Loop jika XP cukup untuk naik lebih dari 1 level sekaligus
    while xp >= xp_needed and level < max_level:
        xp -= xp_needed
        level += 1
        _update_xp_needed() # Update target XP berikutnya
        print("[ProgressManager] Level Up! Now: ", level)
    
    emit_signal("progress_changed") 

func try_add_chapter_exp(book_id: String, chapter_id) -> bool:
    var key := "%s_%s" % [book_id, str(chapter_id)]
    var now := Time.get_unix_time_from_system()

    if chapter_exp_cooldown.has(key):
        var last_time = chapter_exp_cooldown[key]
        if now - last_time < CHAPTER_EXP_COOLDOWN_TIME:
            return false

    # Sukses kasih EXP
    chapter_exp_cooldown[key] = now
    add_xp(CHAPTER_EXP_REWARD)
    return true

# =============================================================
# ================= PROGRESS & VOCAB LOGIC ====================
# =============================================================

func complete_material(level_id: int, score: int):
    completed_material[level_id] = true
    best_score_material[level_id] = max(best_score_material.get(level_id, 0), score)
    emit_signal("material_completed", level_id)

func pass_exam(level_id: int, score: int):
    if not exam_levels.has(level_id): return

    _exam_passed_status[level_id] = true
    best_score_exam[level_id] = max(best_score_exam.get(level_id, 0), score)

    # 🔥 BUKA VOCAB BARU
    if level_id > unlocked_vocab_level:
        unlocked_vocab_level = level_id
        print("[VOCAB] Unlocked up to level:", unlocked_vocab_level)

    emit_signal("exam_passed", level_id)

func get_dictionary_vocab() -> Array:
    var result : Array = []

    for lvl in range(1, unlocked_vocab_level + 1):
        var words = level_material_full.get(lvl, [])
        if words:
            result.append_array(words)

    return result
    
func is_vocab_level_unlocked(level_id: int) -> bool:
    return level_id <= unlocked_vocab_level


func unlock_vocab(word: String):
    if vocab_index.get(word, false) == false:
        vocab_index[word] = true
        emit_signal("vocab_unlocked", word)

func unlock_multiple(words: Array):
    var unlocked_count = 0
    for w in words:
        if vocab_index.get(w, false) == false:
            vocab_index[w] = true
            unlocked_count += 1
    if unlocked_count > 0:
        emit_signal("vocab_batch_unlocked", words)

# =============================================================
# ====================== GETTERS ===============================
# =============================================================
func is_material_completed(level_id: int) -> bool:
    return completed_material.get(level_id, false)

func get_material_by_level(level_id: int) -> Array:
    return level_material.get(level_id, [])
    
func is_exam_passed(level_id: int) -> bool:
    return _exam_passed_status.get(level_id, false)

func is_vocab_unlocked(word: String) -> bool:
    return vocab_index.get(word, false)
