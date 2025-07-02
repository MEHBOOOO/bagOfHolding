extends Control

@onready var lobby_input = $Lobby  
@onready var lobbyname: LineEdit = $lobbyname
@onready var error_dialog = $ErrorDialog 
@onready var error_label = $ErrorDialog.get_node("Label")

func _ready():
	# Настройка Label для диалога
	error_label.add_theme_font_size_override("font_size", 50)
	error_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Connect to NetworkManager signals
	NetworkManager.lobby_join_success.connect(_on_lobby_join_success)
	NetworkManager.lobby_created_suc.connect(_on_lobby_created)
	NetworkManager.lobby_join_failed.connect(_on_lobby_join_failed)
	NetworkManager.already_in_lobby.connect(_on_already_in_lobby)

func show_error(message: String):
	error_dialog.dialog_text = ""   # Очищаем стандартный текст
	error_label.text = message       # Устанавливаем наш текст
	error_dialog.popup_centered()

func _on_lobby_join_success(reason: String):
	show_error("Successfully joined lobby!")
	# Optionally change scene after successful join
	# get_tree().change_scene_to_file("res://Scenes/LobbyScene.tscn")

func _on_lobby_created(reason: String):
	show_error("Комната создана!")

func _on_lobby_join_failed(reason: String):
	show_error("Failed to join lobby: " + reason)

func _on_already_in_lobby():
	show_error("You're already in this lobby!")

func _on_join_lobby_button_down() -> void:
	var lobby_name = $Lobby.text.strip_edges()
	if lobby_name == "":
		show_error("Введите ID комнаты")
		return
	join_lobby(lobby_name)

func join_lobby(lobby_name: String):
	var message = {
		"message": Message.Message.lobby,
		"name": "", 
		"lobbyValue": lobby_name,
		"orgPeer": int(NetworkManager.id),
		"user_id": GameManager.current_user_id
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())


func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
	pass # Replace with function body.


func _on_create_button_down() -> void:
	var lobby_name = $Lobby.text.strip_edges()
	if lobbyname.text == "":
		show_error("Придумайте название комнаты")
		return
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
