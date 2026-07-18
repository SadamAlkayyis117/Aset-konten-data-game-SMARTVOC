extends CanvasLayer

@onready var full_map_canvas = $fullmap  # Ini child bernama "fullmap"

func _ready():
    print("DEBUG CANVAS: _ready dipanggil di root CanvasLayer")
    if is_instance_valid(full_map_canvas):
        print("DEBUG CANVAS: full_map_canvas ditemukan! Nama:", full_map_canvas.name, "Visible awal:", full_map_canvas.visible)
        full_map_canvas.visible = false
        full_map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    else:
        print("DEBUG CANVAS: full_map_canvas NULL! Path $fullmap salah atau node tidak ada!")

func toggle_full_map(visible: bool):

    if is_instance_valid(full_map_canvas):

        if visible:
            full_map_canvas.open_fullmap()
        else:
            full_map_canvas.close_fullmap()

        var sub_viewport_container = full_map_canvas.get_node_or_null("SubViewportContainer")
        if sub_viewport_container:
            sub_viewport_container.visible = visible

        full_map_canvas.mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
    
    # Lock/unlock player input
    var player_node = get_tree().get_first_node_in_group("player")
    if player_node:
        print("DEBUG CANVAS: Player ditemukan, set input_locked ke", visible)
