extends Node

var peer = WebSocketMultiplayerPeer.new()
var users = {}
var lobbies = {}
var dao = DB.new()
var Characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

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
	pass

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
	var username = data.get("data", {}).get("username", "")
	var password = data.get("data", {}).get("password", "")
	
	if username.is_empty():
		push_error("CreateUser: Missing username in data")
		send_failure_response(data, "Username cannot be empty")
		return
	
	if dao.UsernameExists(username):
		send_failure_response(data, "Username already exists")
		return
	
	dao.InsertUserData(username, password)
	login(data)
	
	
func send_failure_response(original_data: Dictionary, reason: String) -> void:
	var response = {
		"message": Message.Message.createUser,
		"success": false,
		"requestId": original_data.get("requestId", -1),
		"reason": reason
	}
	SendToPlayer(original_data.get("orgPeer", -1), response)
	
func login(data):
	var userData = dao.GetUserFromDB(data.data.username)
	if(userData.password == data.data.password): 
		var returnData = {
			"username" : userData.name,
			"id" : userData.id,
			"message" : Message.Message.playerinfo,
		}
		peer.get_peer(data.peer).put_packet(JSON.stringify(returnData).to_utf8_buffer())
	else:
		var returnData ={
			"message" : Message.Message.failedToLogin,
			"text" : "Failed to login invalid username or password"
		}
		peer.get_peer(data.peer).put_packet(JSON.stringify(returnData).to_utf8_buffer())
func SendToPlayer(userId, data):
	peer.get_peer(userId).put_packet(JSON.stringify(data).to_utf8_buffer())
	
func GenString():
	var string = ""
	for i in range(32):
		string += Characters[randi() % Characters.length()]
	return string

func StartServer():
	peer.create_server(8915)
	print("Server has started")

func _on_start_server_button_down():
	StartServer()
	pass
