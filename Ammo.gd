extends RigidBody3D

@export var speed: float = 100.0
@export var gravity_scale_custom: float = 1.0
@export var life_time: float = 7.0
@export var stick_on_hit: bool = true
@onready var hitbox: Area3D = $Area3D
var direction: Vector3 = Vector3.ZERO

func _ready():
	gravity_scale = gravity_scale_custom
	hitbox.body_entered.connect(_on_hit)
	await get_tree().create_timer(life_time).timeout
	queue_free()


func launch(dir: Vector3):
	direction = dir.normalized()
	linear_velocity = direction * speed


func _physics_process(delta):
	if linear_velocity.length() > 0.1:
		look_at(global_position + linear_velocity, Vector3.UP)

func _on_hit(body):

	print("HIT:", body.name)

	if body.has_method("on_hit_by_projectile"):
		body.on_hit_by_projectile(self)

	if stick_on_hit:
		linear_velocity = Vector3.ZERO
		gravity_scale = 0
		freeze = true
	else:
		queue_free()
