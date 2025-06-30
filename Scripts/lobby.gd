extends Control

@onready var lobby_input = $Lobby  

@onready var lobbyname: LineEdit = $lobbyname


func _on_join_lobby_button_down() -> void:
	var lobby_name = $Lobby.text.strip_edges()
	if lobby_name == "":
		return
	join_lobby(lobby_name)

func join_lobby(lobby_name: String):
	var message = {
		"message": Message.Message.lobby,
		"name": "", 
		"lobbyValue": lobby_name,
		"orgPeer": int(NetworkManager.id),
		"user_id": GameManager.current_user_id  # Add this
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
	pass # Replace with function body.


func _on_create_button_down() -> void:
	var lobby_name = $Lobby.text.strip_edges()
	var message = {
		"id": NetworkManager.id,
		"message": Message.Message.lobby,
		"name": lobbyname.text,
		"orgPeer": NetworkManager.id,
		"lobbyValue": lobby_name
	}
	lobbyname.text = ""
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	pass 
