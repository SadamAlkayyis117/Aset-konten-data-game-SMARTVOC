extends Resource
class_name InventoryItems

@export var data: ItemData
@export var quantity: int = 1
@export var current_durability: int = 0


func add_amount(amount: int):
	quantity += amount
	if quantity > data.max_stack:
		quantity = data.max_stack


func remove_amount(amount: int):
	quantity -= amount
	if quantity < 0:
		quantity = 0


func use_item() -> bool:
	if not data:
		return false
		
	if data.item_type != ItemData.ItemType.CONSUMABLE:
		return false
	
	if current_durability <= 0:
		return false
	
	current_durability -= 1
	print("Durability left:", current_durability)
	
	# Apply needs effect
	_apply_needs_effect()
	
	return current_durability <= 0  # true kalau habis

func _apply_needs_effect():
	if not NeedsManager or not data:
		return
	
	# Panggil efek lengkap dari NeedsManager
	NeedsManager.apply_item_effect(data)
