extends Control

# Reference to your lobby input field
@onready var lobby_input = $LobbyInput  # Replace with your actual node name



func _on_join_lobby_button_down() -> void:
	# Get the lobby code from input field
	var lobby_code = $Lobby.text.strip_edges()
	
	# Call the join_lobby function directly
	join_lobby(lobby_code)

# This is the function that sends the lobby join message
func join_lobby(lobby_code: String):
	# Make sure we have an ID first (if we're connected)
	
	# Create the message exactly as you specified
	var message = {
		"id": NetworkManager.id,
		"message": Message.Message.lobby,
		"name": "",
		"lobbyValue": lobby_code
	}
	
	# Send the message through the peer
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	print("Sent lobby join request: ", message)
