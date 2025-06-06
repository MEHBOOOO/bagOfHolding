extends Node
signal login_requested(email, password)
signal create_user_requested(email, username, password)
signal login_failed(message)
signal player_info_received(info)
signal lobby_join_successful(lobby_info)
signal lobby_join_failed(reason)

var peer = WebSocketMultiplayerPeer.new()
var id = 0
var rtcPeer : WebRTCMultiplayerPeer = WebRTCMultiplayerPeer.new()
var hostId :int
var lobbyValue = ""
var lobbyInfo = {}

func _ready():
	connectToServer("")
	multiplayer.connected_to_server.connect(RTCServerConnected)
	multiplayer.peer_connected.connect(RTCPeerConnected)
	multiplayer.peer_disconnected.connect(RTCPeerDisconnected)
	login_requested.connect(_on_login_requested)
	create_user_requested.connect(_on_create_user_requested)
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

func RTCServerConnected():
	print("RTC server connected")

func RTCPeerConnected(id):
	print("rtc peer connected " + str(id))
	
func RTCPeerDisconnected(id):
	print("rtc peer disconnected " + str(id))



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	peer.poll()
	if peer.get_available_packet_count() > 0:
		var packet = peer.get_packet()
		if packet != null:
			var dataString = packet.get_string_from_utf8()
			var data = JSON.parse_string(dataString)
			
			print(data)
			
			if data.message == Message.Message.id:
				id = data.id
				
				connected(id)
				
			if data.message == Message.Message.userConnected:
				#GameManager.Players[data.id] = data.player
				createPeer(data.id)
				
			if data.message == Message.Message.lobby:
				GameManager.Players = JSON.parse_string(data.players)
				hostId = data.host
				lobbyValue = data.lobbyValue
				
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
				get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
				
			if data.message == Message.Message.failedToLogin:
				login_failed.emit(data.text) 
	pass

func connected(id):
	rtcPeer.create_mesh(id)
	multiplayer.multiplayer_peer = rtcPeer

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
		"lobbyValue" : $Lobby.text
	}
	peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass # Replace with function body.
