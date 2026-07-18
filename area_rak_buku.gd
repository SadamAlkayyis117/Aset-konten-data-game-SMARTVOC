extends Area3D

@export var bookshelf_scene: PackedScene

var player_in_range := false
var popup_instance: CanvasLayer = null

func _ready():
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _process(_delta):
    if player_in_range and Input.is_action_just_pressed("Interaksi"):
        _open_bookshelf()

func _on_body_entered(body):
    if body.is_in_group("player"):
        player_in_range = true

func _on_body_exited(body):
    if body.is_in_group("player"):
        player_in_range = false

func _open_bookshelf():
    # Cegah double popup
    if popup_instance != null:
        return

    # Instantiate popup
    popup_instance = bookshelf_scene.instantiate()
    get_tree().root.add_child(popup_instance)

    # Pause game
    get_tree().paused = true
    Engine.time_scale = 0.0

    # Mouse untuk UI
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    # Cleanup otomatis saat popup ditutup
    popup_instance.tree_exited.connect(func():
        popup_instance = null
    )
