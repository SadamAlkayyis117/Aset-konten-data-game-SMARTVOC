extends Node3D

@onready var interact_area: Area3D = $InteractCat
@onready var collider: CollisionShape3D = $"Sketchfab_model-col/root-col/GLTF_SceneRootNode-col/RootNode (gltf orientation matrix)_0-col/RootNode (model correction matrix)_1-col/cat_fbx_2-col/_3-col/RootNode_4-col/_5-col/GLTF_created_0-col/Skeleton3D/Object_12/StaticBody3D/CollisionShape3D"

var carrier: CharacterBody3D = null
var is_carried := false

var original_parent: Node
var original_transform: Transform3D

func _ready():
    print("Kucing Ready")
    original_parent = get_parent()
    original_transform = global_transform

    interact_area.body_entered.connect(_on_body_entered)
    interact_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body):
    print("CAT BODY ENTERED:", body.get_class(), body.name)
    print("GROUPS:", body.get_groups())
    
    # Ignore StaticBody3D (self collider) dan bukan player
    if not body is CharacterBody3D:
        return
    if not body.is_in_group("player"):
        return
    
    print("CAT PLAYER DETECTED & VALID")
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
    
    var mm := MissionManager
    if mm.current_mission.get("id", "") == "cat_chaos_control":
        if mm.current_marker and is_instance_valid(mm.current_marker):
            var old_pos = mm.current_marker.global_position
            mm.current_marker.global_position = mm.caregiver_base_position
            var player := get_tree().get_first_node_in_group("player")
            if player and player.has_method("set_waypoint"):
                player.set_waypoint(mm.current_marker.global_position)
            print("DEBUG CAREGIVER: Kucing diambil! Markpoint & Arrow pindah dari", old_pos, "ke caregiver di", mm.caregiver_base_position)
    else:
        mm.spawn_delivery_marker()
        print("DEBUG NORMAL: Barang diambil - spawn marker baru di drop point")



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
