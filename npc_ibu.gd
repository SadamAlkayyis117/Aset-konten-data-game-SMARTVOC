extends CharacterBody3D

enum State { WALK, IDLE, REVERSE }
enum Task { NONE, COOK_BREAKFAST, SWEEP, LAUNDRY, DRY_CLOTHES, COOK_LUNCH, IRON, RELAX, COOK_DINNER, WATCH_TV, SLEEP }

@export var kitchen_path:NodePath
@export var sweep_path:NodePath
@export var laundry_path:NodePath
@export var ironing_path:NodePath
@export var sofa_path:NodePath
@export var tv_path:NodePath
@export var bed_path:NodePath
@export var fridge_path: NodePath
@export var serving_spot_path: NodePath
@export var speed:= 5.0
@export var idle_duration:= 1.5
@export var rotation_correction_deg:= 90.0

var pending_task = Task.NONE
var task_started := false
var last_position : Vector3
var current_state=State.WALK
var current_task=Task.NONE
var current_path:Path3D
var follower:PathFollow3D


@onready var teflon = $metarig/Skeleton3D/BoneAttachment3D/Teflon
@onready var remote = $metarig/Skeleton3D/BoneAttachment3D/Remote
@onready var sapu = $metarig/Skeleton3D/BoneAttachment3D/Sapu
@onready var setrika = $metarig/Skeleton3D/BoneAttachment3D/Setrika
@onready var phone = $metarig/Skeleton3D/BoneAttachment3D/"White phone"
@onready var anim= $AnimationPlayer
@onready var fridge: StaticContainer = get_node_or_null(fridge_path)
@onready var serving_spot: FoodServingSpot = get_node_or_null(serving_spot_path)

func _ready():
	hide_all_items()
	last_position = global_position
	await get_tree().process_frame
	if TimeManager:
		TimeManager.game_time_changed.connect(_on_time_changed)
		update_schedule()

func hide_all_items():

	teflon.visible = false
	remote.visible = false
	sapu.visible = false
	setrika.visible = false
	phone.visible = false

func _on_time_changed(h,m):
	update_schedule()

func update_schedule():

	var h = TimeManager.current_hour
	var m = TimeManager.current_minute

	# 22:00 - 04:59 tidur
	if h >= 22 or h < 5:
		set_task(Task.SLEEP)

	# 07:00 - 07:09 masak sarapan
	elif h == 7 and m < 10:
		set_task(Task.COOK_BREAKFAST)

	# 08:00 - 08:59 menyapu
	elif h == 8:
		set_task(Task.SWEEP)

	# 09:00 - 09:09 mencuci
	elif h == 9 and m < 10:
		set_task(Task.LAUNDRY)

	# 12:00 - 12:09 masak siang
	elif h == 12 and m < 10:
		set_task(Task.COOK_LUNCH)

	# 13:00 - 13:09 mengeringkan pakaian
	elif h == 13 and m < 10:
		set_task(Task.DRY_CLOTHES)

	# 16:00 - 17:59 menyetrika
	elif h >= 16 and h < 18:
		set_task(Task.IRON)

	# 19:00 - 19:09 masak malam
	elif h == 19 and m < 10:
		set_task(Task.COOK_DINNER)

	# 20:00 - 21:59 nonton TV
	elif h >= 20 and h < 22:
		set_task(Task.WATCH_TV)

	# selain itu relax
	else:
		set_task(Task.RELAX)

func set_task(task):

	if current_task == task:
		return

	print("")
	print("========== GANTI TASK ==========")
	print("TASK LAMA =", current_task)
	print("TASK BARU =", task)

	if follower and is_instance_valid(follower):
		print("PROGRESS =", follower.progress_ratio)
		print("STATE =", current_state)
	else:
		print("FOLLOWER = NULL")

	if follower \
	and is_instance_valid(follower) \
	and current_task != Task.NONE \
	and current_state == State.IDLE:

		print(">>> MASUK MODE REVERSE <<<")

		pending_task = task

		hide_all_items()

		if anim:
			anim.play("Walk")

		current_state = State.REVERSE

		return

	print(">>> LANGSUNG MULAI TASK BARU <<<")

	current_task = task
	start_task_path(task)

func start_task_path(task):

	current_task = task

	match task:

		Task.COOK_BREAKFAST:
			_go_to_path(kitchen_path)

		Task.SWEEP:
			_go_to_path(sweep_path)

		Task.LAUNDRY:
			_go_to_path(laundry_path)

		Task.DRY_CLOTHES:
			_go_to_path(laundry_path)

		Task.COOK_LUNCH:
			_go_to_path(kitchen_path)

		Task.IRON:
			_go_to_path(ironing_path)

		Task.RELAX:
			_go_to_path(sofa_path)

		Task.COOK_DINNER:
			_go_to_path(kitchen_path)

		Task.WATCH_TV:
			_go_to_path(tv_path)

		Task.SLEEP:
			_go_to_path(bed_path)


func _go_to_path(path_node: NodePath):

	print("GO TO =", path_node)

	task_started = false

	var target_path := get_node_or_null(path_node)

	if target_path == null:
		push_warning("Path tidak ditemukan.")
		return

	current_path = target_path

	print("PATH START =", current_path.curve.get_point_position(0))
	print("PATH END =", current_path.curve.get_point_position(
		current_path.curve.point_count - 1
	))

	if follower and is_instance_valid(follower):
		follower.free()

	follower = PathFollow3D.new()
	follower.loop = false

	current_path.add_child(follower)

	follower.progress_ratio = 0.0

	current_state = State.WALK

func _process(delta):
	state_machine(delta)


func state_machine(delta):

	match current_state:

		State.WALK:

			if anim and anim.current_animation != "Walk":
				anim.play("Walk")

			follow_path_forward(delta)

		State.REVERSE:

			if anim and anim.current_animation != "Walk":
				anim.play("Walk")

			follow_path_reverse(delta)

		State.IDLE:

			velocity = Vector3.ZERO

func follow_path_reverse(delta):

	if follower == null:
		return

	follower.progress -= speed * delta

	var pos = follower.global_position

	var old_pos = global_position

	global_position = pos

	var move_dir = global_position - old_pos

	if move_dir.length() > 0.01:

		var target_angle = atan2(move_dir.x, move_dir.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_angle + deg_to_rad(rotation_correction_deg),
			5.0 * delta
		)

	if follower.progress <= 0.0:

		print("=== REVERSE SELESAI ===")
		print("POSISI NPC =", global_position)

		current_state = State.IDLE

		if pending_task != Task.NONE:

			var next_task = pending_task

			print("TASK BERIKUTNYA =", next_task)

			pending_task = Task.NONE

			start_task_path(next_task)


func follow_path_forward(delta):

	if follower == null:
		return

	follower.progress += speed * delta

	var pos = follower.global_position

	var old_pos = global_position

	global_position = pos

	var move_dir = global_position - old_pos

	if move_dir.length() > 0.01:

		var target_angle = atan2(move_dir.x, move_dir.z)

		rotation.y = lerp_angle(
			rotation.y,
			target_angle + deg_to_rad(rotation_correction_deg),
			5.0 * delta
		)

	if follower.progress_ratio >= 1.0 and not task_started:
		task_started = true
		current_state = State.IDLE
		match current_task:
			Task.COOK_BREAKFAST, Task.COOK_LUNCH, Task.COOK_DINNER:
				start_cooking()
			Task.SWEEP:
				start_sweeping()
			Task.LAUNDRY:
				start_laundry()
			Task.DRY_CLOTHES:
				start_dry_clothes()
			Task.IRON:
				start_ironing()
			Task.RELAX:
				start_relax()
			Task.WATCH_TV:
				start_watch_tv()
			Task.SLEEP:
				start_sleep()

func start_cooking():

	hide_all_items()

	teflon.visible = true

	current_state = State.IDLE

	if anim:
		anim.play("Cooking")

	start_cooking_process()


func start_sweeping():

	hide_all_items()

	sapu.visible = true

	current_state = State.IDLE

	if anim:
		anim.play("Sweep")


func start_laundry():

	hide_all_items()

	current_state = State.IDLE

	if anim:
		anim.play("WashingClothes")


func start_ironing():

	hide_all_items()

	setrika.visible = true

	current_state = State.IDLE

	if anim:
		anim.play("Ironing")


func start_relax():

	hide_all_items()

	phone.visible = true

	current_state = State.IDLE

	if anim:
		anim.play("View")


func start_watch_tv():

	hide_all_items()

	remote.visible = true

	current_state = State.IDLE

	if anim:
		anim.play("WachingTV")


func start_sleep():

	hide_all_items()

	current_state = State.IDLE

	if anim:
		anim.play("Sleep")

func start_dry_clothes():

	hide_all_items()

	current_state = State.IDLE

	if anim:
		anim.play("WashingClothes")


func start_cooking_process():

	if CookingManager.is_cooking():
		return

	if fridge == null:
		return

	if fridge.is_empty_fridge():

		print("KULKAS HABIS TOTAL")

		fridge.generate_starter_stock()

	if serving_spot == null:
		return

	if not serving_spot.is_empty():
		return
	
	print("=== ISI KULKAS ===")
	fridge.print_ingredients()
	var recipe = RecipeManager.get_random_available_recipe(
		fridge.items,
		["plate", "bowl"]
	)

	if recipe.is_empty():

		print("TIDAK ADA RESEP YANG BISA DIMASAK")

		return

	print("MEMASAK :", recipe["name"])
	
	if not fridge.consume_recipe(recipe):
		print("GAGAL KURANGI BAHAN")
		return

	CookingManager.start_cooking(
		self,
		null,
		recipe,
		serving_spot
	)
