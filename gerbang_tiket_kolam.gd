extends StaticBody3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var area: Area3D = $Area3D

@onready var collision_node: CollisionShape3D = $CollisionShape3D

var player_can_interact := false
var is_open := false
var is_animating := false


func _ready():

	add_to_group("pool_gate")

	# =========================
	# DEFAULT = TERTUTUP
	# =========================
	anim.play("Tertutup")
	anim.seek(anim.current_animation_length, true)
	anim.stop()

	is_open = false

	collision_node.disabled = false


	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

	anim.animation_finished.connect(_on_animation_finished)


func _input(event):

	if event.is_action_pressed("Interaksi") and player_can_interact:
		interact()


func _on_body_entered(body):

	if body.is_in_group("player"):
		player_can_interact = true


func _on_body_exited(body):

	if body.is_in_group("player"):
		player_can_interact = false


func interact():

	if is_animating:
		return

	# wajib punya tiket
	if not PlayerData.has_pool_ticket:
		print("Harus beli tiket dulu.")
		return

	# flow:
	# tertutup -> pencet E -> terbuka
	# terbuka -> pencet E -> menutup
	if is_open:
		close_gate()
	else:
		open_gate()


# =========================
# BUKA GERBANG
# =========================
func open_gate():

	if is_open:
		return

	is_animating = true
	is_open = true

	# collision mati supaya bisa lewat
	collision_node.disabled = true

	anim.play("Terbuka")


# =========================
# TUTUP GERBANG
# =========================
func close_gate():

	if not is_open:
		return

	is_animating = true
	is_open = false

	anim.play("Menutup")


# =========================
# SELESAI ANIMASI
# =========================
func _on_animation_finished(anim_name: String):

	is_animating = false

	match anim_name:

		"Terbuka":
			# stay terbuka
			anim.stop()

		"Menutup":
			# stay tertutup
			collision_node.disabled = false
			anim.stop()
