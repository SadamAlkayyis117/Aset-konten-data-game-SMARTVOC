extends Control

@onready var list_scroll = $Panel_background/ScrollContainer
@onready var note_box = $Panel_background/ScrollContainer/VBoxContainer

@onready var btn_add = $Panel_background/ButtonAdd
@onready var btn_close = $Panel_background/Button_Close

@onready var editor = $Panel_background/EditorPanel
@onready var btn_back = $Panel_background/EditorPanel/Button_CloseEditor
@onready var btn_menu = $Panel_background/EditorPanel/Button_Close

@onready var title_edit = $Panel_background/EditorPanel/LineEdit
@onready var body_edit = $Panel_background/EditorPanel/RichTextLabel

@onready var canvas = $Panel_background/EditorPanel/ColorRect
@onready var btn_text = $Panel_background/EditorPanel/ButtonTeksMode
@onready var btn_canvas = $Panel_background/EditorPanel/ButtonCanvasMode
@onready var btn_color = $Panel_background/EditorPanel/ButtonColour

@onready var menu_panel = $Panel_background/PanelMenu
@onready var btn_save = $Panel_background/PanelMenu/Button_Save
@onready var btn_delete = $Panel_background/PanelMenu/Button_Delete


var notes_path = "user://notes/"
var current_id = ""
var is_new_note = true

var draw_mode = false
var draw_color = Color.BLACK
var lines = []


func _ready():

    visible = false

    editor.visible = false
    menu_panel.visible = false
    canvas.visible = false

    DirAccess.make_dir_recursive_absolute(notes_path)

    btn_add.pressed.connect(_new_note)
    btn_close.pressed.connect(close_app)

    btn_back.pressed.connect(_back_editor)
    btn_menu.pressed.connect(_toggle_menu)

    btn_save.pressed.connect(_save_note)
    btn_delete.pressed.connect(_delete_note)

    btn_text.pressed.connect(_mode_text)
    btn_canvas.pressed.connect(_mode_canvas)
    btn_color.pressed.connect(_change_color)

    load_notes()


func open_app():
    visible = true
    load_notes()

func close_app():

    visible = false
    editor.visible = false
    menu_panel.visible = false

    if get_parent().has_method("close_current_app"):
        get_parent().close_current_app()

    # 🔥 BUKA INPUT PLAYER LAGI
    var phone = get_parent()

    if phone.player_ref:
        phone.player_ref.set_input_locked(false)


func load_notes():

    for c in note_box.get_children():
        c.queue_free()

    var dir = DirAccess.open(notes_path)
    if dir == null:
        return

    dir.list_dir_begin()

    while true:

        var file = dir.get_next()

        if file == "":
            break

        if file.ends_with(".json"):
            _create_note_card(file)

    dir.list_dir_end()



func _create_note_card(file_name):

    var path = notes_path + file_name

    var f = FileAccess.open(path, FileAccess.READ)
    if f == null:
        return

    var data = JSON.parse_string(f.get_as_text())
    f.close()

    var btn = Button.new()
    btn.custom_minimum_size = Vector2(0,110)
    btn.text = data.title + "\n" + data.date + "   " + data.time
    btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
    btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    btn.pressed.connect(func():
        _open_note(file_name)
    )

    note_box.add_child(btn)


func _new_note():

    is_new_note = true
    current_id = ""

    title_edit.text = ""
    body_edit.text = ""

    lines.clear()
    canvas.queue_redraw()

    editor.visible = true
    menu_panel.visible = false


func _open_note(file_name):

    var path = notes_path + file_name

    var f = FileAccess.open(path, FileAccess.READ)
    if f == null:
        return

    var data = JSON.parse_string(f.get_as_text())
    f.close()

    current_id = file_name
    is_new_note = false

    title_edit.text = data.title
    body_edit.text = data.body

    editor.visible = true
    menu_panel.visible = false


func _back_editor():

    editor.visible = false
    menu_panel.visible = false
    canvas.visible = false


func _toggle_menu():

    menu_panel.visible = !menu_panel.visible


func _save_note():

    var file_name = current_id

    if is_new_note:
        file_name = "note_" + str(Time.get_unix_time_from_system()) + ".json"

    var dt = Time.get_datetime_dict_from_system()

    var data = {
        "title": title_edit.text,
        "body": body_edit.text,
        "date": "%02d/%02d/%04d" % [dt.day, dt.month, dt.year],
        "time": "%02d:%02d" % [dt.hour, dt.minute]
    }

    var f = FileAccess.open(notes_path + file_name, FileAccess.WRITE)
    f.store_string(JSON.stringify(data))
    f.close()

    current_id = file_name
    is_new_note = false

    editor.visible = false
    menu_panel.visible = false

    load_notes()


func _delete_note():

    if current_id == "":
        editor.visible = false
        return

    DirAccess.remove_absolute(notes_path + current_id)

    editor.visible = false
    menu_panel.visible = false

    load_notes()


func _mode_text():

    draw_mode = false
    canvas.visible = false


func _mode_canvas():

    draw_mode = true
    canvas.visible = true



func _change_color():

    if draw_color == Color.BLACK:
        draw_color = Color.RED
    elif draw_color == Color.RED:
        draw_color = Color.BLUE
    elif draw_color == Color.BLUE:
        draw_color = Color.GREEN
    else:
        draw_color = Color.BLACK



func _gui_input(event):

    if not draw_mode:
        return

    if not canvas.visible:
        return

    if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):

        lines.append({
            "pos": canvas.get_local_mouse_position(),
            "color": draw_color
        })

        canvas.queue_redraw()


func _draw():

    if not canvas.visible:
        return

    for i in range(lines.size() - 1):

        draw_line(
            lines[i].pos,
            lines[i + 1].pos,
            lines[i].color,
            3.0
        )
