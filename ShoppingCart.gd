extends Node
class_name ShoppingCart

# ==============================
# DATA
# ==============================

var items : Dictionary = {}
# format:
# items[item_id] = {
#     "item_data": ItemData,
#     "quantity": int
# }

# ==============================
# ADD ITEM
# ==============================

func add_item(item_data, amount: int = 1) -> void:
    if item_data == null:
        return
    
    var id = item_data.item_id
    
    if items.has(id):
        items[id]["quantity"] += amount
    else:
        items[id] = {
            "item_data": item_data,
            "quantity": amount
        }

# ==============================
# REMOVE ITEM
# ==============================

func remove_item(item_id: String, amount: int = 1) -> void:
    if not items.has(item_id):
        return
    
    items[item_id]["quantity"] -= amount
    
    if items[item_id]["quantity"] <= 0:
        items.erase(item_id)

# ==============================
# GET TOTAL PRICE
# ==============================

func get_total_price() -> int:
    var total := 0
    
    for id in items.keys():
        var data = items[id]["item_data"]
        var qty  = items[id]["quantity"]
        
        total += data.price * qty
    
    return total

# ==============================
# CLEAR CART
# ==============================

func clear_cart() -> void:
    items.clear()

# ==============================
# HELPER
# ==============================

func is_empty() -> bool:
    return items.is_empty()

func get_total_items_count() -> int:
    var count := 0
    for id in items.keys():
        count += items[id]["quantity"]
    return count
