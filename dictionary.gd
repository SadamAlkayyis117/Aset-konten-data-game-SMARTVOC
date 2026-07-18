extends CanvasLayer

# Node Nomor Halaman (Label Biasa)
@onready var label_no_left  = $"Root/No_ Halaman kiri"
@onready var label_no_right = $"Root/No_ Halaman Kanan"

# Node Isi Materi (RichTextLabel) - Pastikan ini sudah diganti ke RichTextLabel
@onready var label_content_left  = $"Root/Halaman Kiri"
@onready var label_content_right = $"Root/Halaman Kanan"

@onready var btn_prev = $"Root/Button Previous"
@onready var btn_next = $"Root/Button Next"
@onready var btn_back = $Root/ButtonBack

var vocab_pages: Array = []
var current_spread := 0

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    _load_dictionary()
    _refresh_page()

    btn_prev.pressed.connect(_prev_page)
    btn_next.pressed.connect(_next_page)
    btn_back.pressed.connect(_close)

# =================================================
# LOAD & BUILD DICTIONARY (Banyak kata per halaman)
# =================================================
func _load_dictionary():
    vocab_pages.clear()
    var all_words : Array = []
    
    # 1. Kumpulkan semua kata dari ProgressManager
    var all_levels = ProgressManager.level_material_full.keys()
    all_levels.sort()

    for lvl in all_levels:
        for w in ProgressManager.level_material_full[lvl]:
            var word_data = w.duplicate()
            word_data["level_origin"] = lvl
            all_words.append(word_data)

    var unlocked_level = ProgressManager.unlocked_vocab_level

    # 2. Kelompokkan kata ke dalam halaman
    # Misal: 1 halaman muat 3 kata (sesuaikan jumlahnya di sini)
    var words_per_page = 3 
    var pages_content : Array = []
    
    var current_page_text = ""
    var count = 0
    
    for i in range(all_words.size()):
        var data = all_words[i]
        var formatted = ""
        
        # Cek apakah sudah lulus ujian level tersebut
        if data["level_origin"] <= unlocked_level:
            formatted = _format_vocab(data)
        else:
            formatted = "[b]????[/b]\n\n" # Sensor jika belum lulus

        current_page_text += formatted + "\n"
        count += 1
        
        # Jika halaman penuh atau kata terakhir
        if count >= words_per_page or i == all_words.size() - 1:
            pages_content.append(current_page_text)
            current_page_text = ""
            count = 0

    # 3. Gabungkan halaman menjadi Spread (Kiri & Kanan)
    var p := 0
    while p < pages_content.size():
        var left = pages_content[p]
        var right = ""
        if p + 1 < pages_content.size():
            right = pages_content[p+1]
        else:
            right = "[center]Halaman Terakhir[/center]"
        
        vocab_pages.append([left, right])
        p += 2

# =================================================
# FORMAT VOCAB
# =================================================
func _format_vocab(v: Dictionary) -> String:
    var clean = func(key: String):
        var data = v.get(key, "-")
        if data is Array:
            return ", ".join(data).replace("%", "%%") if not data.is_empty() else "-"
        return str(data).replace("%", "%%")

    var word      = clean.call("word").capitalize()
    var meaning   = v.get("meaning", "-").replace("%", "%%")
    var type      = clean.call("pos")
    var synonym   = clean.call("synonym")
    var antonym   = clean.call("antonym")
    var collocation = clean.call("collocation")
    var preposition = clean.call("preposition")
    var tags      = clean.call("tags")

    # FORMAT VISUAL BARU:
    # Kata utama Bold Hitam, arti Hitam. Keterangan menjorok ke dalam.
    var text = "[b][color=black]%s[/color][/b] = arti: %s\n" % [word, meaning]
    text += "[indent]"
    text += "[font_size=14][color=black]" # Ukuran sedikit lebih kecil untuk detail
    text += "Jenis: %s | Sinonim: %s\n" % [type, synonym]
    text += "Antonim: %s\n" % antonym
    text += "Kolokasi: %s\n" % collocation
    text += "Tagar: %s" % tags
    text += "[/color][/font_size]"
    text += "[/indent]\n"
    
    return text

# =================================================
# UI UPDATE
# =================================================
func _refresh_page():
    if vocab_pages.is_empty(): return
        
    var spread = vocab_pages[current_spread]

    # Update Isi Materi (RichTextLabel)
    label_content_left.clear()
    label_content_left.append_text(spread[0])
    
    label_content_right.clear()
    label_content_right.append_text(spread[1])

    # Update Nomor Halaman (Label Biasa)
    label_no_left.text  = "Hal %d" % (current_spread * 2 + 1)
    label_no_right.text = "Hal %d" % (current_spread * 2 + 2)

    _update_nav_button()

func _update_nav_button():
    btn_prev.disabled = current_spread <= 0
    btn_next.disabled = current_spread >= vocab_pages.size() - 1

func _next_page():
    if current_spread < vocab_pages.size() - 1:
        current_spread += 1
        _refresh_page()

func _prev_page():
    if current_spread > 0:
        current_spread -= 1
        _refresh_page()

func _close():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    queue_free()
