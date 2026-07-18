extends Node3D

@export var max_slots: int = 20  
@export var interact_area: Area3D
@export var collider: CollisionShape3D

var carrier: CharacterBody3D = null
var equipped_to: Node = null
var is_carried: bool = false

func _ready():

	if GM.backpack_taken:
		for bp in get_tree().get_nodes_in_group("backpack"):
			bp.queue_free()

	if not interact_area:
		print("ERROR TAS: interact_area belum di-assign di inspector")
		return

	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

	print("DEBUG TAS: READY | max_slots:", max_slots, "| scene:", scene_file_path)

func _on_body_entered(body):
	if body.is_in_group("player"):
		carrier = body
		body.current_interactable = self
		print("DEBUG TAS: Player masuk area")

func _on_body_exited(body):
	if body == carrier and not is_carried:
		body.current_interactable = null
		carrier = null

func is_backpack() -> bool:
	return true

func equip(player: Node):

	if not is_inside_tree():
		await get_tree().process_frame

	equipped_to = player
	is_carried = true

	var back_point = player.get_node_or_null("metarig/BackPoint")
	if not back_point:
		print("ERROR TAS: BackPoint tidak ditemukan!")
		return

	if get_parent() == null:
		print("ERROR TAS: Tidak punya parent sebelum equip")
		return

	reparent(back_point)
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	scale = Vector3(0.2, 0.2, 0.2)

	# 🔥 DISABLE COLLIDER SAAT DIPAKAI
	if collider:
		collider.disabled = true
	else:
		print("WARNING TAS: collider belum di-assign")

	# 🔥 UPDATE GLOBAL
	GM.has_backpack = true
	GM.backpack_taken = true
	GM.backpack_scene_path = scene_file_path
	InventoryManager.max_slots = max_slots

	print("DEBUG TAS: Equipped | slots:", max_slots)

func unequip():

	if not equipped_to:
		return

	var last_player = equipped_to
	var world = get_tree().current_scene

	if world:
		reparent(world)

	is_carried = false

	# 🔥 ENABLE COLLIDER KEMBALI
	if collider:
		collider.disabled = false

	scale = Vector3(0.7, 0.7, 0.7)

	var drop_pos = last_player.global_position - (last_player.global_transform.basis.z * 1.2)
	drop_pos.y = last_player.global_position.y + 0.2
	global_position = drop_pos

	# 🔥 RESET GLOBAL
	GM.has_backpack = false
	GM.backpack_taken = false
	GM.backpack_scene_path = ""
	InventoryManager.max_slots = 0

	equipped_to = null

	print("DEBUG TAS: Unequipped & dropped")
