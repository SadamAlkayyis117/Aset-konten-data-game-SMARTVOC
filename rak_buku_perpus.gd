extends CanvasLayer

@onready var tooltip = $Root/Tooltip
@onready var label_title = $Root/Tooltip/LabelJudul
@onready var label_genre = $Root/Tooltip/LabelGenre
@onready var shelf_container = $Root/Shelfcontainer
@onready var button_back = $ButtonBack

# Pastikan kamu drag file 'preview_book.tscn' ke slot ini di Inspector
@export var preview_book_scene: PackedScene

# Mapping nama tombol di scene ke ID buku di database
@onready var books_map := {
    "Book1": {
        "book_id": "world_war_2",
        "title": "World War 2",
        "genre": "World History"
    },
    "Book2": {
        "book_id": "ancient_of_egypt",
        "title": "Ancient Of Egypt",
        "genre": "Egypt History"
    },
    "Book3": {
        "book_id": "ancient_of_egypt_2",
        "title": "Ancient Of Egypt 2",
        "genre": "Egypt History"
    },
    "Book4": {
        "book_id": "rise_of_rome",
        "title": "Rise Of Rome",
        "genre": "Italian History"
    },
    "Book5": {
        "book_id": "joseon",
        "title": "Joseon",
        "genre": "South Korean History"
    },
    "Book6": {
        "book_id": "tokugawa_age",
        "title": "Tokugawa Age",
        "genre": "Japan Feodal"
    },
    "Book7": {
        "book_id": "ming_dynasty",
        "title": "Ming Dynasty",
        "genre": "East History"
    },
    "Book8": {
        "book_id": "han_dynasty",
        "title": "Han Dynasty",
        "genre": "East History"
    },
    "Book9": {
        "book_id": "batavia",
        "title": "Batavia",
        "genre": "Indonesian History"
    },
    "Book10": {
        "book_id": "batavia_2",
        "title": "Batavia 2",
        "genre": "Indonesian History"
    },
    "Book11": {
        "book_id": "majapahit",
        "title": "Majapahit",
        "genre": "Indonesian History"
    },
    "Book12": {
        "book_id": "sriwijaya",
        "title": "Sriwijaya",
        "genre": "Indonesian History"
    },
    "Book13": {
        "book_id": "english_dictionary",
        "title": "English Dictionary",
        "genre": "Knowledge"
    }

}

var tooltip_offset := Vector2(25, 25)
var is_hovering := false

func _ready():
    process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    
    if "minigame_open" in GM:
        GM.minigame_open = true

    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    get_tree().paused = true 

    tooltip.visible = false
    tooltip.set_as_top_level(true)
    
    # Loop berdasarkan tombol yang ada di ShelfContainer
    for child in shelf_container.get_children():
        var btn_name = child.name
        if books_map.has(btn_name):
            child.mouse_entered.connect(_on_book_hover.bind(btn_name))
            child.mouse_exited.connect(_on_book_exit)
            child.pressed.connect(_on_book_pressed.bind(btn_name))

    if button_back:
        button_back.pressed.connect(_on_back_pressed)

func _process(_delta):
    if is_hovering and tooltip.visible:
        _update_tooltip_position()

func _update_tooltip_position():
    var mouse_pos = get_viewport().get_mouse_position()
    var screen_size = get_viewport().get_visible_rect().size
    var t_size = tooltip.get_combined_minimum_size()
    
    var final_pos = mouse_pos + tooltip_offset
    if final_pos.x + t_size.x > screen_size.x: final_pos.x = mouse_pos.x - t_size.x - tooltip_offset.x
    if final_pos.y + t_size.y > screen_size.y: final_pos.y = mouse_pos.y - t_size.y - tooltip_offset.y
    tooltip.global_position = final_pos

func _on_book_hover(btn_name: String):
    var data = books_map[btn_name]
    label_title.text = data.title
    label_genre.text = data.genre
    tooltip.show()
    tooltip.reset_size()
    is_hovering = true

func _on_book_exit():
    tooltip.hide()
    is_hovering = false

func _on_book_pressed(btn_name: String):
    var data = books_map[btn_name]

    if data.book_id == "english_dictionary":
        var dict_scene = preload("res://dictionary.tscn").instantiate()
        add_child(dict_scene)
        # Pastikan Kamus juga bisa jalan saat pause
        dict_scene.process_mode = Node.PROCESS_MODE_ALWAYS 
        if dict_scene is CanvasLayer:
            dict_scene.layer = layer + 1
        return
    # buku lain tetap pakai preview_book
    var preview = preview_book_scene.instantiate()
    add_child(preview)
    if preview is CanvasLayer:
        preview.layer = layer + 1
    preview.open_book(data.book_id)

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _on_back_pressed()

func _on_back_pressed():
    print("[RakBuku] Menutup rak buku...")
    
    # Panggil force_resume dari GM untuk sinkronisasi total
    if GM.has_method("force_resume"):
        GM.force_resume()
    else:
        # Fallback jika fungsi belum ada
        GM.minigame_open = false
        get_tree().paused = false
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    
    # Tunggu 1 frame agar mesin stabil
    await get_tree().process_frame
    
    queue_free()
