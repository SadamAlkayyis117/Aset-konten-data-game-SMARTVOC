extends Control

signal buy_pressed(recipe_id)

var recipe_id := ""

@onready var panel = $Panel
@onready var label_name = $Panel/LabelName
@onready var label_price = $Panel/LabelPrice
@onready var button_buy = $Panel/ButtonBuy

func _ready():
	if button_buy:
		button_buy.pressed.connect(_on_buy_pressed)

func setup(id:String, recipe:Dictionary):
	recipe_id = id
	if label_name:
		label_name.text = str(recipe.get("name", "Unknown"))
	if label_price:
		label_price.text = "Rp " + str(recipe.get("cafe_price", 10000))

	# Pastikan background ColorRect punya warna & tidak memblok input
	if panel and panel is ColorRect:
		panel.color = panel.color  # (opsional, hanya memastikan property ada)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _on_buy_pressed():
	buy_pressed.emit(recipe_id)
