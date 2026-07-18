extends CanvasLayer

@onready var transition_overlay = $TransitionOverlay as ColorRect
@onready var loading_label = $LabelLoading as Label

var target_scene_path: String = ""
var target_spawn_point_name: String = ""
var is_transitioning: bool = false

func _ready():
	transition_overlay.modulate = Color(0,0,0,0)
	loading_label.visible = false

func fade_out():

	var tween = create_tween()

	tween.tween_property(
		transition_overlay,
		"modulate",
		Color(0, 0, 0, 1),
		0.5
	)

	await tween.finished


func fade_in():

	var tween = create_tween()

	tween.tween_property(
		transition_overlay,
		"modulate",
		Color(0, 0, 0, 0),
		0.5
	)

	await tween.finished
	
# Fungsi utama yang dipanggil oleh trigger pintu
func change_scene_with_transition(path: String, spawn_name: String):

	if is_transitioning:
		return

	is_transitioning = true
	target_scene_path = path
	target_spawn_point_name = spawn_name

	# 🟢 SAVE PLAYER ITEM
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if StoreTransactionManager.unpaid_hand_items.size() > 0 \
		or StoreTransactionManager.unpaid_inventory_items.size() > 0:
			print("🔥 PREVENT SAVE ITEM ILEGAL")
			StoreTransactionManager.clear_all_unpaid(player)
		GM.save_player_items(player)

	# 🔥🔥🔥 TAMBAHAN PALING PENTING
	if Engine.has_singleton("SaveManager"):
		var SM = get_node("/root/SaveManager")
		SM.force_save_all_vehicles()
	loading_label.visible = true
	var tween_in = create_tween()
	tween_in.tween_property(transition_overlay, "modulate", Color(0,0,0,1), 0.5)

	await tween_in.finished
	load_new_scene()

# Diubah menjadi fungsi non-callback untuk menggunakan 'await'
func load_new_scene():
	var error = get_tree().change_scene_to_file(target_scene_path)
	if error != OK:
		push_error("Gagal memuat scene: ", target_scene_path)
		is_transitioning = false
		return
	await get_tree().tree_changed
	call_deferred("position_player_in_new_scene")

func position_player_in_new_scene():

	var new_scene_root = get_tree().get_current_scene()
	if new_scene_root == null:
		push_error("ERROR: Scene root is null after scene change.")
		is_transitioning = false
		return

	# 1. Ambil player
	var player = get_tree().get_first_node_in_group("player") as CharacterBody3D

	# 2. Reparent player ke scene baru
	if is_instance_valid(player) and player.get_parent() != new_scene_root:
		player.reparent(new_scene_root)
		player.owner = new_scene_root

	# 3. Cari spawn point
	var spawn_point = new_scene_root.find_child(target_spawn_point_name, true) as Node3D

	if is_instance_valid(player) and is_instance_valid(spawn_point):

		# 🔹 Posisi player
		player.global_position = spawn_point.global_position
		print("INFO: Player berhasil diposisikan di scene baru.")

		# 🔹 Restore item (dari save sebelumnya)
		GM.restore_player_items(player)

		# 🔥🔥🔥 FIX UTAMA: HAPUS ITEM YANG BELUM DIBAYAR
		if StoreTransactionManager.unpaid_hand_items.size() > 0 \
		or StoreTransactionManager.unpaid_inventory_items.size() > 0:

			print("⚠ PLAYER KELUAR TOKO TANPA BAYAR → ITEM DIHAPUS")
			StoreTransactionManager.clear_all_unpaid(player)

	else:
		if not is_instance_valid(player):
			push_error("ERROR: Player not found in the new scene (Group 'player').")
		if not is_instance_valid(spawn_point):
			push_error("ERROR: Spawn Point '%s' not found in the new scene." % target_spawn_point_name)

	# 4. Fade-in
	var tween_out = create_tween()
	tween_out.tween_property(transition_overlay, "modulate", Color(0, 0, 0, 0), 0.5)

	await tween_out.finished
	loading_label.visible = false
	reset_switcher()

func reset_switcher():
	is_transitioning = false
	target_scene_path = ""
	target_spawn_point_name = ""
