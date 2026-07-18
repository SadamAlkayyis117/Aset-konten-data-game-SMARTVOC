extends Node3D

var npc = preload("res://npc_kota_1.tscn")
@onready var navigation_region: NavigationRegion3D = $"../NavigationRegion3D"
@export var amount := 5

func _ready():
    for x in amount:
        var current_npc = npc.instantiate()
        get_parent().add_child.call_deferred(current_npc)
        current_npc.navigation_region = navigation_region
        var verts = navigation_region.navigation_mesh.get_vertices()
        if verts.size() > 0:
            var idx = randi_range(0, verts.size() - 1)
            # Jika navigation_region di-scale, butuh to_global atau dikali scale (pastikan transform benar)
            var spawn_pos = navigation_region.to_global(verts[idx])
            current_npc.position = spawn_pos
