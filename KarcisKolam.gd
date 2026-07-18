extends Node3D
class_name PoolCashier

@onready var interact_area = $InteractArea

const TICKET_PRICE := 10000

var payment_processing := false

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.set_interactable(self)

func _on_body_exited(body):
	if body.is_in_group("player"):
		body.clear_interactable(self)

func interact(player):
	process_payment(player)

func process_payment(player):

	if payment_processing:
		return

	if PlayerData.has_pool_ticket:
		print("Sudah punya tiket.")
		return

	if PlayerData.money < TICKET_PRICE:
		print("Uang tidak cukup.")
		return

	payment_processing = true

	player.open_wallet_payment(
		TICKET_PRICE,
		"Tiket Kolam Renang",
		func(success):

			payment_processing = false

			if success:
				_on_payment_success(player)
	)

func _on_payment_success(player):

	PlayerData.has_pool_ticket = true

	PlayerData.add_transaction(
		"Beli tiket kolam Rp " + str(TICKET_PRICE)
	)

	print("Tiket berhasil dibeli.")
