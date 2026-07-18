extends Node3D

@onready var interact_area: Area3D = $InteractPoster
@onready var collider: CollisionShape3D = $"poster lingkungan/StaticBody3D/CollisionShape3D"

var carrier: CharacterBody3D = null
var is_carried := false

var original_parent: Node
var original_transform: Transform3D

func _ready():
    print("Poster Ready")
    original_parent = get_parent()
    original_transform = global_transform

    interact_area.body_entered.connect(_on_body_entered)
    interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
    print("BODY ENTERED:", body.name)
    print("BODY:", body, "GROUPS:", body.get_groups())
    if body.is_in_group("player"):
        print("PLAYER DETECTED")
        carrier = body
        body.current_interactable = self


func _on_body_exited(body):
    if body == carrier and not is_carried:
        body.current_interactable = null
        carrier = null

func pick_up():
    if carrier == null or is_carried:
        return

    is_carried = true
    collider.disabled = true
    carrier.start_pickup()
    MissionManager.spawn_delivery_marker()



func drop():
    if not is_carried:
        return

    if carrier:
        if carrier.mode == carrier.PlayerMode.BIKE:
            return
        if carrier.exiting_bike:
            return

    is_carried = false
    collider.disabled = false

    var space := get_world_3d().direct_space_state
    var ray := PhysicsRayQueryParameters3D.create(
        global_position,
        global_position + Vector3.DOWN * 5
    )
    var hit := space.intersect_ray(ray)
    if hit:
        global_position.y = hit.position.y

    if carrier:
        carrier.start_drop()
        carrier.current_interactable = null

    carrier = null
