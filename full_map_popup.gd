extends Control

signal waypoint_set(target_position: Vector3)

@export var map_min_x: float = -300.0
@export var map_max_x: float = 300.0
@export var map_min_z: float = -300.0
@export var map_max_z: float = 300.0

@export var world_node_path: NodePath
@export var waypoint_scene: PackedScene
@export var destination_tolerance: float = 4.0
@export var minimap_nodepath: NodePath

var world: Node3D = null
var player: CharacterBody3D = null
var arrow_indicator: Node3D = null
var current_marker: Node3D = null
var minimap_node: Control = null

# jangan beri typing yang ketat — biarkan sebagai Variant supaya null diizinkan
var _pending_waypoint = null

func _ready():
    print_debug("\n===== FULLMAP READY =====")
    print_debug("Fullmap size:", size)

    world = get_node_or_null(world_node_path)
    minimap_node = get_node_or_null(minimap_nodepath)

    print_debug("World node:", world)
    print_debug("Minimap node:", minimap_node)

    call_deferred("_refresh_player")

    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE


func _refresh_player():
    print_debug("\n[Fullmap] refresh_player called.")
    player = get_tree().get_first_node_in_group("Player")

    print_debug("Player found:", player)

    if is_instance_valid(player):
        arrow_indicator = player.get_node_or_null("ArrowIndicator")
        print_debug("Arrow indicator:", arrow_indicator)


func open_fullmap():
    print_debug("\n[Fullmap] OPEN FULLMAP called!")

    # ❌ JANGAN PAUSE TREE
    # get_tree().paused = true

    # 🟢 Cukup kunci input player + tunjukkan mouse
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    if is_instance_valid(player) and player.has_method("set_input_locked"):
        player.set_input_locked(true)

    if is_instance_valid(minimap_node):
        minimap_node.visible = false

    visible = true
    mouse_filter = Control.MOUSE_FILTER_STOP

    print_debug("Fullmap is now VISIBLE:", visible)


func close_fullmap():
    print_debug("\n[Fullmap] CLOSE FULLMAP called!")

    # ❌ JANGAN UNPAUSE TREE (karena memang tidak dipause)
    # get_tree().paused = false

    Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

    if is_instance_valid(player) and player.has_method("set_input_locked"):
        player.set_input_locked(false)

    visible = false
    mouse_filter = Control.MOUSE_FILTER_IGNORE

    if is_instance_valid(minimap_node):
        minimap_node.visible = true

    print_debug("Fullmap is now HIDDEN:", visible)


func _input(event):
    if not visible:
        return

    if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
        print_debug("\n[Fullmap] CLICK DETECTED!")
        print_debug("Mouse pos local:", get_local_mouse_position())
        
        _handle_map_click(get_local_mouse_position())


func _unhandled_input(event):
    if visible and event.is_action_pressed("ui_cancel"):
        print_debug("[Fullmap] ESC pressed → closing")
        close_fullmap()
        get_viewport().set_input_as_handled()


func _handle_map_click(mouse_pos: Vector2):
    print_debug("\n===== HANDLE MAP CLICK =====")
    print_debug("Click pos:", mouse_pos)
    print_debug("Fullmap size:", size)

    if not Rect2(Vector2.ZERO, size).has_point(mouse_pos):
        print_debug("Click OUTSIDE map!")
        return

    var uv = mouse_pos / size
    uv.x = clamp(uv.x, 0, 1)
    uv.y = clamp(uv.y, 0, 1)

    print_debug("UV:", uv)

    var world_x = lerp(map_min_x, map_max_x, uv.x)
    var world_z = lerp(map_min_z, map_max_z, uv.y)

    var wp = Vector3(world_x, 0, world_z)
    print_debug("Generated world waypoint:", wp)

    # simpan waypoint sementara, tutup peta, lalu apply deferred (menghindari freeze)
    _pending_waypoint = wp
    close_fullmap()
    call_deferred("_apply_pending_waypoint")


func _apply_pending_waypoint():
    if _pending_waypoint == null:
        return

    var wp = _pending_waypoint
    _pending_waypoint = null

    print_debug("[Fullmap] APPLY pending waypoint:", wp)

    # lakukan instancing marker secara deferred untuk keamanan timing
    set_waypoint_marker_deferred(wp)
    emit_signal("waypoint_set", wp)


func set_waypoint_marker_deferred(target_position: Vector3):
    call_deferred("_inst_marker", target_position)


func _inst_marker(target_position: Vector3):
    print_debug("[Fullmap] _inst_marker target:", target_position)

    if is_instance_valid(current_marker):
        print_debug("[Fullmap] Removing old marker:", current_marker)
        current_marker.queue_free()
        current_marker = null

    if waypoint_scene == null:
        push_error("[Fullmap] waypoint_scene NOT SET")
        return

    var marker = waypoint_scene.instantiate()
    var parent = (world if is_instance_valid(world) else get_tree().get_root())

    if is_instance_valid(parent):
        parent.add_child(marker)
    else:
        push_error("ERROR: Cannot add waypoint marker. Parent node is invalid.")
        return

    # set posisi marker
    marker.global_position = target_position + Vector3(0, 0.5, 0)
    current_marker = marker

    print_debug("Marker final position:", marker.global_position)

    if is_instance_valid(arrow_indicator):
        arrow_indicator.visible = true


func _physics_process(delta):
    if not is_instance_valid(player):
        print_debug("[Fullmap] Player missing → refreshing...")
        _refresh_player()
        return

    if not is_instance_valid(current_marker):
        return

    var mp = current_marker.global_position; mp.y = 0
    var pp = player.global_position; pp.y = 0

    print_debug("\n[Fullmap] Checking waypoint distance")
    print_debug("Player:", pp)
    print_debug("Marker:", mp)
    print_debug("Distance:", mp.distance_to(pp))

    if mp.distance_to(pp) < destination_tolerance:
        print_debug("[Fullmap] Waypoint reached → removing marker!")
        current_marker.queue_free()
        current_marker = null
        if is_instance_valid(arrow_indicator):
            arrow_indicator.visible = false
