extends CanvasLayer

# ==========================================================
# 📱 SMARTPHONE CORE
# ==========================================================
var calendar_scene = preload("res://Calendar_app.tscn")
var calendar_instance = null
var wallet_scene = preload("res://wallet_app_ui.tscn")
var wallet_instance: Control = null
var weather_scene = preload("res://weather_app.tscn")
var weather_instance = null
var clock_scene = preload("res://clock_app.tscn")
var clock_instance = null
var camera_scene = preload("res://camera_app.tscn")
var camera_instance = null
var gallery_scene = preload("res://gallery_app.tscn")
var gallery_instance = null
var calculator_scene = preload("res://app_calculator.tscn")
var calculator_instance = null
var notes_scene = preload("res://app_notes.tscn")
var notes_instance = null
@onready var label_day = $PhoneBody/TopBar/Label_Day
@onready var label_date = $PhoneBody/TopBar/Label_Date
@onready var label_time = $PhoneBody/TopBar/Label_Time
@onready var app_wallet = $PhoneBody/PageViewport/PageContainer/Page1/AppYoWallet
@onready var app_calendar = $PhoneBody/PageViewport/PageContainer/Page1/AppCalendar
@onready var app_weather = $PhoneBody/PageViewport/PageContainer/Page1/AppWeather
@onready var app_clock = $PhoneBody/PageViewport/PageContainer/Page1/AppClock
@onready var app_camera = $PhoneBody/PageViewport/PageContainer/Page1/AppCamera
@onready var app_gallery = $PhoneBody/PageViewport/PageContainer/Page1/AppGallery
@onready var app_calculator = $PhoneBody/PageViewport/PageContainer/Page1/AppCalculator
@onready var app_notes = $PhoneBody/PageViewport/PageContainer/Page1/AppNotes

var is_open: bool = false
var current_app_open: bool = false

var player_ref: Node = null

# ==========================================================
# READY
# ==========================================================

func _ready():
    visible = false
    
    # connect TimeManager
    if TimeManager:
        TimeManager.game_time_changed.connect(_on_time_changed)
        _update_full_date()
    
    # connect wallet button
    app_wallet.pressed.connect(_on_wallet_pressed)
    app_calendar.pressed.connect(_on_calendar_pressed)
    app_weather.pressed.connect(_on_weather_pressed)
    app_clock.pressed.connect(_on_clock_pressed)
    app_camera.pressed.connect(_on_camera_pressed)
    app_gallery.pressed.connect(_on_gallery_pressed)
    app_calculator.pressed.connect(_on_calculator_pressed)
    app_notes.pressed.connect(_on_notes_pressed)

func setup(player: Node):
    player_ref = player

# ==========================================================
# TOGGLE
# ==========================================================

func toggle_phone():
    if current_app_open:
        return
    
    is_open = !is_open
    visible = is_open
    
    if is_open:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ==========================================================
# TIME UPDATE
# ==========================================================

func _on_time_changed(hour: int, minute: int):
    label_time.text = TimeManager.get_formatted_time()
    _update_full_date()

func _update_full_date():
    label_day.text = TimeManager.WEEKDAY_NAMES[TimeManager.current_day_of_week - 1]
    label_date.text = str(TimeManager.current_date) + "/" + str(TimeManager.current_month) + "/" + str(TimeManager.current_year)

# ==========================================================
# WALLET APP
# ==========================================================

func _on_wallet_pressed():
    if wallet_instance == null:
        wallet_instance = wallet_scene.instantiate()
        add_child(wallet_instance)
    
    wallet_instance.visible = true
    current_app_open = true
    
    # sementara cuma debug tampil saldo
    if PlayerData:
        print("Money:", PlayerData.get_balance())
        print("Savings:", PlayerData.get_savings())

func open_wallet_with_payment(total:int, desc:String="", callback=null):

    if wallet_instance == null:
        wallet_instance = wallet_scene.instantiate()
        add_child(wallet_instance)

    visible = true
    is_open = true
    current_app_open = true

    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

    wallet_instance.visible = true
    wallet_instance.open_wallet_with_payment(
        total,
        desc,
        callback
    )

func close_current_app():
    current_app_open = false

func _on_calendar_pressed():

    if calendar_instance == null:
        calendar_instance = calendar_scene.instantiate()
        add_child(calendar_instance)

    calendar_instance.visible = true
    current_app_open = true

func _on_weather_pressed():

    if weather_instance == null:
        weather_instance = weather_scene.instantiate()
        add_child(weather_instance)

    # tutup app lain
    if wallet_instance:
        wallet_instance.visible = false

    if calendar_instance:
        calendar_instance.visible = false

    weather_instance.visible = true
    weather_instance.refresh_weather()

    current_app_open = true

func _on_clock_pressed():

    if clock_instance == null:
        clock_instance = clock_scene.instantiate()
        add_child(clock_instance)

    clock_instance.visible = true
    current_app_open = true

func _on_camera_pressed():

    if camera_instance == null:
        camera_instance = camera_scene.instantiate()
        add_child(camera_instance)

    camera_instance.open_camera(player_ref)
    current_app_open = true

func _on_gallery_pressed():

    if gallery_instance == null:
        gallery_instance = gallery_scene.instantiate()
        add_child(gallery_instance)

    gallery_instance.open_gallery()

    current_app_open = true

func _on_calculator_pressed():

    if calculator_instance == null:
        calculator_instance = calculator_scene.instantiate()
        add_child(calculator_instance)

    calculator_instance.open_app()

    current_app_open = true

# ==========================================================
# NOTES APP OPEN
# ==========================================================

func _on_notes_pressed():

    if notes_instance == null:
        notes_instance = notes_scene.instantiate()
        add_child(notes_instance)

    notes_instance.open_app()

    current_app_open = true

    # 🔥 LOCK PLAYER
    if player_ref:
        player_ref.set_input_locked(true, true)
