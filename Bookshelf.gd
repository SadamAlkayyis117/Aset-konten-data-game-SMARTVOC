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
        "book_id": "le_morte_darthur",
        "title": "Le Morte d'Arthur",
        "genre": "Reineesans Age"
    },
    "Book2": {
        "book_id": "a_midsummer_nights_dream",
        "title": "A Midsummer Night's Dream",
        "genre": "Elf Folklore"
    },
    "Book3": {
        "book_id": "grimms_fairy_tales",
        "title": "Grimm’s Fairy Tales",
        "genre": "Long Tales"
    },
    "Book4": {
        "book_id": "the_art_of_war",
        "title": "The Art of War",
        "genre": "Historical"
    },
    "Book5": {
        "book_id": "beowulf",
        "title": "Beowulf",
        "genre": "Norse Tales"
    },
    "Book6": {
        "book_id": "the_age_of_fable",
        "title": "The Age of Fable",
        "genre": "Mythology"
    },
    "Book7": {
        "book_id": "the_key_of_solomon",
        "title": "The Key of Solomon",
        "genre": "Grimoire"
    },
    "Book8": {
        "book_id": "the_volsunga_saga",
        "title": "The Völsunga Saga",
        "genre": "Ancient History"
    },
    "Book9": {
        "book_id": "the_divine_comedy_inferno",
        "title": "The Divine Comedy: Inferno",
        "genre": "Darkness"
    },
    "Book10": {
        "book_id": "the_prince",
        "title": "The Prince (Il Principe)",
        "genre": "Medieval Kingdom"
    },
    "Book11": {
        "book_id": "popol_vuh",
        "title": "Popol Vuh",
        "genre": "K'iche' History"
    },
    "Book12": {
        "book_id": "the_jade_emperors_decree",
        "title": "The Jade Emperor's Decree",
        "genre": "Folklore Timur"
    },
    "Book13": {
        "book_id": "valhalla_rising_runes_of_the_alfather",
        "title": "Valhalla Rising: Runes of the Allfather",
        "genre": "Mitologi Nordik"
    },
    "Book14": {
        "book_id": "olympus_the_fall_of_titans",
        "title": "Olympus: The Fall of Titans",
        "genre": "Klasik"
    },
    "Book15": {
        "book_id": "the_book_of_the_dead_aarus_gate",
        "title": "The Book of the Dead: Aaru's Gate",
        "genre": "Sejarah Kuno"
    },
    "Book16": {
        "book_id": "zero_dawn_rise_of_the_machines",
        "title": "Zero Dawn: Rise of the Machines",
        "genre": "Sci-Fi"
    },
    "Book17": {
        "book_id": "endure_and_survive_cordyceps_outbreak",
        "title": "Endure and Survive: Cordyceps Outbreak",
        "genre": "Post-Apocalyptic"
    },
    "Book18": {
        "book_id": "sic_parvis_magna_francis_drakes_journal",
        "title": "Sic Parvis Magna: Francis Drake's Journal",
        "genre": "Petualangan"
    },
    "Book19": {
        "book_id": "the_ghost_way_of_the_samurai",
        "title": "The Ghost: Way of the Samurai",
        "genre": "Aksi"
    },
    "Book20": {
        "book_id": "creed_of_shadows_nothing_is_true",
        "title": "Creed of Shadows: Nothing is True",
        "genre": "Stealth"
    },
    "Book21": {
        "book_id": "sun_stone_prophecies",
        "title": "Sun Stone Prophecies",
        "genre": "Misteri Arkeologi"
    },
    "Book22": {
        "book_id": "journey_to_the_west",
        "title": "Journey to the West",
        "genre": "Wuxia"
    },
    "Book23": {
        "book_id": "the_prose_edda",
        "title": "The Prose Edda",
        "genre": "Norse Myth"
    },
    "Book24": {
        "book_id": "the_iliad",
        "title": "The Iliad",
        "genre": "Epic Poetry"
    },
    "Book25": {
        "book_id": "the_egyptian_book_of_the_dead",
        "title": "The Egyptian Book of the Dead",
        "genre": "Egypt Tales"
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
    var book_id = data.book_id

    # Cek ke Database Asli (StoryDatabase)
    if not StoryDatabase.books.has(book_id):
        push_error("Book ID belum di-load atau salah nama: " + book_id)
        return

    var preview = preview_book_scene.instantiate()
    add_child(preview)
    # Pastikan layer di atas rak buku
    if preview is CanvasLayer: preview.layer = layer + 1
    
    preview.open_book(book_id)

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
