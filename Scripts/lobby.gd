extends Control

@onready var lobby_input = $LobbyInput  # Replace with your actual node name



func _on_join_lobby_button_down() -> void:
	var lobby_name = $Lobby.text.strip_edges()
	if lobby_name == "":
		return
	join_lobby(lobby_name)

func join_lobby(lobby_name: String):
	
	
	var message = {
		"id": NetworkManager.id,
		"message": Message.Message.lobby,
		"name": "",
		"lobbyValue": lobby_name
	}
	
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("Sent lobby join request: ", message)


func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
	pass # Replace with function body.


func _on_create_button_down() -> void:
	var lobby_name = $Lobby.text.strip_edges()
	var message = {
		"id": NetworkManager.id,
		"message": Message.Message.lobby,
		"name": "",
		"orgPeer": NetworkManager.id,
		"lobbyValue": lobby_name
	}
	
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass 
