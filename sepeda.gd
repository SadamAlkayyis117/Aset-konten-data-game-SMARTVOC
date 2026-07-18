extends CharacterBody3D

# =====================
# CONFIG
# =====================
@export var max_speed: float = 14.0
@export var acceleration: float = 18.0
@export var brake_force: float = 22.0
@export var turn_speed: float = 2.2
@export var default_position: Vector3
@export var default_rotation: Vector3
@export var wheel_rotate_speed: float = 6.0
@export var pedal_rotate_speed: float = 10.0
@export var vehicle_id: String = "bike_1"
@export var vehicle_scene_path: String = "res://sepedaBaru.tscn"

# =====================
# NODES
# =====================
@onready var engine_sfx: AudioStreamPlayer3D = $EngineSFX
@onready var mount_area: Area3D = $MountArea
@onready var seat_point: Marker3D = $Sitpoint
@onready var look_at_point: Marker3D = $LookAtPoint
@onready var parking_detector: Area3D = $ParkingDetector
@onready var anim: AnimationPlayer = $AnimationPlayer

const ENGINE_MIN_DB := -18.0
const ENGINE_MAX_DB := -4.0
var mounted_player: CharacterBody3D = null
var can_mount := false
var speed := 0.0
var player_yaw_offset := 0.0
@export var gravity: float = 30.0

# =====================
# READY
# =====================
func _ready():
	floor_snap_length = 0.6
	mount_area.body_entered.connect(_on_body_entered)
	mount_area.body_exited.connect(_on_body_exited)
	add_to_group("bike")
	set_meta("vehicle_id", vehicle_id)
	if "vehicle_scene_path" in self:
		vehicle_scene_path = "res://sepedaBaru.tscn"  # pastikan default
	default_position = global_position
	default_rotation = global_rotation
	await get_tree().process_frame
	apply_parking_state()

# =====================
# INPUT
# =====================
func _input(event):
	if not event.is_action_pressed("Interaksi"):
		return

	if can_mount and mounted_player == null:
		mount_player()
	elif mounted_player:
		dismount_player()

func get_current_parking_area() -> Area3D:
	if parking_detector == null:
		return null

	var areas = parking_detector.get_overlapping_areas()

	for area in areas:
		if area.is_in_group("parking_area"):
			return area

	return null

func apply_parking_state():
	var GM = get_node_or_null("/root/GM")

	if GM == null:
		print("[BIKE] GM belum ready, skip...")
		return

	var parking_id = GM.get_vehicle_parking(vehicle_id)

	if parking_id == "":
		return

	var areas = get_tree().get_nodes_in_group("parking_area")

	for area in areas:
		if "parking_id" in area and area.parking_id == parking_id:
			global_position = area.global_position
			global_rotation = area.global_rotation
			print("[BIKE] Spawn di parking:", parking_id)
			return

# =====================
# PHYSICS
# =====================
func _physics_process(delta):

	# APPLY GRAVITY
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if mounted_player:
		handle_movement(delta)

		mounted_player.global_position = seat_point.global_position
		mounted_player.visual_root.global_rotation.y = global_rotation.y + player_yaw_offset

		if abs(speed) > 0.2:
			if not anim.is_playing():
				anim.play("Bike_Run")
		else:
			anim.stop()
	else:
		velocity.x = 0
		velocity.z = 0
		anim.stop()

	move_and_slide()
	
	if Engine.has_singleton("GM"):
		var GM = get_node("/root/GM")
		if GM == null:
			return
		GM.save_vehicle(self, vehicle_id)
	

# =====================
# MOUNT
# =====================
func _on_body_entered(body):
	if body.is_in_group("player"):
		can_mount = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_mount = false
		
func reset_to_default_position():
	global_position = default_position
	global_rotation = default_rotation

func mount_player():
	var player = get_near_player()
	if player == null:
		return

	mounted_player = player
	speed = 0.0

	player.mode = player.PlayerMode.BIKE
	player.input_locked = true
	player.velocity = Vector3.ZERO
	player.get_node("CollisionShape3D").disabled = true
	player.vehicle_look_target = look_at_point

	# =============================
	# POSISI DUDUK
	# =============================
	player.global_position = seat_point.global_position

	var dir = look_at_point.global_position - seat_point.global_position
	dir.y = 0
	var look_yaw = atan2(dir.x, dir.z)

	player_yaw_offset = look_yaw - global_rotation.y
	player.visual_root.global_rotation.y = look_yaw

	# =============================
	# START BIKE SFX
	# =============================
	if engine_sfx:
		engine_sfx.volume_db = -40
		engine_sfx.pitch_scale = 0.9

		if !engine_sfx.playing:
			engine_sfx.play()


func dismount_player():
	if mounted_player == null:
		return

	var p = mounted_player

	p.get_node("CollisionShape3D").disabled = false
	p.velocity = Vector3.ZERO

	var exit_dir = global_transform.basis.x.normalized()
	p.global_position = global_position + exit_dir * 2.0
	p.visual_root.rotation = Vector3.ZERO
	p.input_locked = false
	p.anim_player.speed_scale = 1.0
	p.velocity = Vector3.ZERO
	p.vehicle_look_target = null
	p.exit_bike()

	var GM = get_node_or_null("/root/GM")

	if GM != null:
		var parking_area = get_current_parking_area()

		if parking_area != null:
			var pid = parking_area.parking_id
			GM.set_vehicle_parked(vehicle_id, pid)
			print("[BIKE] Parked di:", pid)
		else:
			print("[BIKE] Tidak di parking → tetap di posisi sekarang")
			GM.clear_vehicle_parking(vehicle_id)
	else:
		print("[BIKE] GM NULL, skip parking system")

	# =============================
	# STOP BIKE SFX
	# =============================
	if engine_sfx:
		engine_sfx.stop()

	mounted_player = null
	player_yaw_offset = 0.0
	speed = 0.0


# =====================
# MOVEMENT
# =====================
func handle_movement(delta):

	var input_forward = Input.get_action_strength("Maju") - Input.get_action_strength("Mundur")
	var input_turn = Input.get_action_strength("Kanan") - Input.get_action_strength("Kiri")

	# =============================
	# SPEED
	# =============================
	if input_forward != 0:
		speed = move_toward(speed, input_forward * max_speed, acceleration * delta)
	else:
		speed = move_toward(speed, 0, brake_force * delta)

	# =============================
	# ROTATION
	# =============================
	if abs(speed) > 0.2:
		rotation.y -= input_turn * turn_speed * delta * sign(speed)

	# =============================
	# MOVE
	# =============================
	var forward = -transform.basis.z

	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

	# =============================
	# BIKE SFX
	# =============================
	if engine_sfx:

		var speed_ratio = clamp(abs(speed) / max_speed, 0.0, 1.0)

		engine_sfx.pitch_scale = lerp(0.9, 1.4, speed_ratio)

		if speed_ratio > 0.05:
			engine_sfx.volume_db = lerp(-18.0, -4.0, speed_ratio)
		else:
			engine_sfx.volume_db = -40.0
# =====================
# HELPER
# =====================
func get_near_player():
	for body in mount_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return body
	return null

func reset_global_scale(node: Node3D) -> void:
	var gt := node.global_transform
	gt.basis = Basis.IDENTITY
	node.global_transform = gt
	node.scale = Vector3.ONE
