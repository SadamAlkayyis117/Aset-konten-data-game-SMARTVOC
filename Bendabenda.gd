extends RigidBody3D
class_name ItemPickup

@export var item_data: ItemData
@onready var interact_area: Area3D = $InteractArea

var player_inside: Node = null
var throw_impulse: Vector3 = Vector3.ZERO
var should_throw: bool = false
@export var pickup_amount: int = 1

func _ready():
	if not item_data:
		print("ERROR: ItemPickup", name, "tidak punya ItemData!")
		return
	
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	
	# Pastikan monitoring aktif saat di dunia
	interact_area.monitoring = true
	interact_area.monitorable = true
	
	mass = 1.5
	gravity_scale = 1.0
	freeze = false  # pastikan tidak freeze saat spawn/drop
	
	call_deferred("_wait_for_throw_data")


func _on_body_entered(body):
	if body.is_in_group("player") and player_inside == null:
		player_inside = body
		body.current_interactable = self
		print("DEBUG: Player masuk area item:", item_data.item_name)


func _on_body_exited(body):
	if body.is_in_group("player") and player_inside == body:
		player_inside = null

		if body.current_interactable == self:
			body.current_interactable = null

		print("DEBUG: Player keluar area item:", item_data.item_name)

func _wait_for_throw_data():
	await get_tree().process_frame   # tunggu 1 frame
	await get_tree().process_frame   # extra safety

	if should_throw:
		_apply_throw()
	else:
		print("DEBUG: throw data belum masuk")

func _apply_throw():
	sleeping = false
	can_sleep = false

	# 🔥 INI KUNCI UTAMA
	linear_velocity = throw_impulse

	# optional biar muter
	angular_velocity = Vector3(
		randf_range(-3.0, 3.0),
		randf_range(-3.0, 3.0),
		randf_range(-3.0, 3.0)
	)
	
	print("ITEM THROW EXECUTED:", throw_impulse)

func freeze_physics():
	freeze = true
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO

func unfreeze_physics():
	freeze = false

func enable_interaction():
	interact_area.monitoring = true
	interact_area.monitorable = true
	print("ItemPickup: Interaction enabled -", item_data.item_name)

func disable_interaction():
	interact_area.monitoring = false
	interact_area.monitorable = false
	print("ItemPickup: Interaction disabled -", item_data.item_name)


func get_item_data() -> ItemData:
	return item_data
