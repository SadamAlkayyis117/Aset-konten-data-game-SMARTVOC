extends CanvasLayer

# =========================
# NODE REFERENCES
# =========================
@onready var bg            : TextureRect      = $Background/TextureRect_BG
@onready var hint_label    : RichTextLabel    = $Hint/RichTextLabelHint
@onready var spinner_anim  : AnimationPlayer  = $LoadingCircle/Spinner
@onready var fade_anim     : AnimationPlayer  = $UI_Anim
@onready var timer         : Timer            = $TimerLoading
@onready var bg_timer      : Timer            = $TimerBG

@onready var btn_next      : Button           = $Hint/BtnNext
@onready var btn_prev      : Button           = $Hint/BtnPrev

# =========================
# DATA
# =========================
@export var backgrounds : Array[Texture2D]
@export var hints       : Array[String]

@export var min_load_time := 10.0
@export var max_load_time := 15.0

const HINT_COUNT := 6

var active_hints : Array[String] = []
var current_hint := 0
var loading_done := false

# =========================
# READY
# =========================
func _ready():
	# 1. BLOKIR SISTEM GLOBAL
	GM.is_opening = true   # Pakai is_opening agar Pause Menu otomatis terblokir
	GM.is_loading = true   # Untuk flag internal loading jika perlu
	
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	_pick_random_background()
	_pick_random_hints()

	spinner_anim.play("Spinner")

	_start_loading_timer()
	_start_background_cycle()

	btn_next.pressed.connect(_next_hint)
	btn_prev.pressed.connect(_prev_hint)
	fade_anim.animation_finished.connect(_on_fade_anim_finished)

# =========================
# LOADING TIMER
# =========================
func _start_loading_timer():
	timer.wait_time = randf_range(min_load_time, max_load_time)
	timer.one_shot = true
	timer.timeout.connect(_on_loading_finished)
	timer.start()

func _on_loading_finished():
	if loading_done:
		return

	loading_done = true
	timer.stop()        # <--- Tambahkan ini untuk jaga-jaga
	bg_timer.stop()
	spinner_anim.stop()
	
	fade_anim.play("fade_out")

# =========================
# BACKGROUND CYCLE
# =========================
func _start_background_cycle():
	if backgrounds.size() <= 1:
		return

	bg_timer.wait_time = 3.0
	bg_timer.one_shot = false
	bg_timer.timeout.connect(_on_bg_timer_timeout)
	bg_timer.start()

func _on_bg_timer_timeout():
	_pick_random_background()

func _pick_random_background():
	if backgrounds.is_empty():
		return
	bg.texture = backgrounds.pick_random()

# =========================
# HINT SYSTEM (6 RANDOM)
# =========================
func _pick_random_hints():
	if hints.is_empty():
		return

	active_hints.clear()

	var pool := hints.duplicate()
	pool.shuffle()

	for i in min(HINT_COUNT, pool.size()):
		active_hints.append(pool[i])

	current_hint = 0
	_update_hint()

func _update_hint():
	hint_label.text = "%s" % active_hints[current_hint]

func _next_hint():
	current_hint = (current_hint + 1) % active_hints.size()
	_update_hint()

func _prev_hint():
	current_hint -= 1
	if current_hint < 0:
		current_hint = active_hints.size() - 1
	_update_hint()

func _on_fade_anim_finished(anim_name: String):
	if anim_name != "fade_out":
		return

	GM.is_opening = false
	GM.is_loading = false

	MusicManager.start_gameplay_music()

	get_tree().change_scene_to_file("res://rumah_mc.tscn")
