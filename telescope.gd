extends Node3D

@export var telescope_camera: Camera3D
@export var look_speed := 0.002
@export var zoom_speed := 8.0

var player_inside := false
var target_fov := 75.0
var min_fov := 5.0
var max_fov := 75.0
var pitch := 0.0
var yaw := 0.0
var using_telescope := false

func _ready():
	$Area3D.body_entered.connect(_on_body_entered)
	$Area3D.body_exited.connect(_on_body_exited)

func _process(delta):

	if !using_telescope:
		return

	telescope_camera.fov = lerp(
		telescope_camera.fov,
		target_fov,
		delta * zoom_speed
	)

func enter_telescope():
	print("ENTER CALLED")
	using_telescope = true

	if is_instance_valid(telescope_camera):
		telescope_camera.current = true

	target_fov = telescope_camera.fov

	var player = get_tree().get_first_node_in_group("player")

	if player:
		player.set_input_locked(true)
		player.is_using_telescope = true
		# Block only interaction so player won't re-trigger enter
		if "input_context" in player:
			player.input_context["interaction"] = true

	# capture mouse for telescope control
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func exit_telescope():
	print("EXIT CALLED")
	using_telescope = false

	if is_instance_valid(telescope_camera):
		telescope_camera.current = false
		print("Telescope camera current set to false")

	var player = get_tree().get_first_node_in_group("player")

	if player:
		print("UNLOCK PLAYER")
		player.set_input_locked(false)
		player.is_using_telescope = false
		# unblock interaction
		if "input_context" in player:
			player.input_context["interaction"] = false
		# let the player restore its camera(s) properly
		if player.has_method("_apply_camera_mode"):
			player._apply_camera_mode()
			print("Called player._apply_camera_mode() to restore player camera")
		else:
			print("WARNING: player._apply_camera_mode() not found")

	# fallback: try to set any node in group main_camera (if you still use that)
	var main_cam = get_tree().get_first_node_in_group("main_camera")
	if main_cam and main_cam is Camera3D:
		main_cam.current = true
		print("MAIN CAMERA SET (group fallback)")

	# make sure mouse mode matches player unlocked state
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false

		if using_telescope:
			exit_telescope()
		
func _input(event):

	if event.is_action_pressed("Interaksi"):

		if player_inside:

			if using_telescope:
				exit_telescope()
			else:
				enter_telescope()

			return

	if !using_telescope:
		return

	if event is InputEventMouseMotion:

		yaw -= event.relative.x * look_speed
		pitch -= event.relative.y * look_speed

		pitch = clamp(
			pitch,
			deg_to_rad(-40),
			deg_to_rad(40)
		)

		telescope_camera.rotation.y = yaw
		telescope_camera.rotation.x = pitch

	elif event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_fov -= 5.0

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_fov += 5.0

		target_fov = clamp(
			target_fov,
			min_fov,
			max_fov
		)
