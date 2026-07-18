extends Node

# ==============================
# PLAYER DATA
# ==============================

var unpaid_hand_items: Array = [] # ItemData
var unpaid_inventory_items: Array = []
var player = null
var player_money: int = 100


func add_money(amount: int):
	player_money += amount

func remove_money(amount: int) -> bool:
	if player_money >= amount:
		player_money -= amount
		return true
	return false

func is_item_unpaid(item_data: ItemData):

	print("=== CHECK UNPAID ===")
	print("CHECK:", item_data.item_id)

	for data in unpaid_inventory_items:
		print("INV UNPAID:", data.item_id)

		if data.item_id == item_data.item_id:
			print("MATCH INVENTORY")
			return true

	for data in unpaid_hand_items:
		print("HAND UNPAID:", data.item_id)

		if data.item_id == item_data.item_id:
			print("MATCH HAND")
			return true

	print("NOT UNPAID")
	return false

func mark_all_paid():
	unpaid_inventory_items = []
	unpaid_hand_items = []
	print("✅ Semua unpaid item dibersihkan")

func register_unpaid_inventory(item_data: ItemData):
	unpaid_inventory_items.append(item_data)

func register_unpaid_hand(item_data: ItemData):
	unpaid_hand_items.append(item_data)

func clear_all_unpaid(player):

	# =========================
	# HAPUS ITEM DI TANGAN
	# =========================
	for hand in [player.right_hand_attachment, player.left_hand_attachment]:

		for child in hand.get_children():

			if child.has_meta("item_id"):

				var item_id = child.get_meta("item_id")

				# cek apakah item unpaid
				if equipped_item_is_unpaid(item_id):

					child.queue_free()

					if player.equipped_items.has(item_id):
						player.equipped_items.erase(item_id)

					if player.equipped_source.has(item_id):
						player.equipped_source.erase(item_id)

	# =========================
	# HAPUS ITEM INVENTORY
	# =========================
	for item_data in unpaid_inventory_items:

		InventoryManager.remove_item(item_data.item_id, 999)

	# =========================
	# FIX PENTING:
	# CLEAR SAVE SEMENTARA
	# =========================
	GM.carried_items.clear()

	# =========================
	# CLEAR LIST UNPAID
	# =========================
	unpaid_inventory_items.clear()
	unpaid_hand_items.clear()

	# =========================
	# REFRESH UI INVENTORY
	# =========================
	InventoryManager.emit_signal("inventory_updated")

	print("🔥 FORCE CLEAR ALL UNPAID + VISUAL + SAVE DATA")

func equipped_item_is_unpaid(item_id: String) -> bool:

	for item_data in unpaid_hand_items:

		if item_data.item_id == item_id:
			return true

	return false

func calculate_total_price() -> int:
	var total = 0
	for item in unpaid_inventory_items:
		total += item.price
	for item in unpaid_hand_items:
		total += item.price
	print("TOTAL UNPAID:", total)
	return total
