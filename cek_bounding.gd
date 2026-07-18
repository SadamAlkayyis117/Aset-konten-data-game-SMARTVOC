extends Node3D

# AABB scanner + debug yang robust untuk berbagai struktur hasil import Blender/GLTF

func _ready():
	print("\n\n==================== AABB DEBUG START ====================")
	print("Node path:", get_path())
	
	var aabb = _scan_for_aabb(self)

	if aabb == null:
		print("[AABB DEBUG] Tidak ditemukan mesh / collider apapun di subtree.")
		print("===================== AABB DEBUG END =====================\n\n")
		return

	var minp = aabb.position
	var maxp = aabb.position + aabb.size
	print("AABB Min (X, Y, Z):", minp)
	print("AABB Max (X, Y, Z):", maxp)
	print("AABB Size (X, Y, Z):", aabb.size)
	print("Center (X, Y, Z):", minp + aabb.size * 0.5)
	
	print("\n[MAP BOUNDS XZ]")
	print("Min X:", minp.x)
	print("Max X:", maxp.x)
	print("Min Z:", minp.z)
	print("Max Z:", maxp.z)
	
	print("===================== AABB DEBUG END =====================\n\n")


# Hapus type hint AABB agar mengizinkan pengembalian null
func _scan_for_aabb(root: Node): 
	
	var INF = 1e20
	var min_v = Vector3(INF, INF, INF)
	var max_v = Vector3(-INF, -INF, -INF)
	var found := false

	var stack: Array = [root]

	while stack.size() > 0:
		var node = stack.pop_back()
		if not (node is Node):
			continue

		var mesh_aabb: AABB
		var node_transform: Transform3D = node.global_transform
		
		# 1) MeshInstance3D
		if node is MeshInstance3D:
			var mesh = (node as MeshInstance3D).mesh
			if mesh:
				mesh_aabb = mesh.get_aabb()
				_update_min_max(node_transform, mesh_aabb, min_v, max_v)
				found = true

		# 2) CollisionShape3D (menggunakan debug mesh jika ada)
		elif node is CollisionShape3D:
			var shape = (node as CollisionShape3D).shape
			if shape and shape.has_method("get_debug_mesh"):
				var dbg = shape.get_debug_mesh()
				if dbg:
					mesh_aabb = dbg.get_aabb()
					_update_min_max(node_transform, mesh_aabb, min_v, max_v)
					found = true
					
		# 3) CSGShape3D (menggunakan mesh internal)
		elif node is CSGShape3D:
			if node.has_method("get_meshes"):
				var csg_meshes: Array = node.get_meshes()
				for cm in csg_meshes:
					if cm is Mesh:
						mesh_aabb = cm.get_aabb()
						_update_min_max(node_transform, mesh_aabb, min_v, max_v)
						found = true

		# Tambahkan anak-anak node ke stack
		for c in node.get_children():
			if c is Node:
				stack.append(c)

	if not found:
		return null # Baris 87: Sekarang tidak error karena type hint dihapus

	# hasilkan AABB global
	var size = max_v - min_v
	return AABB(min_v, size)


# Utilitas untuk menggabungkan sudut AABB yang ditransformasi ke min/max global.
func _update_min_max(xf: Transform3D, aabb: AABB, min_v: Vector3, max_v: Vector3) -> void:
	var minp = aabb.position
	var maxp = aabb.position + aabb.size

	# Sudut-sudut AABB lokal
	var corners = [
		Vector3(minp.x, minp.y, minp.z),
		Vector3(minp.x, minp.y, maxp.z),
		Vector3(minp.x, maxp.y, minp.z),
		Vector3(minp.x, maxp.y, maxp.z),
		Vector3(maxp.x, minp.y, minp.z),
		Vector3(maxp.x, minp.y, maxp.z),
		Vector3(maxp.x, maxp.y, minp.z),
		Vector3(maxp.x, maxp.y, maxp.z),
	]

	for c in corners:
		# 🟢 [PERBAIKAN KRUSIAL LINE 113]: Mengganti method xform() dengan operator perkalian (*)
		var wp = xf * c 
		
		# Perbarui min_v dan max_v secara in-place
		min_v.x = min(min_v.x, wp.x)
		min_v.y = min(min_v.y, wp.y)
		min_v.z = min(min_v.z, wp.z)
		max_v.x = max(max_v.x, wp.x)
		max_v.y = max(max_v.y, wp.y)
		max_v.z = max(max_v.z, wp.z)
