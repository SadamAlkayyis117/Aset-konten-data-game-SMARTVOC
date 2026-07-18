extends RigidBody3D

@export var push_force := 2.5
@export var return_force := 40.0
@export var max_return_speed := 100.0

var start_basis : Basis
var start_rotation_y := 0.0

func _ready():

    body_entered.connect(_on_body_entered)

    start_basis = global_transform.basis
    start_rotation_y = rotation.y


func _on_body_entered(body):

    if body.is_in_group("player"):

        var dir = global_position - body.global_position
        dir.y = 0
        dir = dir.normalized()

        apply_impulse(dir * push_force)


func _physics_process(delta):

    var diff = wrapf(start_rotation_y - rotation.y, -PI, PI)

    # gaya balik
    apply_torque(Vector3(0, diff * return_force, 0))

    # rem rotasi biar stop rapih
    angular_velocity.y *= 0.92
