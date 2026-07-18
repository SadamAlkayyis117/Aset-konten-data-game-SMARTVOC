extends Node

# book_id -> book_data
var books: Dictionary = {}

const BOOKS_PATH: String = "res://books/"

func _ready():
    load_all_books()
    print("[StoryDatabase] Loaded books:", books.keys())

func load_all_books():
    books.clear()

    var dir: DirAccess = DirAccess.open(BOOKS_PATH)
    if dir == null:
        push_error("Folder books tidak ditemukan: " + BOOKS_PATH)
        return

    dir.list_dir_begin()
    var file_name: String = dir.get_next()

    while file_name != "":
        if file_name.ends_with(".json"):
            _load_book_file(BOOKS_PATH + file_name)
        file_name = dir.get_next()

    dir.list_dir_end()

func _load_book_file(path: String):
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("Gagal buka file: " + path)
        return

    var text: String = file.get_as_text()
    
    # PERBAIKAN DI SINI:
    # Jangan pakai := jika hasilnya Variant. Pakai var biasa 
    # atau tentukan tipenya secara spesifik.
    var parsed: Variant = JSON.parse_string(text)

    if typeof(parsed) != TYPE_DICTIONARY:
        push_error("Format JSON salah: " + path)
        return

    # Casting ke Dictionary karena kita sudah yakin tipenya benar
    var data: Dictionary = parsed as Dictionary

    if not data.has("book_id"):
        push_error("JSON tanpa book_id: " + path)
        return

    var book_id: String = data.get("book_id", "")
    if book_id == "":
        push_error("book_id kosong di file: " + path)
        return

    books[book_id] = data
    print("✔ Loaded book:", book_id)
