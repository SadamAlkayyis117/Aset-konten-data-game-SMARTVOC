extends CanvasLayer

@onready var header_title := $Root/Story/Titlechapter
@onready var story_text := $Root/Story/Storytext
@onready var route_area := $Root/Choicelist
@onready var button_back := $Root/ButtonBack
@onready var toggle_lang := $Root/ButtonToggle

var current_lang := "en"
var chapter_data : Dictionary = {}
var selected_route : Dictionary = {}
var pages: Array[String] = []
var current_page := 0
var active_book_id := ""
var active_chapter_id = 0
var exp_given_for_this_open := false

# NEW: Timer untuk simulasi baca (decay energy & boost mood/social)
@onready var reading_timer = Timer.new()

func _ready():
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    if button_back:
        button_back.pressed.connect(_close_popup)
    if toggle_lang:
        toggle_lang.pressed.connect(_toggle_language)

    # Setup timer baca (setiap 5 detik cek efek needs)
    reading_timer.wait_time = 5.0
    reading_timer.autostart = false
    reading_timer.timeout.connect(_on_reading_tick)
    add_child(reading_timer)

func open_chapter(book_id: String, chapter_id, lang: String):
    if not is_node_ready():
        await ready
    active_book_id = book_id
    active_chapter_id = chapter_id
    current_lang = lang
    exp_given_for_this_open = false

    if not StoryDatabase.books.has(book_id):
        push_error("Buku tidak ditemukan!")
        return

    var full_book_data = StoryDatabase.books[book_id]

    var found = false
    if full_book_data.has("chapters"):
        for ch in full_book_data.chapters:
            if str(ch.id) == str(chapter_id):
                chapter_data = ch
                found = true
                break

    if not found:
        story_text.text = "Error: Chapter not found."
        return

    _refresh_full_ui()

    # Mulai timer efek needs saat buka chapter
    reading_timer.start()

func _on_reading_tick():
    if not visible: 
        reading_timer.stop()
        return

    # Energy berkurang karena baca lama
    var energy_cost = NeedsManager.get_reading_energy_cost()
    NeedsManager.energy -= energy_cost
    print("[Reading Tick] Energy berkurang:", energy_cost, "→", NeedsManager.energy)

    # Social rendah → baca jadi self-care
    var social_boost = NeedsManager.get_reading_social_boost()
    NeedsManager.social += social_boost
    NeedsManager.mood += social_boost * 0.5
    print("[Reading Tick] Social + Mood boost:", social_boost)

func _refresh_full_ui():
    header_title.text = chapter_data.title.get(current_lang, "No Title")
    _build_route_buttons()

    if selected_route.is_empty():
        story_text.text = "Please select a route..." if current_lang == "en" else "Silakan pilih rute..."
    else:
        var full_text = selected_route.content.get(current_lang, "")
        _build_pages_from_text(full_text)
        _show_page(current_page)

func _build_route_buttons():
    for c in route_area.get_children():
        c.queue_free()
    if not chapter_data.has("routes"): return
    var start_y := 15
    var btn_height := 42
    var spacing := 10
    var current_y := start_y
    for route in chapter_data.routes:
        var btn := Button.new()
        var text_base = route.title.get(current_lang, "???")
        btn.text = ("📘 " if route.get("type") == "canon" else "❓ ") + text_base
        btn.position = Vector2(10, current_y)
        btn.size = Vector2(route_area.size.x - 20, btn_height)
        btn.clip_text = true
        btn.pressed.connect(_on_route_selected.bind(route))
        route_area.add_child(btn)
        current_y += btn_height + spacing

func _on_route_selected(route):
    if selected_route.is_empty() or selected_route.id != route.id:
        if not exp_given_for_this_open:
            var mood_penalty = NeedsManager.get_mood_penalty()
            var exp_multiplier = NeedsManager.get_reading_exp_multiplier()
            var base_exp = 5  # misal base EXP per route
            var final_exp = int(base_exp * exp_multiplier / mood_penalty)
            ProgressManager.add_xp(final_exp)
            print("[Reading EXP] Diberikan:", final_exp, "(mood penalty:", mood_penalty, "multiplier:", exp_multiplier, ")")
            exp_given_for_this_open = true

    if not selected_route.is_empty() and selected_route.id == route.id:
        _next_page_logic()
    else:
        selected_route = route
        var full_text = route.content.get(current_lang, "")
        _build_pages_from_text(full_text)
        _show_page(0)

func _next_page_logic():
    if pages.is_empty(): return
    if current_page < pages.size() - 1:
        _show_page(current_page + 1)
    else:
        _show_page(0)

func _build_pages_from_text(full_text: String):
    pages.clear()
    if full_text == "": return
    var limit_height = story_text.size.y
    var words = full_text.split(" ")
    var buffer = ""
    story_text.modulate.a = 0
    for word in words:
        var test_text = buffer + word + " "
        story_text.text = test_text
        if story_text.get_content_height() > limit_height:
            pages.append(buffer.strip_edges())
            buffer = word + " "
        else:
            buffer = test_text
    if not buffer.is_empty():
        pages.append(buffer.strip_edges())
    story_text.modulate.a = 1

func _show_page(index: int):
    if pages.is_empty():
        return
    current_page = clamp(index, 0, pages.size() - 1)
    story_text.text = pages[current_page]

func _toggle_language():
    current_lang = "id" if current_lang == "en" else "en"
    _refresh_full_ui()
    toggle_lang.move_to_front()

func _input(event):
    if event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        _close_popup()

func _close_popup():
    reading_timer.stop()  # STOP timer efek needs
    queue_free()
