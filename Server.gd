extends Node

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
var dao = DB.new()
var Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
var user_sessions = {}
func _ready():
	peer.connect("peer_connected", peer_connected)
	peer.connect("peer_disconnected", peer_disconnected)
	load_lobbies()
	pass
	
func load_lobbies():
	var query = "SELECT * FROM lobbies"
	if dao.db.query(query):
		for lobby_data in dao.db.query_result:
			var lobby_id = lobby_data["lobby_id"]
			var host_user_id = lobby_data["host_id"]
			
			var lobby = Lobby.new(host_user_id)  
			
			lobby.lobby_name = lobby_data["lobby_name"]
			lobby.created_at = lobby_data["created_at"]
			
			lobbies[lobby_id] = lobby
			print("Loaded lobby: ", lobby_id)
	else:
		push_error("Failed to load lobbies: " + dao.db.error_message)	
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			if data.message == Message.Message.SaveProfile:
				handle_save_profile(data)

			if data.message == Message.Message.LoadProfile:
				handle_load_profile(data)

			if data.message == Message.Message.SaveInventory:
				handle_save_inventory(data)

			if data.message == Message.Message.LoadInventory:
				handle_load_inventory(data)

			if data.message ==  Message.Message.lobby:
				JoinLobby(data)
			
			if data.message == Message.Message.loginUser:
				login(data)
			if data.message == Message.Message.createLobby:
				create_lobby(data)
			
			if data.message == Message.Message.requestLobbies:
				handle_lobby_request(data)
			
			if data.message == Message.Message.createUser:
				create_user(data)
				
			if data.message ==  Message.Message.offer || data.message ==  Message.Message.answer || data.message ==  Message.Message.candidate:
				print("source id is " + str(data.orgPeer))
				SendToPlayer(data.peer, data)
				
			if data.message ==  Message.Message.removeLobby:
				if lobbies.has(data.lobbyID):
					lobbies.erase(data.lobbyID)
					
			if data.message == Message.Message.InventoryRequest:
				handle_inventory_request(data)
				
			if data.message == Message.Message.createItem:
				var item_data = data.get("data", {})
		
				var peer_id = data.get("orgPeer", -1)
					
				item_data["user_id"] = user_sessions[peer_id]
				var success = dao.insertItem(item_data)
				
			if data.message == Message.Message.requestParticipants:
				handle_participants_request(data)
	pass

func handle_participants_request(data: Dictionary):
	var lobby_id = data.lobby_id
	var participants = dao.get_lobby_participants(lobby_id)
	var host_id = dao.get_lobby_host(lobby_id)
	
	var response = {
		"message": Message.Message.participantsData,
		"participants": participants,
		"host_id": host_id,
		"lobby_id": lobby_id,
		"orgPeer": data.orgPeer
	}
	
	SendToPlayer(data.orgPeer, response)

func broadcast_participant_update(lobby_id: String):
	var participants = dao.get_lobby_participants(lobby_id)
	var host_id = dao.get_lobby_host(lobby_id)
	
	var update = {
		"message": Message.Message.participantsData,
		"participants": participants,
		"host_id": host_id,
		"lobby_id": lobby_id
	}
	
	if lobbies.has(lobby_id):
		for peer_id in lobbies[lobby_id].Players:
			SendToPlayer(peer_id, update)

func create_lobby(data: Dictionary) -> void:
	var lobby_id = GenString()
	var user_id = user_sessions[data.orgPeer]
	
	var lobby_data = {
		"lobby_id": lobby_id,
		"host_id": user_id,
		"lobby_name": data.get("lobby_name", "Unnamed Lobby"),
		"created_at": Time.get_datetime_string_from_system()
	}
	
	if dao.insert_lobby(lobby_data):
		dao.add_participant(lobby_id, user_id, true)
		lobbies[lobby_id] = Lobby.new(user_id)
		
		
func handle_lobby_request(data: Dictionary) -> void:
	var user_id = user_sessions[data.orgPeer]
	var user_lobbies = dao.get_user_lobbies(user_id)
	
	var response = {
		"message": Message.Message.lobbyData,
		"lobbies": user_lobbies,
		"orgPeer": data.orgPeer
	}
	SendToPlayer(data.orgPeer, response)
func handle_inventory_request(data: Dictionary) -> void:
	var peer_id = data.get("orgPeer", -1)
	
	if not user_sessions.has(peer_id):
		push_error("User not authenticated for inventory request")
		return
		
	var user_id = user_sessions[peer_id]
	var items = dao.load_items_by_lobby(data.lobby_id, str(user_id))
	
	var response = {
		"message": Message.Message.InventoryData,
		"items": items if items is Array else [],
		"orgPeer": peer_id
	}
	SendToPlayer(peer_id, response)
	
func peer_connected(id):
	print("Peer Connected: " + str(id))
	users[id] = {
		"id" : id,
		"message" :  Message.Message.id
	}
	peer.get_peer(id).put_packet(JSON.stringify(users[id]).to_utf8_buffer())
	pass
	
func peer_disconnected(id):
	users.erase(id)
	pass


func JoinLobby(user):
	var peer_id = user.orgPeer
	var lobby_id = user.lobbyValue
	
	if not user_sessions.has(peer_id):
		push_error("Unauthorized join attempt")
		return
	
	var user_id = user_sessions[peer_id]
	
	# Add to database as participant
	if not dao.add_participant(lobby_id, user_id, false):
		push_error("Failed to add participant to DB")
		return
	
	# Existing lobby case
	if lobbies.has(lobby_id):
		var lobby = lobbies[lobby_id]
		var player_name = str(user.get("name", "Anonymous"))
		
		# Add player to lobby
		var player = lobby.AddPlayer(peer_id, player_name)
		
		# Prepare players data
		var players_data = {}
		for p in lobby.Players:
			players_data[str(p)] = lobby.Players[p]
		
		# Notify all players
		for p in lobby.Players:
			var newPlayer = peer_id if p != peer_id else null
			SendToPlayer(p, {
				"message": Message.Message.lobbyUpdate,
				"host": lobby.host_peer_id,
				"lobbyValue": lobby_id,
				"players": players_data,
				"newPlayer": newPlayer
			})
	
	# New lobby case - FIXED
	else:
		# Generate new lobby ID
		var new_lobby_id = GenString()
		
		# Create and store new lobby with new ID
		var lobby = Lobby.new(user_id)
		lobby.host_peer_id = peer_id  # Set host peer ID
		lobby.lobby_name = str(user.get("lobby_name", "Unnamed Lobby"))
		lobbies[new_lobby_id] = lobby
		
		# Insert to database
		var lobby_data = {
			"lobby_id": new_lobby_id,
			"host_id": user_id,
			"lobby_name": lobby.lobby_name,
			"created_at": Time.get_datetime_string_from_system()
		}
		
		if dao.insert_lobby(lobby_data):
			# Add host as participant
			dao.add_participant(new_lobby_id, user_id, true)
			
			# Add player to lobby
			lobby.AddPlayer(peer_id, str(user.get("name", "Anonymous")))
			
			# Notify creator
			SendToPlayer(peer_id, {
				"message": Message.Message.lobbyCreated,
				"lobby_id": new_lobby_id,
				"host": peer_id
			})
			
			lobby_id = new_lobby_id
	
	broadcast_participant_update(lobby_id)
	

func update_lobby_participants(lobby_id: String):
	var participants = dao.get_lobby_participants(lobby_id)
	var participant_data = {
		"message": Message.Message.lobbyParticipants,
		"participants": participants,
		"lobby_id": lobby_id
	}
	
	if lobbies.has(lobby_id):
		for peer_id in lobbies[lobby_id].Players:
			SendToPlayer(peer_id, participant_data)
	
func create_user(data: Dictionary) -> void:
	var user_data = data.get("data", {})
	var username = user_data.get("username", "")
	var email = user_data.get("email", "")
	var password = user_data.get("password", "")
	
	# Validate inputs
	if username.is_empty():
		push_error("CreateUser: Missing username in data")
		send_failure_response(data, "Username cannot be empty")
		return
	if email.is_empty():
		push_error("CreateUser: Missing email in data")
		send_failure_response(data, "Email cannot be empty")
		return
	if password.is_empty():
		push_error("CreateUser: Missing password in data")
		send_failure_response(data, "Password cannot be empty")
		return
	
	if dao.UsernameExists(username):
		send_failure_response(data, "Username already exists")
		return
	
	if dao.EmailExists(email):
		send_failure_response(data, "Email already registered")
		return
	if data.message == Message.Message.LoadProfile:
		handle_load_profile(data)
	# Insert new user with hashed password
	dao.InsertUserData(username, email, password)
	
	# Automatically log in the user after registration
	login(data)
	
func handle_load_profile(data: Dictionary):
	var user_id = data.get("user_id")
	var lobby_id = data.get("lobby_id")

	var profile = dao.load_profile(user_id, lobby_id)

	var response = {
		"message": Message.Message.LoadProfile,
		"user_id": user_id,
		"lobby_id": lobby_id,
		"profile": profile
	}
	SendToPlayer(data.get("orgPeer", -1), response)
	
func send_failure_response(original_data: Dictionary, reason: String) -> void:
	var response = {
		"message": Message.Message.failedToLogin,
		"text": reason,
		"orgPeer": original_data.get("orgPeer", -1)
	}
	SendToPlayer(original_data.get("orgPeer", -1), response)
	
func login(data):
	var user_data = data.get("data", "")
	var email = user_data.get("email", "")
	var password = user_data.get("password", "")
	
	if dao.VerifyUser(email, password):
		var ema = dao.GetUserFromDB(email)
		var user_id = ema["id"] 
		
		user_sessions[data.orgPeer] = user_id
		
		for lobby_id in lobbies:
			var lobby = lobbies[lobby_id]
			if lobby.host_user_id == user_id: 
				lobby.host_peer_id = data.orgPeer 
				print("Host reconnected to lobby: ", lobby_id)
		
		var returnData = {
			"username": ema["name"],
			"email": ema["email"],
			"id": user_id,
			"message": Message.Message.playerinfo,
		}
		peer.get_peer(data.orgPeer).put_packet(JSON.stringify(returnData).to_utf8_buffer())
	else:
		send_failure_response(data, "Invalid username or password")
		
func SendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func GenString():
	var string = ""
	for i in range(32):
		string += Characters[randi() % Characters.length()]
	return string

func handle_save_profile(data: Dictionary):
	var user_id = data.get("user_id")
	var lobby_id = data.get("lobby_id")
	var profile = data.get("profile", {})

	var success = dao.save_profile(user_id, lobby_id, profile)
	print("✅ SaveProfile: ", success)


func handle_save_inventory(data: Dictionary):
	var user_id = data.get("user_id")
	var lobby_id = data.get("lobby_id")
	var items = data.get("items", [])

	var success = dao.save_inventory(user_id, lobby_id, items)
	print("✅ SaveInventory: ", success)

func handle_load_inventory(data: Dictionary):
	var user_id = data.get("user_id")
	var lobby_id = data.get("lobby_id")

	print("🔍 Загрузка инвентаря для пользователя:", user_id, "лобби:", lobby_id) # ✅ ОБЯЗАТЕЛЬНО добавь!
	print("🔍 Загрузка инвентаря для пользователя: %s, лобби: %s" % [user_id, lobby_id])

	var items = dao.load_inventory(user_id, lobby_id)

	var response = {
		"message": Message.Message.LoadInventory,
		"user_id": user_id,
		"lobby_id": lobby_id,
		"items": items
	}
	SendToPlayer(data.get("orgPeer", -1), response)

func handle_profile_request(data: Dictionary):
	var requested_id = int(data.get("user_id", -1))
	var peer_id = data.get("orgPeer", -1)

	var profile = dao.get_user_profile(requested_id)
	profile["user_id"] = requested_id

	var response = {
		"message": Message.Message.profileData,
		"user_id": requested_id,
		"profile": profile,
		"orgPeer": peer_id
	}
	SendToPlayer(peer_id, response)


func StartServer():
	var error = peer.create_server(8915)
	if error == OK:
		return true
	return false

func _on_start_server_button_down():
	StartServer()
