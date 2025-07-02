extends Node
signal login_requested(email, password)
signal create_user_requested(email, username, password)
signal login_failed(message)
signal player_info_received(info)
signal lobby_join_successful(lobby_info)
signal load_inventory()
signal createItem(data)
signal lobby_created(lobby_id)
signal lobbies_received(lobbies)
signal participant_update_received(participants_data)
signal player_disconnected()
signal profile_save_completed(success)  
signal profiles_list_received(profiles) 
signal profile_data_received(user_id, profile_data)  # For profile data
signal inventory_data_received(user_id, items) 
signal kicked_from_lobby(reason)
signal joinsuccess(reason)
signal lobby_join_failed(reason)     # Add this signal
signal already_in_lobby()            # Add this signal
signal lobby_join_success(reason)    # Keep this signal
signal lobby_created_suc(reason)

var peer = WebSocketMultiplayerPeer.new()
var id = 0
var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var hostId :int
var lobbyValue = ""
var lobbyInfo = {}
var current_user_items : Array = [] 
var current_user_id: int = 0 


func _ready():
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	login_requested.connect(_on_login_requested)
	create_user_requested.connect(_on_create_user_requested)
	load_inventory.connect(_on_load_inventory_requested) 
	connectToServer("")
	pass # Replace with function body.

func _on_login_requested(email, password):
	loginUser(email, password)
	
func _on_create_user_requested(email, username, password):
	createUser(email, username, password)
	
	
func createUser(email,username, password):
	var data = {
	"email" : email.strip_edges(true, true), 
	"username" : username.strip_edges(true, true), 
	"password" : password.strip_edges(true, true)
	}
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.Message.createUser,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func loginUser(email, password):
	var data = {
	"email" : email.strip_edges(true, true), 
	"password" : password.strip_edges(true, true)
	}
	
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" :  Message.Message.loginUser,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func load_item_names_from_db() -> void:
	var message = {
		"peer": id,
		"orgPeer": id,
		"lobby_id": GameManager.current_lobby_id,  
		"message": Message.Message.InventoryRequest
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func RTCServerConnected():
	print("RTC server connected")

func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))

func request_create_item(data: Dictionary) -> void:
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.createItem, 
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			
			print(data)
			if data.message == Message.Message.lobbyJoinSuccess:
				lobby_join_success.emit("success")
			
			# Add these new message handlers
			if data.message == Message.Message.lobbyJoinFailed:
				lobby_join_failed.emit(data.reason)
				
			if data.message == Message.Message.alreadyInLobby:
				already_in_lobby.emit()
				
			
			if data.message == Message.Message.id:
				id = data.id
				
				connected(id)
				
			if data.message == Message.Message.userConnected:
				#GameManager.Players[data.id] = data.player
				createPeer(data.id)
			
			if data.message == Message.Message.lobbyCreated:
				lobby_created.emit()
				lobby_created_suc.emit("reason")
				
				
			if data.message == Message.Message.lobbyData:
				lobbies_received.emit(data.lobbies)
			
			if data.message == Message.Message.lobby:
				var raw_players = JSON.parse_string(data.players)
				var fixed_players = {}
				for key in raw_players.keys():
					fixed_players[int(key)] = raw_players[key]  # ✅ конвертация в числа
				GameManager.Players = fixed_players
				print("✅ GameManager.Players:", GameManager.Players)
			
			#if data.message == Message.Message.LoadInventory:
				#emit_signal("inventory_data_received", data.get("items", []))
			#if data.message == Message.Message.LoadInventory:
				#emit_signal("inventory_data_received", data.get("items", []))

			
				
			if data.message == Message.Message.candidate:
				if rtcPeer.has_peer(data.orgPeer):
					print("Got Candididate: " + str(data.orgPeer) + " my id is " + str(id))
					rtcPeer.get_peer(data.orgPeer).connection.add_ice_candidate(data.mid, data.index, data.sdp)
			
			if data.message == Message.Message.offer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("offer", data.data)
			
			if data.message == Message.Message.answer:
				if rtcPeer.has_peer(data.orgPeer):
					rtcPeer.get_peer(data.orgPeer).connection.set_remote_description("answer", data.data)
					
			if data.message == Message.Message.playerinfo:
				current_user_id = data.get("id", 0)
				player_info_received.emit(data)
				# или сохранить в глобальной переменной, если используешь GameManager
				get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
				
			if data.message == Message.Message.failedToLogin:
				login_failed.emit(data.text) 
				
			if data.message == Message.Message.InventoryData:
				current_user_items = data.get("items", []) 
				inventory_data_received.emit(current_user_items)
			if data.message == Message.Message.getLobbies:
				emit_signal("lobbies_received", data["lobbies"])
				
			if data.message == Message.Message.participantsData:
				participant_update_received.emit(data)
				
			if data.message == Message.Message.userDisconnected:
				player_disconnected.emit()
				
			if data.message == Message.Message.LoadProfile:
				emit_signal("profile_data_received", 
					data.get("user_id", -1), 
					{
						"name": data.get("name", ""),
						"avatar_id": data.get("avatar_id", 0),
						"class": data.get("class", ""),
						"description": data.get("description", "")
					}
				)
				
			if data.message == Message.Message.SaveProfile:
				emit_signal("profile_save_completed", data.get("success", false))
				
			if data.message == Message.Message.GetAllProfiles:
				var profiles = data.get("profiles", [])
				# Add lobby_id to each profile
				for profile in profiles:
					profile["lobby_id"] = profile.get("lobby_id", "")
				emit_signal("profiles_list_received", profiles)
				
			if data.message == Message.Message.LoadInventory:
				var user_id = data.get("user_id", -1)
				var items = data.get("items", [])
				emit_signal("inventory_data_received", user_id, items)
			if data.message == Message.Message.kickedFromLobby:
				kicked_from_lobby.emit(data.reason)
			if data.message == Message.Message.LoadInventory:
				var user_id = data.get("user_id", -1)
				var items = data.get("items", [])
				emit_signal("inventory_data_received", user_id, items)
			if data.message == Message.Message.kickedFromLobby:
				print("Kicked from lobby:", data.reason)
				get_tree().change_scene_to_file("res://Scenes/Lobbies.tscn")
			if data.message == Message.Message.deleteItemResponse:
				if data.success:
					print("✅ Item deleted successfully")
				else:
					push_error("Failed to delete item: " + data.reason)

	pass

func request_delete_item(item_id: int, user_id: int, lobby_id: String):
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.deleteItem,
		"item_id": item_id,
		"user_id": user_id,
		"lobby_id": lobby_id
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer

func create_lobby(lobby_name: String):
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.createLobby,
		"lobby_name": lobby_name
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
func send_request_lobbies(user_id: int):
	var data = {
		"message": Message.Message.getLobbies,
		"user_id": user_id
	}
	peer.put_packet(JSON.stringify(data).to_utf8_buffer())

func request_user_lobbies():
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.requestLobbies
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
#web rtc connection
func createPeer(id):
	if id != self.id:
		var peer : WebRTCPeerConnection = WebRTCPeerConnection.new()
		peer.initialize({
			"iceServers" : [{ "urls": ["stun:stun.l.google.com:19302"] }]
		})
		print("Binding id " + str(id) + "my id is " + str(self.id))
		
		peer.session_description_created.connect(self.offerCreated.bind(id))
		peer.ice_candidate_created.connect(self.iceCandidateCreated.bind(id))
		rtcPeer.add_peer(peer, id)
		
		if id < rtcPeer.get_unique_id():
			peer.create_offer()
		pass
		

func offerCreated(type, data, id):
	if !rtcPeer.has_peer(id):
		return
		
	rtcPeer.get_peer(id).connection.set_local_description(type, data)
	
	if type == "offer":
		sendOffer(id, data)
	else:
		sendAnswer(id, data)
	pass
	
	
func sendOffer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" :  Message.Message.offer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func sendAnswer(id, data):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" : Message.Message.answer,
		"data": data,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func iceCandidateCreated(midName, indexName, sdpName, id):
	var message = {
		"peer" : id,
		"orgPeer" : self.id,
		"message" :  Message.Message.candidate,
		"mid": midName,
		"index": indexName,
		"sdp": sdpName,
		"Lobby": lobbyValue
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass

func connectToServer(ip):
	var error = peer.create_client("ws://127.0.0.1:8915")
	#var error = peer.create_client("ws://10.18.2.7:8915")
	if error != OK:
		print("Failed to connect to server: " + str(error))
	else:
		print("Client started")


func _on_start_client_button_down():
	connectToServer("")
	pass


@rpc("any_peer", "call_local")

func _on_join_lobby_button_down():
	var message ={
		"id" : id,
		"message" : Message.Message.lobby,
		"name" : "",
		"orgPeer": id,
		"lobbyValue" : $Lobby.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.

# ---------- Индивидуальный профиль ----------

func _on_load_inventory_requested():
	# Request inventory for current user and lobby
	request_inventory(current_user_id, GameManager.current_lobby_id)

func save_profile(user_id: int, lobby_id: String, profile_data: Dictionary):
	var data = {
		"name": profile_data.get("name", ""),
		"avatar_id": profile_data.get("avatar_id", 0),
		"class": profile_data.get("class", ""),
		"description": profile_data.get("description", ""),
		"lobby_id": lobby_id  # Critical for per-lobby profiles
	}

	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.SaveProfile,
		"user_id": user_id,
		"lobby_id": lobby_id,
		"profile": data
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("💾 Saving profile for user:%s lobby:%s" % [user_id, lobby_id])

func load_profile(user_id: int, lobby_id: String):
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.LoadProfile,
		"user_id": user_id,
		"lobby_id": lobby_id
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("📥 Loading profile for user:%s lobby:%s" % [user_id, lobby_id])


func request_profile_for_user(user_id: int, lobby_id: String):
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.LoadProfile,
		"user_id": user_id,
		"lobby_id": lobby_id
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("📥 Requested profile for user:%s in lobby:%s" % [user_id, lobby_id])

func request_user_profiles(user_id: int):
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.GetAllProfiles,
		"user_id": user_id
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("📚 Requesting all profiles for user:%s" % user_id)

func request_inventory(user_id: int, lobby_id: String):
	var message = {
		"peer": id,
		"orgPeer": id,
		"message": Message.Message.LoadInventory,
		"user_id": user_id,
		"lobby_id": lobby_id
	}
	print("📦 Запрос инвентаря с user_id: %s, lobby_id: %s" % [str(user_id), lobby_id])
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
