extends StaticBody3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var col: CollisionShape3D = $CollisionShape3D

var is_closed := false

func _ready():
	add_to_group("archery_gate")
	# 🔥 Default: TERBUKA
	anim.play("Terbuka")
	col.disabled = true

	# 🔥 penting: listen anim selesai
	anim.animation_finished.connect(_on_animation_finished)

# =========================
# 🔒 TUTUP GATE
# =========================
func close_gate():

	if is_closed:
		return

	is_closed = true

	print("GATE: CLOSING")

	col.disabled = false   # 🔥 aktifkan collision saat mulai nutup
	anim.play("Tutup")

# =========================
# 🔓 BUKA GATE
# =========================
func open_gate():

	if not is_closed:
		return

	is_closed = false

	print("GATE: OPENING")

	anim.play("Buka")

# =========================
# 🎬 HANDLE TRANSISI ANIMASI
# =========================
func _on_animation_finished(anim_name: String):

	match anim_name:

		"Tutup":
			# setelah nutup → stay tertutup
			anim.play("Tertutup")

		"Buka":
			# setelah buka → balik ke default
			anim.play("Terbuka")
			col.disabled = true   # 🔥 collision mati lagi
