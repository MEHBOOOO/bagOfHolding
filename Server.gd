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
	pass

func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			print(data)
			
			if data.message ==  Message.Message.lobby:
				JoinLobby(data)
			
			if data.message == Message.Message.loginUser:
				login(data)
				
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
	pass
	
func handle_inventory_request(data: Dictionary) -> void:
	var peer_id = data.get("orgPeer", -1)
	
	if not user_sessions.has(peer_id):
		push_error("User not authenticated for inventory request")
		return
		
	var user_id = user_sessions[peer_id]
	var items = dao.load_items_by_user(user_id) 
	
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
	var result = ""
	if user.lobbyValue == "":
		user.lobbyValue = GenString()
		lobbies[user.lobbyValue] = Lobby.new(user.id)
		print(user.lobbyValue)
	var player = lobbies[user.lobbyValue].AddPlayer(user.id, user.name)
	
	for p in lobbies[user.lobbyValue].Players:
		
		var data = {
			"message" :  Message.Message.userConnected,
			"id" : user.id
		}
		SendToPlayer(p, data)
		
		var data2 = {
			"message" :  Message.Message.userConnected,
			"id" : p
		}
		SendToPlayer(user.id, data2)
		
		var lobbyInfo = {
			"message" :  Message.Message.lobby,
			"players" : JSON.stringify(lobbies[user.lobbyValue].Players),
			"host" : lobbies[user.lobbyValue].HostID,
			"lobbyValue" : user.lobbyValue
		}
		SendToPlayer(p, lobbyInfo)
		
	var data = {
		"message" :  Message.Message.userConnected,
		"id" : user.id,
		"host" : lobbies[user.lobbyValue].HostID,
		"player" : lobbies[user.lobbyValue].Players[user.id],
		"lobbyValue" : user.lobbyValue
	}
	SendToPlayer(user.id, data)
	
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
	
	# Insert new user with hashed password
	dao.InsertUserData(username, email, password)
	
	# Automatically log in the user after registration
	login(data)
	
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
		user_sessions[data.orgPeer] = ema["id"]
		var returnData = {
			"username": ema["name"],
			"email": ema["email"],
			"id": ema["id"],
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


func StartServer():
	var error = peer.create_server(8915)
	if error == OK:
		return true
	return false

func _on_start_server_button_down():
	StartServer()
