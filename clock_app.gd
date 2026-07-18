extends Control

# ==========================================================
# PAGE
# ==========================================================
@onready var page_clock = $Panel_background/ContentArea/PageClock
@onready var page_alarm = $Panel_background/ContentArea/PageAlarm
@onready var page_stopwatch = $Panel_background/ContentArea/PageStopwatch
@onready var page_timer = $Panel_background/ContentArea/PageTimer

# ==========================================================
# NAV BUTTON
# ==========================================================
@onready var btn_clock = $Panel_background/ButtonNav/ButtonClock
@onready var btn_alarm = $Panel_background/ButtonNav/ButtonAlarm
@onready var btn_stopwatch = $Panel_background/ButtonNav/ButtonStopwatch
@onready var btn_timer = $Panel_background/ButtonNav/ButtonTimer
@onready var btn_close = $Panel_background/Button_Close

# ==========================================================
# CLOCK PAGE
# ==========================================================
@onready var hand_hour = $Panel_background/ContentArea/PageClock/HandHour
@onready var hand_minute = $Panel_background/ContentArea/PageClock/HandMinute
@onready var hand_second = $Panel_background/ContentArea/PageClock/HandSecond
@onready var label_day = $Panel_background/ContentArea/PageClock/Label_Day
@onready var label_date = $Panel_background/ContentArea/PageClock/Label_Date

# ==========================================================
# ALARM PAGE
# ==========================================================
@onready var spin_hour = $Panel_background/ContentArea/PageAlarm/SpinHour
@onready var spin_minute = $Panel_background/ContentArea/PageAlarm/SpinMinute
@onready var btn_set_alarm = $Panel_background/ContentArea/PageAlarm/ButtonSetAlarm
@onready var label_alarm_info = $Panel_background/ContentArea/PageAlarm/LabelAlarmInfo

# ==========================================================
# STOPWATCH PAGE
# ==========================================================
@onready var label_stopwatch = $Panel_background/ContentArea/PageStopwatch/LabelStopwatch
@onready var btn_sw_left = $Panel_background/ContentArea/PageStopwatch/ButtonLeft
@onready var btn_sw_play = $Panel_background/ContentArea/PageStopwatch/ButtonPlayPause
@onready var btn_sw_right = $Panel_background/ContentArea/PageStopwatch/ButtonRight

# ==========================================================
# TIMER PAGE
# ==========================================================
@onready var spin_th = $Panel_background/ContentArea/PageTimer/SpinTimerHour
@onready var spin_tm = $Panel_background/ContentArea/PageTimer/SpinTimerMinute
@onready var spin_ts = $Panel_background/ContentArea/PageTimer/SpinTimerSecond
@onready var label_timer = $Panel_background/ContentArea/PageTimer/LabelTimer
@onready var btn_timer_start = $Panel_background/ContentArea/PageTimer/ButtonStart
@onready var btn_timer_reset = $Panel_background/ContentArea/PageTimer/ButtonReset


# ==========================================================
# DATA
# ==========================================================
var stopwatch_running := false
var stopwatch_time := 0.0

var timer_running := false
var timer_time := 0.0

# ======================
# ALARM DATA (BARU)
# ======================
var alarm_enabled := false
var alarm_hour := 0
var alarm_minute := 0
var alarm_triggered_today := false


# ==========================================================
# READY
# ==========================================================
func _ready():

    btn_clock.pressed.connect(open_clock)
    btn_alarm.pressed.connect(open_alarm)
    btn_stopwatch.pressed.connect(open_stopwatch)
    btn_timer.pressed.connect(open_timer)
    btn_close.pressed.connect(close_app)

    btn_set_alarm.pressed.connect(save_alarm)

    btn_sw_left.pressed.connect(stopwatch_left)
    btn_sw_play.pressed.connect(stopwatch_play_pause)

    btn_timer_start.pressed.connect(timer_start_pause)
    btn_timer_reset.pressed.connect(timer_reset)

    spin_hour.max_value = 23
    spin_minute.max_value = 59

    spin_th.max_value = 99
    spin_tm.max_value = 59
    spin_ts.max_value = 59

    open_clock()



# ==========================================================
# PROCESS
# ==========================================================
func _process(delta):

    update_clock_page()
    update_alarm_check()
    update_stopwatch(delta)
    update_timer(delta)

    # reset alarm trigger tiap jam 00:00
    if TimeManager.current_hour == 0 and TimeManager.current_minute == 0:
        alarm_triggered_today = false


# ==========================================================
# PAGE SWITCH
# ==========================================================
func hide_sub_pages():

    # clock jangan dihide di sini
    page_alarm.visible = false
    page_stopwatch.visible = false
    page_timer.visible = false


func open_clock():

    # clock utama
    page_clock.visible = true

    # lainnya mati
    page_alarm.visible = false
    page_stopwatch.visible = false
    page_timer.visible = false


func open_alarm():

    hide_sub_pages()

    page_clock.visible = false
    page_alarm.visible = true


func open_stopwatch():

    hide_sub_pages()

    page_clock.visible = false
    page_stopwatch.visible = true


func open_timer():

    hide_sub_pages()

    page_clock.visible = false
    page_timer.visible = true


# ==========================================================
# CLOCK
# ==========================================================
func update_clock_page():

    var h = TimeManager.current_hour
    var m = TimeManager.current_minute

    # ambil detik dari pecahan menit
    var total_seconds = int(TimeManager.current_time_minutes * 60.0)
    var s = total_seconds % 60

    # ======================
    # MENIT
    # ======================
    hand_minute.rotation_degrees = m * 6.0 + (s / 60.0) * 6.0

    # ======================
    # JAM
    # ======================
    hand_hour.rotation_degrees = (h % 12) * 30.0 + (m / 60.0) * 30.0

    # ======================
    # DETIK
    # ======================
    if hand_second:
        hand_second.rotation_degrees = s * 6.0

    # ======================
    # LABEL
    # ======================
    label_day.text = TimeManager.WEEKDAY_NAMES[
        TimeManager.current_day_of_week - 1
    ]

    label_date.text = str(TimeManager.current_date) + "/" + \
        str(TimeManager.current_month) + "/" + \
        str(TimeManager.current_year)

# ==========================================================
# ALARM
# ==========================================================
func save_alarm():

    alarm_hour = int(spin_hour.value)
    alarm_minute = int(spin_minute.value)
    alarm_enabled = true
    alarm_triggered_today = false

    label_alarm_info.text = "Alarm: " + \
        str(alarm_hour).pad_zeros(2) + ":" + \
        str(alarm_minute).pad_zeros(2)


func update_alarm_check():

    if not alarm_enabled:
        return

    if alarm_triggered_today:
        return

    if TimeManager.current_hour == alarm_hour \
    and TimeManager.current_minute == alarm_minute:

        alarm_triggered_today = true

        print("⏰ ALARM RINGING!")

        # kalau punya audio player:
        # $AlarmSound.play()

        label_alarm_info.text = "⏰ ALARM RINGING!"


# ==========================================================
# STOPWATCH
# ==========================================================
func stopwatch_play_pause():

    stopwatch_running = !stopwatch_running

    if stopwatch_running:
        btn_sw_play.text = "Pause"
    else:
        btn_sw_play.text = "Start"


func stopwatch_left():

    if stopwatch_time <= 0.0:
        return

    stopwatch_running = false
    stopwatch_time = 0.0
    label_stopwatch.text = "00.00.00"
    btn_sw_play.text = "Start"


func update_stopwatch(delta):

    if not stopwatch_running:
        return

    stopwatch_time += delta

    var sec = int(stopwatch_time)
    var ms = int((stopwatch_time - sec) * 100)
    var min = sec / 60
    sec = sec % 60

    label_stopwatch.text = \
        str(min).pad_zeros(2) + "." + \
        str(sec).pad_zeros(2) + "." + \
        str(ms).pad_zeros(2)


# ==========================================================
# TIMER
# ==========================================================
func timer_start_pause():

    if timer_time <= 0:
        timer_time = \
            spin_th.value * 3600 + \
            spin_tm.value * 60 + \
            spin_ts.value

    timer_running = !timer_running

    if timer_running:
        btn_timer_start.text = "Pause"
    else:
        btn_timer_start.text = "Start"


func timer_reset():

    timer_running = false
    timer_time = 0
    label_timer.text = "00:00:00"
    btn_timer_start.text = "Start"


func update_timer(delta):

    if not timer_running:
        return

    timer_time -= delta

    if timer_time <= 0:
        timer_time = 0
        timer_running = false
        print("⏰ TIMER FINISHED")

    var total = int(timer_time)

    var h = total / 3600
    var m = (total % 3600) / 60
    var s = total % 60

    label_timer.text = \
        str(h).pad_zeros(2) + ":" + \
        str(m).pad_zeros(2) + ":" + \
        str(s).pad_zeros(2)


# ==========================================================
# CLOSE
# ==========================================================
func close_app():

    visible = false
    get_parent().close_current_app()
