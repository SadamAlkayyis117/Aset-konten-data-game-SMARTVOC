extends Node

# ==========================================================
# 💰 PLAYER ECONOMY CORE
# ==========================================================

signal money_changed
signal transaction_logged(type, amount, description)
signal transaction_added(entry)

var has_pool_ticket := false
var transaction_log: Array[String] = []
var money: int = 0
var bank_savings: int = 0

# ==========================================================
# 🎁 DAILY ALLOWANCE CONFIG
# ==========================================================

const DAILY_ALLOWANCE: int = 15000

# ==========================================================
# 💵 MONEY FUNCTIONS
# ==========================================================

func add_money(amount: int, description: String = "Income"):
	if amount <= 0:
		return

	money += amount
	print("[Money] +", amount, "| Total:", money)
	
	money_changed.emit()
	transaction_logged.emit("INCOME", amount, description)


func spend_money(amount: int, description: String = "Expense") -> bool:
	if amount <= 0:
		return false
		
	if money < amount:
		print("[Money] Not enough funds.")
		return false

	money -= amount
	print("[Money] -", amount, "| Total:", money)

	money_changed.emit()
	transaction_logged.emit("EXPENSE", amount, description)
	return true


func can_afford(amount: int) -> bool:
	return money >= amount

func add_transaction(text: String):
	transaction_log.append(text)
	emit_signal("transaction_added", text)

func get_transaction_log():
	return transaction_log

# ==========================================================
# 🏦 SIMPLE SAVINGS SYSTEM
# ==========================================================

func deposit_to_savings(amount: int) -> bool:
	if money < amount:
		return false
		
	money -= amount
	bank_savings += amount

	money_changed.emit()
	return true


func get_balance() -> int:
	return money


func get_savings() -> int:
	return bank_savings


# ==========================================================
# 📅 DAILY ALLOWANCE TRIGGER
# ==========================================================

func give_daily_allowance():
	add_money(DAILY_ALLOWANCE, "Daily Allowance")
