extends Area3D

@export var sit_duration: float = 15.0  # durasi duduk saat NPC masuk kursi
@export var rotation_offset_deg: float = 180.0  # koreksi rotasi agar menghadap depan kursi

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body is CharacterBody3D:
		# pastikan NPC siswa dan belum duduk
		if "NPC" in body.name and not body.is_sitting:
			# set posisi & rotasi sesuai marker
			var marker = get_parent().get_node_or_null("Marker3D")
			if marker != null:
				body.global_position = marker.global_position
				# koreksi rotasi Y agar NPC menghadap depan kursi
				var corrected_rot = marker.global_rotation
				corrected_rot.y += deg_to_rad(rotation_offset_deg)
				body.rotation = corrected_rot
			# panggil fungsi duduk di NPC
			body.start_sitting(sit_duration)
