extends Control

@onready var label_month = $Panel_background/Label_MonthYear
@onready var grid = $Panel_background/GridContainer
@onready var label_today = $Panel_background/Label_Today
@onready var btn_prev = $Panel_background/Button_Previous
@onready var btn_next = $Panel_background/Button_Next
@onready var close_button = $Panel_background/Button_Close

var current_month := 1
var current_year := 2025

const MONTH_NAMES = [
    "January","February","March","April","May","June",
    "July","August","September","October","November","December"
]

func _ready():
    close_button.pressed.connect(_on_close_pressed)

    current_month = TimeManager.current_month
    current_year = TimeManager.current_year

    btn_prev.pressed.connect(_prev_month)
    btn_next.pressed.connect(_next_month)

    build_calendar()


func build_calendar():

    for c in grid.get_children():
        c.queue_free()

    label_month.text = MONTH_NAMES[current_month - 1] + " " + str(current_year)

    var total_days = 30

    for i in range(1, total_days + 1):

        var b = Button.new()
        b.text = str(i)

        if i == TimeManager.current_date \
        and current_month == TimeManager.current_month \
        and current_year == TimeManager.current_year:
            b.modulate = Color(0.4,1,0.4)

        grid.add_child(b)

    label_today.text = "Today: " + \
    TimeManager.WEEKDAY_NAMES[TimeManager.current_day_of_week - 1] + \
    ", " + str(TimeManager.current_date)


func _prev_month():

    current_month -= 1

    if current_month <= 0:
        current_month = 12
        current_year -= 1

    build_calendar()


func _next_month():

    current_month += 1

    if current_month > 12:
        current_month = 1
        current_year += 1

    build_calendar()

func _on_close_pressed():
    visible = false
    get_parent().close_current_app()
