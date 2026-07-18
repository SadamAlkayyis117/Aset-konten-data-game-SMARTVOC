extends CanvasLayer

var current_player = null
var current_closet = null

func _ready():

	visible = false

	$Panel/ButtonPee.pressed.connect(_on_pee)
	$Panel/ButtonPoop.pressed.connect(_on_poop)
	$Panel/ButtonClose.pressed.connect(_on_cancel)

func open_menu(player, closet):

	current_player = player
	current_closet = closet

	visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_pee():

	if current_player == null:
		return

	current_player.start_pee(current_closet)

	visible = false

func _on_poop():

	if current_player == null:
		return

	current_player.start_poop(current_closet)

	visible = false

func _on_cancel():

	visible = false
