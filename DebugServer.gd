extends Node


var server := TCPServer.new()
var clients = []
var scene_loading := false

func _ready():

	if !OS.is_debug_build():
		queue_free()
		return

	var err = server.listen(7777, "127.0.0.1")

	if err == OK:
		print("DEBUG SERVER RUNNING")
	else:
		print("FAILED START DEBUG SERVER")

func _process(delta):
	
	if scene_loading:
		return

	# TERIMA CONNECTION BARU
	if server.is_connection_available():

		var client = server.take_connection()

		clients.append(client)

	# PROCESS CLIENT
	for client in clients.duplicate():

		# CLIENT INVALID
		if client.get_status() != StreamPeerTCP.STATUS_CONNECTED:

			clients.erase(client)

			continue

		# ADA DATA
		if client.get_available_bytes() > 0:

			var data = client.get_utf8_string(
				client.get_available_bytes()
			)

			print("RECEIVED: ", data)

			handle_command(data)

			# CLOSE CLIENT SETELAH COMMAND
			client.disconnect_from_host()

			clients.erase(client)

func handle_command(cmd):

	var parts = cmd.split(":")

	match parts[0]:

		# =========================================
		# MONEY
		# =========================================

		"money":

			if parts.size() < 2:
				return

			PlayerData.money += int(parts[1])

		# =========================================
		# XP
		# =========================================

		"xp":

			if parts.size() < 2:
				return

			PlayerData.xp += int(parts[1])

		# =========================================
		# SET TIME
		# =========================================

		"set_time":

			if parts.size() < 3:
				return

			var hour = int(parts[1])
			var minute = int(parts[2])

			TimeManager.current_time_minutes = (hour * 60) + minute
			TimeManager.current_hour = hour
			TimeManager.current_minute = minute
			TimeManager.last_minute = -1

			TimeManager.game_time_changed.emit(hour, minute)

		# =========================================
		# GOD MODE
		# =========================================

		"godmode":

			PlayerData.hp = 999999
			PlayerData.max_hp = 999999

		# =========================================
		# FREEZE TIME
		# =========================================

		"freeze_time":

			TimeManager.time_frozen = true

		# =========================================
		# PLAYER SPEED
		# =========================================

		"speed":

			if parts.size() < 2:
				return

			var player = get_tree().get_first_node_in_group("player")

			if player == null:
				return

			if !is_instance_valid(player):
				return

			player.move_speed = float(parts[1])

		# =========================================
		# SPAWN ITEM
		# =========================================

		"spawn_item":

			if parts.size() < 3:
				return

			InventoryManager.add_item(
				parts[1],
				int(parts[2])
			)

		# =========================================
		# TELEPORT
		# =========================================

		"teleport":

			if parts.size() < 4:
				return

			var player = get_tree().get_first_node_in_group("player")

			if player == null:
				return

			if !is_instance_valid(player):
				return

			player.global_position = Vector3(
				float(parts[1]),
				float(parts[2]),
				float(parts[3])
			)

		# =========================================
		# INFINITE ENERGY
		# =========================================

		"infinite_energy":

			PlayerData.energy = 999999

		# =========================================
		# HEAL
		# =========================================

		"heal":

			PlayerData.hp = PlayerData.max_hp

func _notification(what):

	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		scene_loading = true

func _exit_tree():

	server.stop()

	clients.clear()
