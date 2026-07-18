# KursiMejaMakan.gd
extends Area3D

@export var sit_point_path: NodePath
@export var sit_point_with_food_path: NodePath  # 🔥 TAMBAHAN
@export var look_at_path: NodePath

func _ready():
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not body.is_in_group("player"):
		return

	if body.sitting:
		return

	if body.stand_up_lock:
		return

	var point = get_node_or_null(sit_point_path)
	var look_target = get_node_or_null(look_at_path)
	
	# 🔥 GUNAKAN SIT POINT YANG BERBEDA JIKA BAWA MAKANAN
	if body.food_carrying and body.current_carried_item:
		var food_sit_point = get_node_or_null(sit_point_with_food_path)
		if food_sit_point:
			point = food_sit_point

	if point and look_target:
		body.call_deferred("sit_on_dining_chair", get_parent(), point, look_target)
	else:
		print("ERROR: SitPoint / LookAtPoint belum diisi")
