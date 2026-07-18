extends CanvasLayer

@onready var chapter_list := $Root/Chapterlist
@onready var book_title := $Root/Preview/BookTitle
@onready var chapter_preview := $Root/Preview/ChapterPreview
@onready var button_back := $Root/ButtonBack
@onready var toggle_lang := $Root/ButtonToggle

var current_lang := "en"
var book_id := ""
var book_data : Dictionary = {}
var selected_chapter : Dictionary = {}

func _ready():
    process_mode = Node.PROCESS_MODE_ALWAYS
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    button_back.pressed.connect(_close_popup)
    toggle_lang.pressed.connect(_toggle_language)

func open_book(_book_id: String):
    # Tunggu node siap dulu agar UI tidak error
    if not is_node_ready():
        await ready 
    
    book_id = _book_id
    print("[PreviewBook] Membuka buku ID: ", book_id)
    
    if not StoryDatabase.books.has(book_id):
        push_error("[PreviewBook] Data tidak ditemukan!")
        return
    
    book_data = StoryDatabase.books[book_id]
    _refresh_text()
    _build_chapter_buttons()

func _build_chapter_buttons():
    for c in chapter_list.get_children():
        c.queue_free()

    if not book_data.has("chapters"): return

    var y := 0
    var btn_height := 42
    var spacing := 6

    for chapter in book_data.chapters:
        var btn := Button.new()
        # Ambil judul chapter sesuai bahasa, fallback ke '???'
        var title_text = chapter.title.get(current_lang, "???")
        
        btn.text = "Chapter %s : %s" % [str(chapter.id), title_text]
        btn.position = Vector2(8, y)
        btn.size = Vector2(chapter_list.size.x - 16, btn_height)

        # Bind seluruh data chapter ke tombol
        btn.pressed.connect(_on_chapter_selected.bind(chapter))
        chapter_list.add_child(btn)

        y += btn_height + spacing

func _refresh_text():
    book_title.text = book_data.title.get(current_lang, "No Title")
    
    if selected_chapter.is_empty():
        chapter_preview.text = "Select a chapter..." if current_lang == "en" else "Pilih chapter..."
    else:
        chapter_preview.text = selected_chapter.preview.get(current_lang, "Preview missing")


func _toggle_language():
    current_lang = "id" if current_lang == "en" else "en"
    _refresh_text()
    _build_chapter_buttons()
    # Update preview text jika sudah ada chapter yang dipilih
    if not selected_chapter.is_empty():
        chapter_preview.text = selected_chapter.preview.get(current_lang, "")

func _on_chapter_selected(chapter: Dictionary):
    print("[PreviewBook] Chapter dipilih: ", chapter.id)
    selected_chapter = chapter
    
    # Ambil teks preview, jika tidak ada tampilkan pesan error di layar biar ketahuan
    var text_preview = chapter.preview.get(current_lang, "")
    if text_preview == "":
        chapter_preview.text = "Error: Preview text not found in JSON for " + current_lang
    else:
        chapter_preview.text = text_preview
    
    # Buka popup story
    _open_chapter_story(chapter.id)

func _open_chapter_story(chapter_id):
    var popup_scene := preload("res://chapterstory.tscn")
    var popup := popup_scene.instantiate()
    
    add_child(popup)
    
    # 🔥 FIX: Paksa layer lebih tinggi dari PreviewBook (biar ga ketutup)
    if popup is CanvasLayer:
        popup.layer = self.layer + 10
    
    # Kirim ID Buku dan ID Chapter untuk dicari datanya
    popup.open_chapter(book_id, chapter_id, current_lang)

func _close_popup():
    # Jangan ubah mouse mode ke Captured di sini kalau RakBuku masih kebuka
    # RakBuku yang akan handle mouse capture saat dia ditutup
    queue_free()
