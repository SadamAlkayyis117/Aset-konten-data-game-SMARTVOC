extends Control

@onready var expr = $Panel_background/ScreenPanel/Label_Expression
@onready var result = $Panel_background/ScreenPanel/LabelResult
@onready var basic = $Panel_background/GridBasic
@onready var adv = $Panel_background/GridAdvance
@onready var py_panel = $Panel_background/ToolPanel/VBoxPhytagoras
@onready var stat_panel = $Panel_background/ToolPanel/VBoxStatistik
@onready var py_button = $Panel_background/ButtonPhytagoras
@onready var stat_button = $Panel_background/ButtonStatistik

var expression := ""
var advanced := false

func _ready():
    visible = false
    $Panel_background/Button_Close.pressed.connect(_on_ButtonClose_pressed)
    py_button.pressed.connect(_on_ButtonPythagoras_pressed)
    stat_button.pressed.connect(_on_ButtonStatistik_pressed)
    result.text = "0"
    expr.text = ""
    adv.visible = false
    py_button.visible = false
    stat_button.visible = false
    $Panel_background/ToolPanel.visible = false
    py_panel.visible = false
    stat_panel.visible = false
    _build_basic_buttons()
    _build_advance_buttons()
    _build_pythagoras_ui()
    _build_statistic_ui()

func open_app():
    visible = true
    advanced = false
    basic.visible = true
    adv.visible = false
    py_button.visible = false
    stat_button.visible = false
    $Panel_background/ToolPanel.visible = false
    py_panel.visible = false
    stat_panel.visible = false

func close_app():
    visible = false
    py_panel.visible = false
    stat_panel.visible = false

func input_value(v):

    expression += str(v)
    expr.text = expression

func clear_all():
    expression = ""
    expr.text = ""
    result.text = "0"

func backspace():
    if expression.length() > 0:
        expression = expression.substr(0, expression.length()-1)
        expr.text = expression

func _build_basic_buttons():

    var items = [
        "7","8","9","÷",
        "4","5","6","×",
        "1","2","3","-",
        "0",".","=","+",
        "C","DEL","ADV","%"
    ]

    for t in items:

        var btn = Button.new()
        btn.text = t
        btn.custom_minimum_size = Vector2(57,44)

        btn.pressed.connect(func():
            _basic_pressed(t)
        )

        basic.add_child(btn)

func _build_advance_buttons():

    var items = [
        "sin","cos","tan","√",
        "^","π","e","log",
        "(",")","!","BASIC"
    ]

    for t in items:

        var btn = Button.new()
        btn.text = t
        btn.custom_minimum_size = Vector2(57,44)

        btn.pressed.connect(func():
            _advance_pressed(t)
        )

        adv.add_child(btn)

func _basic_pressed(t):

    match t:
        "=":
            calculate()

        "C":
            clear_all()

        "DEL":
            backspace()

        "ADV":
            toggle_mode()

        _:
            input_value(t)

func _advance_pressed(t):

    match t:

        "BASIC":
            toggle_mode()

        "√":
            input_value("sqrt(")

        "π":
            input_value("π")

        "e":
            input_value("e")

        "sin":
            input_value("sin(")

        "cos":
            input_value("cos(")

        "tan":
            input_value("tan(")

        "log":
            input_value("log(")

        "!":
            input_value("!")

        _:
            input_value(t)

func calculate():

    var exp = expression

    exp = exp.replace("×","*")
    exp = exp.replace("÷","/")
    exp = exp.replace("^","**")
    exp = exp.replace("π", str(PI))
    exp = exp.replace("e", str(2.7182818))

    var val = Expression.new()
    var err = val.parse(exp)

    if err != OK:
        result.text = "ERROR"
        return

    var res = val.execute()

    result.text = str(res)

func toggle_mode():

    advanced = !advanced

    basic.visible = !advanced
    adv.visible = advanced

    py_button.visible = advanced
    stat_button.visible = advanced

    $Panel_background/ToolPanel.visible = false

    py_panel.visible = false
    stat_panel.visible = false

func _on_ButtonPythagoras_pressed():
    $Panel_background/ToolPanel.visible = true
    py_panel.visible = true
    stat_panel.visible = false

func _on_ButtonStatistik_pressed():
    $Panel_background/ToolPanel.visible = true
    py_panel.visible = false
    stat_panel.visible = true

func _build_pythagoras_ui():

    py_panel.add_theme_constant_override("separation", 10)

    var title = Label.new()
    title.text = "PYTHAGORAS"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    py_panel.add_child(title)

    var input_a = LineEdit.new()
    input_a.name = "InputA"
    input_a.placeholder_text = "Nilai a"
    py_panel.add_child(input_a)

    var input_b = LineEdit.new()
    input_b.name = "InputB"
    input_b.placeholder_text = "Nilai b"
    py_panel.add_child(input_b)

    var btn = Button.new()
    btn.text = "HITUNG"
    btn.pressed.connect(_solve_pythagoras)
    py_panel.add_child(btn)

    var out = Label.new()
    out.name = "Output"
    out.text = "c = ?"
    py_panel.add_child(out)

    var back = Button.new()
    back.text = "BACK"
    back.pressed.connect(_close_tool_panel)
    py_panel.add_child(back)

func _build_statistic_ui():

    stat_panel.add_theme_constant_override("separation", 10)

    var title = Label.new()
    title.text = "STATISTIK"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stat_panel.add_child(title)

    var txt = TextEdit.new()
    txt.name = "InputData"
    txt.custom_minimum_size = Vector2(0,100)
    txt.placeholder_text = "10,20,30,40"
    stat_panel.add_child(txt)

    var btn = Button.new()
    btn.text = "HITUNG"
    btn.pressed.connect(_solve_statistik)
    stat_panel.add_child(btn)

    var out = Label.new()
    out.name = "Output"
    out.text = "Mean = ?"
    out.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    stat_panel.add_child(out)
    
    var back = Button.new()
    back.text = "BACK"
    back.pressed.connect(_close_tool_panel)
    stat_panel.add_child(back)

func _solve_pythagoras():

    var a = float(py_panel.get_node("InputA").text)
    var b = float(py_panel.get_node("InputB").text)

    var c = sqrt(a*a + b*b)

    py_panel.get_node("Output").text = "c = " + str(c)

func _solve_statistik():

    var raw = stat_panel.get_node("InputData").text
    var arr = raw.split(",")

    var nums = []

    for n in arr:
        nums.append(float(n.strip_edges()))

    if nums.size() == 0:
        return

    var total = 0.0

    for n in nums:
        total += n

    var mean = total / nums.size()

    stat_panel.get_node("Output").text = "Mean = " + str(mean)

func _on_ButtonClose_pressed():

    close_app()

    get_parent().current_app_open = false

func _close_tool_panel():

    $Panel_background/ToolPanel.visible = false
    py_panel.visible = false
    stat_panel.visible = false
