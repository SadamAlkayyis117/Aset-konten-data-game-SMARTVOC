extends Node3D
class_name Cashier

@onready var interact_area = $InteractArea

func _ready():
	interact_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player"):
		body.set_interactable(self)

func process_payment(player):

	var total = StoreTransactionManager.calculate_total_price()

	if total <= 0:
		return

	player.open_wallet_payment(
		total,
		"Pembayaran Belanja",
		func(success):

			if success:

				StoreTransactionManager.mark_all_paid()

				print("✅ Pembayaran berhasil")
	)
