extends Area3D

@export var sit_point_path: NodePath   
@export var look_at_path: NodePath    

func _ready():
	monitoring = true 
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player"):
		if not body.sitting and not body.stand_up_lock:
			var point = get_node_or_null(sit_point_path)
			var look_target = get_node_or_null(look_at_path)
			
			if point and look_target:
				body.sit_on_classroom_chair(get_parent(), point, look_target)
			else:
				print("ERROR: Pastikan SitPoint dan LookAtPoint sudah diisi di Inspector!")
