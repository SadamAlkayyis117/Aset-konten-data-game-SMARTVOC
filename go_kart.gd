extends CharacterBody3D

# =====================
# CONFIG
# =====================
@export var max_speed: float = 44.0
@export var acceleration: float = 46.0
@export var brake_force: float = 57.0
@export var turn_speed: float = 3.6
var default_speed := 44.0
var boost_speed := 120.0

@export var wheel_rotate_speed: float = 5.0
@export var pedal_rotate_speed: float = 7.0

# =====================
# NODES
# =====================
@onready var engine_sfx: AudioStreamPlayer3D = $EngineSFX
@onready var mount_area: Area3D = $MountArea
@onready var seat_point: Marker3D = $Sitpoint
@onready var look_at_point: Marker3D = $LookAtPoint
@onready var anim: AnimationPlayer = $AnimationPlayer

var mounted_player: CharacterBody3D = null
var can_mount := false
var speed := 0.0
var player_yaw_offset := 0.0
@export var gravity: float = 45.0

# =====================
# READY
# =====================
func _ready():
	floor_snap_length = 0.9
	mount_area.body_entered.connect(_on_body_entered)
	mount_area.body_exited.connect(_on_body_exited)
	GoKartMissionController.mission_finished.connect(_on_mission_finish)

# =====================
# INPUT
# =====================
func _input(event):
	if not event.is_action_pressed("Interaksi"):
		return
	if FunMissionManager.objective_index != 2:
		return
	if mounted_player != null and mounted_player.input_locked:
		return
	if can_mount and mounted_player == null:
		mount_player()
	elif mounted_player:
		dismount_player()

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
				anim.play("Gorun")

			if !engine_sfx.playing:
				engine_sfx.play()

			# Pitch mengikuti kecepatan
			engine_sfx.pitch_scale = lerp(
				0.9,
				1.5,
				clamp(abs(speed) / max_speed, 0.0, 1.0)
			)

		else:

			anim.stop()

			if engine_sfx.playing:
				engine_sfx.stop()

	else:

		velocity.x = 0
		velocity.z = 0

		anim.stop()

		if engine_sfx.playing:
			engine_sfx.stop()

	move_and_slide()

# =====================
# MOUNT
# =====================
func _on_body_entered(body):
	if body.is_in_group("player"):
		can_mount = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		can_mount = false

func mount_player():
	var player = get_near_player()
	if player == null:
		return
	
	mounted_player = player
	speed = 0.0

	player.enter_kart()
	player.input_locked = true
	player.velocity = Vector3.ZERO
	player.get_node("CollisionShape3D").disabled = true
	player.vehicle_look_target = look_at_point
	GoKartMissionController.start_mission(self, player)

	# ✅ TAMBAHKAN INI
	FunMissionManager.next_objective()

	# posisi duduk
	player.global_position = seat_point.global_position

	var dir = look_at_point.global_position - seat_point.global_position
	dir.y = 0
	var look_yaw = atan2(dir.x, dir.z)

	player_yaw_offset = look_yaw - global_rotation.y
	player.visual_root.global_rotation.y = look_yaw
	if GoKartMissionController.mission_running:
		return


func dismount_player():
	if mounted_player == null:
		return

	var p = mounted_player

	p.get_node("CollisionShape3D").set_deferred("disabled", false)

	p.velocity = Vector3.ZERO

	# keluar ke samping kart
	var exit_dir = global_transform.basis.x.normalized()
	p.global_position = global_position + exit_dir * 2.0
	p.visual_root.rotation = Vector3.ZERO
	p.input_locked = false
	p.anim_player.speed_scale = 1.0
	p.velocity = Vector3.ZERO
	p.vehicle_look_target = null
	p.exit_kart()
	if engine_sfx.playing:
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

	# SPEED
	if input_forward != 0:
		speed = move_toward(speed, input_forward * max_speed, acceleration * delta)
	else:
		speed = move_toward(speed, 0, brake_force * delta)

	# ROTATION
	if abs(speed) > 0.2:
		rotation.y -= input_turn * turn_speed * delta * sign(speed)

	# MOVE
	var forward = -transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed

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

func _on_mission_finish():
	call_deferred("dismount_player")

func apply_boost():

	max_speed = boost_speed

	print("BOOST MODE")


func reset_speed():

	max_speed = default_speed

	print("NORMAL SPEED")
