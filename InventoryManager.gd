extends Node
class_name InventoryManagers

signal inventory_updated

@export var max_slots: int = 20  # Default, akan di-override oleh tas

var inventory_items: Array = []   # Array of InventoryItem


func add_item(item_data: ItemData, amount: int = 1) -> bool:
	if item_data == null:
		return false
	
	# Kalau stackable, coba cari item yang sama dulu
	if item_data.is_stackable:
		for inv_item in inventory_items:
			if inv_item.data.item_id == item_data.item_id:
				var space_left = inv_item.data.max_stack - inv_item.quantity
				
				if space_left > 0:
					var to_add = min(space_left, amount)
					inv_item.quantity += to_add
					amount -= to_add
					
					if amount <= 0:
						emit_signal("inventory_updated")
						return true
	
	# Kalau masih ada sisa atau tidak stackable
	while amount > 0:
		if inventory_items.size() >= max_slots:
			return false
		
		var new_item = InventoryItems.new()
		new_item.data = item_data
		
		if item_data.item_type == ItemData.ItemType.CONSUMABLE:
			new_item.current_durability = item_data.max_durability
		
		if item_data.is_stackable:
			var to_add = min(item_data.max_stack, amount)
			new_item.quantity = to_add
			amount -= to_add
		else:
			new_item.quantity = 1
			amount -= 1
		
		inventory_items.append(new_item)
	
	emit_signal("inventory_updated")
	return true


# ===============================
# REMOVE ITEM
# ===============================
func remove_item(item_id: String, amount: int = 1) -> bool:

	for inv_item in inventory_items:

		if inv_item.data.item_id == item_id:

			# =========================
			# REMOVE SEBANYAK MUNGKIN
			# =========================
			inv_item.quantity -= amount

			# =========================
			# HAPUS SLOT JIKA HABIS
			# =========================
			if inv_item.quantity <= 0:
				inventory_items.erase(inv_item)

			emit_signal("inventory_updated")

			print("DEBUG REMOVE ITEM:",
				item_id,
				"sisa:",
				inv_item.quantity if inv_item in inventory_items else 0
			)

			return true

	return false

func use_item(item_id: String) -> void:
	for inv_item in inventory_items:
		if inv_item.data.item_id == item_id:
			if inv_item.current_durability > 0:
				inv_item.current_durability -= 1
				NeedsManager.apply_item_effect(inv_item.data)  # Apply effect ke needs
				print("DEBUG: Durability item", item_id, "sekarang:", inv_item.current_durability)
			if inv_item.current_durability <= 0:
				inv_item.quantity -= 1
				print("DEBUG: Quantity item", item_id, "sekarang:", inv_item.quantity)
				if inv_item.quantity > 0:
					inv_item.current_durability = inv_item.data.max_durability  # Auto refill dari stack
					print("DEBUG: Auto refill durability dari stack untuk", item_id)
				else:
					inventory_items.erase(inv_item)
					print("DEBUG: Item", item_id, "habis total, hapus dari inventory")
			emit_signal("inventory_updated")
			return

func has_item(item_id: String) -> bool:
	for inv_item in inventory_items:
		if inv_item.data.item_id == item_id:
			return true
	return false

func get_items() -> Array:
	return inventory_items


func is_full() -> bool:
	return inventory_items.size() >= max_slots


func clear_inventory():
	inventory_items.clear()
	emit_signal("inventory_updated")
