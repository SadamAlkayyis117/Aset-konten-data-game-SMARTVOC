extends Area3D

enum Behavior {
	COOK,
	SWEEP,
	LAUNDRY,
	IRON,
	RELAX,
	TV,
	SLEEP
}

@export var behavior : Behavior
@export var marker_path : NodePath
@export var rotation_offset_deg := 180.0

func _ready():

	monitoring = true
	monitorable = true

	body_entered.connect(_on_body_entered)

func _on_body_entered(body):

	if not (body is CharacterBody3D):
		return

	if body.name != "NPC Ibu":
		return

	var marker = get_node_or_null(marker_path)

	if marker:

		body.global_position = marker.global_position

		var rot = marker.global_rotation
		rot.y += deg_to_rad(rotation_offset_deg)
		body.rotation = rot

	match behavior:

		Behavior.COOK:

			if body.current_task in [
				body.Task.COOK_BREAKFAST,
				body.Task.COOK_LUNCH,
				body.Task.COOK_DINNER
			]:
				body.start_cooking()

		Behavior.SWEEP:

			if body.current_task == body.Task.SWEEP:
				body.start_sweeping()

		Behavior.LAUNDRY:

			if body.current_task == body.Task.LAUNDRY:
				body.start_laundry()

			elif body.current_task == body.Task.DRY_CLOTHES:
				body.start_dry_clothes()

		Behavior.IRON:

			if body.current_task == body.Task.IRON:
				body.start_ironing()

		Behavior.RELAX:

			if body.current_task == body.Task.RELAX:
				body.start_relax()

		Behavior.TV:

			if body.current_task == body.Task.WATCH_TV:
				body.start_watch_tv()

		Behavior.SLEEP:

			if body.current_task == body.Task.SLEEP:
				body.start_sleep()
