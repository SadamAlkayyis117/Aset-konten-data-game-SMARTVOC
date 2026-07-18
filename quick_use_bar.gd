extends CanvasLayer

@onready var bar_control: Control = $BarControl
@onready var quick_grid: GridContainer = $BarControl/QuickGrid
@onready var option_panel: Panel = $BarControl/OptionPanel
@onready var slot_buttons: Array = [
$BarControl/OptionPanel/Slot1,
$BarControl/OptionPanel/Slot2,
$BarControl/OptionPanel/Slot3,
$BarControl/OptionPanel/Slot4,
$BarControl/OptionPanel/Slot5
]


var grid_slots: Array = []
var selected_grid_index: int = -1

func _ready():
	grid_slots.clear()
	for child in quick_grid.get_children():
		grid_slots.append(child)
	hide()
	
	for i in range(slot_buttons.size()):
		slot_buttons[i].pressed.connect(_on_slot_button_pressed.bind(i))
	option_panel.visible = false
	
	if quick_grid.get_child_count() != QuickUseManager.MAX_SLOTS:
		print("ERROR: Jumlah slot grid tidak sama dengan manager!")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _use_slot(0)
			KEY_2: _use_slot(1)
			KEY_3: _use_slot(2)
			KEY_4: _use_slot(3)
			KEY_5: _use_slot(4)

func _use_slot(index: int):
	var item = QuickUseManager.get_slot_item(index)

	if item == null:
		return

	print("DEBUG: Pakai item dari QuickUse slot", index + 1, ":", item.item_name)

	# Kirim ke player lewat group
	get_tree().call_group("player", "_use_quickuse_slot", index)

func _on_slot_button_pressed(button_index: int):
	if selected_grid_index != -1:
		print("DEBUG: Pilih slot quick use", button_index + 1, "untuk grid index", selected_grid_index)
		# Logic assign ke quick use slot 1-4 (kecilkan visual)
		option_panel.visible = false
		selected_grid_index = -1

func use_slot(index: int):
	match index:
		0: print("Use slot 0")
		1: print("Use slot 1")
		2: print("Use slot 2")
		3: print("Use slot 3")
