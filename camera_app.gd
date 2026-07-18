extends Control

@onready var preview_texture = $Kerangka
@onready var mode_label = $Topbar/LabelMode
@onready var watermark = $WaterMark
@onready var Crosshair = $Crosshair

var player = null
var cam : Camera3D = null

var is_open := false
var is_video_mode := false
var is_recording := false
var record_frames = []
var record_timer = 0.0
var record_interval = 0.15
var current_video_name = ""
var yaw := 0.0
var pitch := 0.0
var sens := 0.003
var zoom_speed := 0.15

# =====================================================
# READY
# =====================================================

func _ready():
	visible = false
	watermark.text = "SMARTVOC CAM | " + Time.get_datetime_string_from_system()

# =====================================================
# OPEN CAMERA
# =====================================================

func open_camera(p):

	player = p
	cam = player.phone_cam

	if cam == null:
		push_error("PhoneCamera belum ada di Player")
		return

	visible = true
	is_open = true
	is_video_mode = false
	is_recording = false

	get_parent().get_node("PhoneBody").visible = false

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	cam.current = true
	mode_label.text = "PHOTO"
	player.set_input_locked(true)
	player.is_using_phone_camera = true

	watermark.visible = true

	_activate_back_camera()

func _process(delta):

	if not is_open or not player:
		return

	# ikut posisi holder HP
	cam.global_position = player.phone_cam_back.global_position

	# ikut arah dasar holder
	cam.global_rotation = player.phone_cam_back.global_rotation

	# tambah rotasi user
	cam.rotate_y(yaw)
	cam.rotate_object_local(Vector3.RIGHT, pitch)
	
	if is_recording:
		record_timer += delta
		if record_timer >= record_interval:
			record_timer = 0.0
			_capture_video_frame()
			

func close_camera():

	visible = false
	is_open = false
	is_recording = false

	get_parent().get_node("PhoneBody").visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if player:
		player._apply_camera_mode()
		player.set_input_locked(false)
		player.is_using_phone_camera = false

	get_parent().current_app_open = false

# =====================================================
# INPUT
# =====================================================

func _input(event):

	if not is_open:
		return
	
	get_viewport().set_input_as_handled()

	# Mouse geser = gerak kamera
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * sens
		pitch -= event.relative.y * sens
		pitch = clamp(pitch, deg_to_rad(-80), deg_to_rad(80))

		cam.rotation.y = yaw
		cam.rotation.x = pitch

	# Fire
	if event.is_action_pressed("Fire"):

		if is_video_mode:
			_toggle_record()
		else:
			_take_photo()

	# E = mode photo/video
	if event.is_action_pressed("Interaksi"):
		_toggle_mode()

	# Zoom in
	if event.is_action_pressed("Lompat"):
		cam.fov -= 4
		cam.fov = clamp(cam.fov, 20, 75)

	# Zoom out
	if event.is_action_pressed("Crouch"):
		cam.fov += 4
		cam.fov = clamp(cam.fov, 20, 75)

	# ESC
	if event.is_action_pressed("ui_cancel"):
		close_camera()

# =====================================================
# PHOTO
# =====================================================

func _take_photo():

	var old_crosshair = player.crosshair_ui.visible

	preview_texture.visible = false
	$Topbar.visible = false
	Crosshair.visible = false

	if player.crosshair_ui:
		player.crosshair_ui.visible = false

	watermark.visible = true

	await RenderingServer.frame_post_draw

	var img = get_viewport().get_texture().get_image()
	img.flip_y()
	img.flip_x()

	# nama file jangan pakai float
	var file_name = "IMG_" + str(Time.get_unix_time_from_system()).replace(".", "_") + ".png"

	var full_path = GalleryManager.photo_path + file_name
	img.save_png(full_path)

	# =====================
	# BUAT THUMBNAIL
	# =====================
	var thumb = img.duplicate()
	thumb.resize(223.53,125.74, Image.INTERPOLATE_LANCZOS)

	var thumb_path = GalleryManager.photo_path + "thumb_" + file_name
	thumb.save_png(thumb_path)

	# restore ui
	preview_texture.visible = true
	$Topbar.visible = true
	Crosshair.visible = true

	if player.crosshair_ui:
		player.crosshair_ui.visible = old_crosshair

	print("📷 FOTO DISIMPAN:", full_path)

	var g = get_parent().get_node_or_null("Gallery_app")
	if g:
		g.load_gallery()

	_flash_effect()

func _capture_video_frame():

	var old_crosshair = player.crosshair_ui.visible

	preview_texture.visible = false
	$Topbar.visible = false
	Crosshair.visible = false

	if player.crosshair_ui:
		player.crosshair_ui.visible = false

	watermark.visible = true

	await RenderingServer.frame_post_draw

	var img = get_viewport().get_texture().get_image()

	img.flip_y()
	img.flip_x()

	record_frames.append(img)

	# restore UI
	preview_texture.visible = true
	$Topbar.visible = true
	Crosshair.visible = true

	if player.crosshair_ui:
		player.crosshair_ui.visible = old_crosshair

# =====================================================
# VIDEO
# =====================================================

func _toggle_record():

	is_recording = !is_recording

	if is_recording:

		record_frames.clear()
		record_timer = 0.0
		current_video_name = "VID_" + str(Time.get_unix_time_from_system())

		mode_label.text = "REC ●"

	else:

		mode_label.text = "VIDEO"

		_save_fake_video()

func _save_fake_video():

	if record_frames.size() == 0:
		return

	var folder = GalleryManager.video_path + current_video_name + "/"
	DirAccess.make_dir_recursive_absolute(folder)

	for i in range(record_frames.size()):
		var path = folder + str(i).pad_zeros(4) + ".png"
		record_frames[i].save_png(path)

	# thumbnail = frame pertama
	var thumb = record_frames[0].duplicate()
	thumb.resize(223.53,125.74, Image.INTERPOLATE_LANCZOS)
	thumb.save_png(folder + "thumb.png")
	
	var g = get_parent().get_node_or_null("Gallery_app")
	if g:
		g.load_gallery()

	print("VIDEO SAVED:", folder)

# =====================================================
# MODE
# =====================================================

func _toggle_mode():

	if is_recording:
		return

	is_video_mode = !is_video_mode

	if is_video_mode:
		mode_label.text = "VIDEO"
	else:
		mode_label.text = "PHOTO"

# =====================================================
# BACK CAMERA
# =====================================================

func _activate_back_camera():

	if not player:
		return

	yaw = 0
	pitch = 0

	cam.global_transform = player.phone_cam_back.global_transform

	player.anim_player.play("Picture")

# =====================================================
# FX
# =====================================================

func _flash_effect():

	modulate = Color(2,2,2,1)
	await get_tree().create_timer(0.08).timeout
	modulate = Color.WHITE
