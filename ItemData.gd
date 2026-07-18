extends Resource
class_name ItemData

# ==============================
# BASIC INFO
# ==============================
@export var world_scene_path: String
@export var equip_scene_path: String
@export var item_id: String
@export var item_name: String
@export var description: String
@export var icon: Texture2D
@export var equip_scale: Vector3 = Vector3.ONE
@export var world_scale: Vector3 = Vector3.ONE
@export var price: int = 0

# ==============================
# TYPE SYSTEM
# ==============================
enum ItemType {
	GENERIC,
	CONSUMABLE,
	INGREDIENT,
	EQUIPMENT,
	WEAPON,
	QUEST
}

# ==============================
# CONSUMABLE SYSTEM
# ==============================
@export var overconsume_threshold: int = 5  # jumlah use berturut-turut sebelum penalty
@export var health_penalty: float = 0.0      # negatif value, misal -5.0 per over
@export var energy_crash: float = 0.0        # misal -15 setelah lonjakan
@export var mood_penalty: float = 0.0
@export var bladder_multiplier: float = 1.0  # multiplier ke bladder increase (misal 2.0 = naik 2x cepat)
@export var overconsume_delay: float = 300.0 # detik, reset counter kalau tidak consume dalam waktu ini
@export var energy_restore: float = 0.0
@export var mood_boost: float = 0.0
@export var health_restore: float = 0.0
@export var bladder_restore: float = 0.0  
@export var max_durability: int = 1
@export var hunger_restore: float = 0.0
@export var thirsty_restore: float = 0.0
@export var item_type: ItemData.ItemType = ItemData.ItemType.GENERIC

# ==============================
# COOKING SYSTEM
# ==============================

@export var ingredient_id : String = ""

@export var ingredient_tags : Array[String] = []

@export var ingredient_quality : int = 1

# ==============================
# BEHAVIOR FLAGS
# ==============================
@export var is_usable: bool = false
@export var is_equippable: bool = false
@export var is_giveable: bool = false
@export var is_droppable: bool = true
@export var is_storable: bool = true
@export var enable_aim: bool = false

# ==============================
# SECONDARY ACTION (RIGHT CLICK)
# ==============================

@export var enable_alt_fire: bool = false

@export_enum("Aim", "Throw", "Block")
var alt_fire_type: String = "Aim"

@export var alt_fire_anim: String = ""        # anim saat ditekan
@export var alt_fire_release_anim: String = "" # anim saat dilepas
# ==============================
# PROJECTILE SYSTEM 🔥
# ==============================

@export var is_projectile_weapon: bool = false

@export var projectile_scene: String = ""   # peluru / panah
@export var ammo_item_id: String = ""       # pakai ammo apa
@export var ammo_per_shot: int = 1

@export_enum("OnRelease", "OnHoldLoop", "OnTap")
var fire_spawn_timing: String = "OnTap"

# ==============================
# ITEM ANIMATION SYNC 🔥
# ==============================

@export var use_item_animation: bool = false
@export var item_anim_player_path: NodePath

@export var fire_item_animations: Array[String] = []
@export var fire_item_release_anim: String = ""

@export var alt_item_anim: String = ""
@export var alt_item_release_anim: String = ""

# ==============================
# QUICK USE GRID SIZE
# ==============================
@export_range(1, 6)
var quick_use_size: int = 1

# ==============================
# STACKING SYSTEM
# ==============================
@export var is_stackable: bool = false
@export var max_stack: int = 1

@export var enable_fire: bool = false                      # Apakah item ini support Fire?
@export_enum("Tap", "Hold") var fire_type: String = "Tap"  # Tap = klik pendek, Hold = tahan
@export var fire_animations: Array[String] = []            # Untuk tap: ["Swing1", "Swing2", "Swing3"]
														   # Untuk hold: ["Holdfire", "Shoot"] (pressed → loop → released)
@export var fire_release_anim: String = ""                 # Untuk hold: animasi saat lepas (misal "Holdfire")
@export var auto_idle_anim: String = ""                    # Nama animasi idle khusus (misal "IdleWeapon")

func is_ingredient() -> bool:
	return item_type == ItemType.INGREDIENT
