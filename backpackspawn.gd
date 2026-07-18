extends Marker3D

@export var backpack_scene_path := "res://tas_sekolah.tscn"

func _ready():
	await get_tree().process_frame

	# Tas sedang dipakai player
	if GM.has_backpack:
		return

	# Belum pernah diambil
	if !GM.backpack_taken:
		_spawn_backpack(global_position, global_rotation)
		return

	# Pernah diambil tetapi sedang berada di scene ini
	if GM.backpack_world_scene == get_tree().current_scene.scene_file_path:
		_spawn_backpack(
			GM.backpack_world_position,
			GM.backpack_world_rotation
		)


func _spawn_backpack(pos:Vector3, rot:Vector3):

	var scene = load(backpack_scene_path)

	if scene == null:
		push_error("TasPlayerSpawn: gagal load backpack.")
		return

	var backpack = scene.instantiate()
	GM.backpack_scene_path = backpack_scene_path
	get_tree().current_scene.add_child(backpack)

	backpack.global_position = pos
	backpack.global_rotation = rot

	print("Spawn Backpack:", backpack.global_position)
