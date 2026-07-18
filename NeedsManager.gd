extends Node
class_name NeedsManagers

signal needs_updated

const MAX_VALUE := 100.0
const MIN_VALUE := 0.0

# ==============================
# NEED VALUES
# ==============================
var bladder := 100.0
var mood := 100.0
var hunger := 100.0
var thirsty := 100.0
var social := 100.0
var energy := 100.0
var health := 100.0
var hygiene := 100.0

# ==============================
# BASE DECAY PER SECOND (REAL TIME)
# ==============================
var base_decay_rates := {
	"bladder": 100.0 / (4.0 * 60.0),     # 4 jam
	"mood": 100.0 / (24.0 * 60.0),       # 24 jam
	"hunger": 100.0 / (8.0 * 60.0),      # 8 jam
	"thirsty": 100.0 / (16.0 * 60.0),    # 16 jam total
	"social": 100.0 / (48.0 * 60.0),     # 2 hari
	"energy": 100.0 / (18.0 * 60.0),     # 18 jam
	"hygiene": 100.0 / (24.0 * 60.0)     # 24 jam
}

var overconsume_tracker: Dictionary = {}
# ==============================
# MOOD PENALTY FOR MISSIONS
# ==============================
var mood_penalty_multiplier := 1.0

# ==============================
# TIME-BASED MULTIPLIER
# ==============================
var time_decay_multiplier := 1.0  # akan di-update dari TimeManager

func _ready():
	# Connect ke TimeManager kalau sudah ready
	var time_mgr = get_node_or_null("/root/TimeManager")
	if time_mgr:
		time_mgr.game_time_changed.connect(_on_game_time_changed)

func _process(delta):
	apply_decay(delta)
	apply_cross_effects(delta)
	clamp_all()
	update_mood_penalty()
	emit_signal("needs_updated")

func apply_decay(delta):

	var game_minutes_passed = delta * 0.1333

	mood -= base_decay_rates["mood"] * game_minutes_passed
	hunger -= base_decay_rates["hunger"] * game_minutes_passed
	thirsty -= base_decay_rates["thirsty"] * game_minutes_passed
	social -= base_decay_rates["social"] * game_minutes_passed
	energy -= base_decay_rates["energy"] * game_minutes_passed
	hygiene -= base_decay_rates["hygiene"] * game_minutes_passed

func apply_cross_effects(delta):

	# ======================
	# ENERGY
	# ======================

	if hunger <= 25:
		energy -= 0.10 * delta

	if thirsty <= 30:
		energy -= 0.15 * delta

	# ======================
	# MOOD
	# ======================

	if social <= 0:
		mood -= 0.4 * delta

	if bladder <= 0:
		mood -= 0.5 * delta
		hygiene -= 0.3 * delta
	
	if hygiene <= 0:
		mood -= 0.25 * delta

	# ======================
	# HEALTH PENALTY
	# ======================

	if mood <= 30:
		health -= 0.05 * delta

	if hunger <= 25:
		health -= 0.10 * delta

	if thirsty <= 30:
		health -= 0.10 * delta

	if social <= 0:
		health -= 0.08 * delta

	if bladder <= 0:
		health -= 0.12 * delta
	
	if hygiene <= 0:
		health -= 0.15 * delta

func clamp_all():
	bladder = clamp(bladder, MIN_VALUE, MAX_VALUE)
	mood = clamp(mood, MIN_VALUE, MAX_VALUE)
	hunger = clamp(hunger, MIN_VALUE, MAX_VALUE)
	thirsty = clamp(thirsty, MIN_VALUE, MAX_VALUE)
	social = clamp(social, MIN_VALUE, MAX_VALUE)
	energy = clamp(energy, MIN_VALUE, MAX_VALUE)
	health = clamp(health, MIN_VALUE, MAX_VALUE)
	hygiene = clamp(hygiene, MIN_VALUE, MAX_VALUE)

func update_mood_penalty():
	if mood > 60:
		mood_penalty_multiplier = 1.0
	elif mood > 30:
		mood_penalty_multiplier = 1.3
	elif mood > 15:
		mood_penalty_multiplier = 1.7
	else:
		mood_penalty_multiplier = 2.5

func get_mood_penalty() -> float:
	return mood_penalty_multiplier

# Getter untuk efek lain (sudah ada dari sebelumnya)
func get_writing_progress_penalty() -> float:
	if mood > 60: return 1.0
	if mood > 30: return 1.4
	if mood > 15: return 2.0
	return 3.0

func get_writing_energy_drain() -> float:
	if energy > 50: return 0.5
	if energy > 20: return 1.5
	return 3.0

func get_writing_social_requirement() -> float:
	return social

func get_writing_health_critical() -> bool:
	return health <= 5

# NEW: Dipanggil dari TimeManager setiap jam berubah
func _on_game_time_changed(hour: int, minute: int):
	# Multiplier waktu malam (22:00 - 06:00)
	if hour >= 22 or hour < 6:
		time_decay_multiplier = 1.8   # malam: decay lebih cepat (lelah, lapar naik)
	else:
		time_decay_multiplier = 1.0   # siang: normal
	
	# Opsional: boost tertentu di jam tertentu
	if hour >= 7 and hour <= 9:
		social += 0.1 * 60  # pagi: interaksi sosial lebih mudah (morning mood boost)

func apply_item_effect(item_data: ItemData):
	# Positive effects
	hunger += item_data.hunger_restore
	thirsty += item_data.thirsty_restore
	energy += item_data.energy_restore
	mood += item_data.mood_boost
	health += item_data.health_restore
	bladder += item_data.bladder_restore * item_data.bladder_multiplier  # multiplier untuk over

	# Track overconsumption
	var now = Time.get_unix_time_from_system()
	if not overconsume_tracker.has(item_data.item_id):
		overconsume_tracker[item_data.item_id] = {"count": 0, "last_use": now}
	
	var track = overconsume_tracker[item_data.item_id]
	if now - track.last_use > item_data.overconsume_delay:
		track.count = 1  # reset kalau lama tidak consume
	else:
		track.count += 1
	
	track.last_use = now
	
	# Apply penalty kalau over threshold
	if track.count >= item_data.overconsume_threshold:
		health += item_data.health_penalty
		energy += item_data.energy_crash
		mood += item_data.mood_penalty
		# Bladder sudah dikalikan di atas
		print("DEBUG: OVERCONSUMPTION penalty untuk", item_data.item_name, "count:", track.count)

	clamp_all()
	emit_signal("needs_updated")

func apply_time_skip(hours: float):

	var skipped_minutes = hours * 60.0

	mood -= base_decay_rates["mood"] * skipped_minutes

	hunger -= base_decay_rates["hunger"] * skipped_minutes

	thirsty -= base_decay_rates["thirsty"] * skipped_minutes

	social -= base_decay_rates["social"] * skipped_minutes

	energy -= base_decay_rates["energy"] * skipped_minutes

	hygiene -= base_decay_rates["hygiene"] * skipped_minutes

	clamp_all()

func get_reading_exp_multiplier() -> float:

	# Mood bagus + energy bagus = fokus baca tinggi

	if mood >= 80 and energy >= 80:
		return 1.5

	elif mood >= 60 and energy >= 60:
		return 1.2

	elif mood >= 30 and energy >= 30:
		return 1.0

	elif mood >= 15 and energy >= 15:
		return 0.7

	return 0.5

func get_reading_energy_cost() -> float:

	if energy > 70:
		return 0.4

	elif energy > 30:
		return 0.7

	return 1.2
	
func get_reading_social_boost() -> float:

	# baca novel / buku bisa self-care

	if social < 30:
		return 1.0

	elif social < 60:
		return 0.5

	return 0.2

func apply_swimming_effect(delta):

	# Mood naik pelan
	mood += 1.2 * delta

	# Energy turun pelan
	energy -= 0.8 * delta

	# Sedikit lebih haus
	thirsty -= 0.5 * delta

	# Bersih karena air
	hygiene += 0.3 * delta

	clamp_all()

func apply_sleep(hours: float):

	# decay selama waktu tidur
	apply_time_skip(hours)

	# benefit tidur
	energy += hours * 15
	mood += hours * 5
	health += hours * 2

	# bladder khusus
	bladder -= hours * 8

	clamp_all()

	emit_signal("needs_updated")
