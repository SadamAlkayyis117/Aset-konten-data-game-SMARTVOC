extends Node3D

@export var max_slots: int = 20  # Ubah di inspector per tas (sekolah=12, hiking=30, dll)

@onready var interact_area: Area3D = $InteractTas
@onready var collider: CollisionShape3D = $Cube/StaticBody3D/CollisionShape3D

var carrier: CharacterBody3D = null
var equipped_to: Node = null
var is_carried: bool = false

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	print("DEBUG TAS: Script tas READY, max_slots:", max_slots, "scene path:", scene_file_path)

func _on_body_entered(body):
	if body.is_in_group("player"):
		carrier = body
		body.current_interactable = self
		print("DEBUG TAS: Body entered - nama:", body.name)

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

	if collider:
		collider.disabled = true

	# UPDATE GM & INVENTORY
	GM.has_backpack = true
	GM.backpack_scene_path = scene_file_path  # ← INI KUNCI! Simpan path scene tas ini
	InventoryManager.max_slots = max_slots

	print("DEBUG TAS: Equipped → GM.backpack_scene_path:", GM.backpack_scene_path)
	print("DEBUG TAS: max_slots inventory di-update menjadi", max_slots)
	print("DEBUG TAS: Equipped dengan aman")

func unequip():
	if not equipped_to:
		return

	var last_player = equipped_to
	var world = get_tree().current_scene
	if world:
		reparent(world)

	is_carried = false
	if collider:
		collider.disabled = false

	scale = Vector3(0.7, 0.7, 0.7)
	var drop_pos = last_player.global_position - (last_player.global_transform.basis.z * 1.2)
	drop_pos.y = last_player.global_position.y + 0.2
	global_position = drop_pos

	# RESET GM & INVENTORY
	GM.has_backpack = false
	GM.backpack_scene_path = ""
	InventoryManager.max_slots = 0

	print("DEBUG TAS: Unequipped → GM.backpack_scene_path di-clear")
	print("DEBUG TAS: max_slots inventory di-reset ke 0 (tanpa tas)")
	print("DEBUG TAS: Unequipped & dropped di world scene")

	equipped_to = null
