extends Node2D

@onready var participants_container = $ScrollContainer/VBoxContainer
@onready var profile_popup = $ProfilePopup
@onready var profile_name_label = $ProfilePopup/VBoxContainer/PlayerNameLabel
@onready var profile_class_label = $ProfilePopup/VBoxContainer/PlayerClassLabel
@onready var profile_description_label = $ProfilePopup/VBoxContainer/PlayerDescriptionLabel
@onready var profile_avatar_button = $ProfilePopup/VBoxContainer/AvatarButton
@onready var profile_close_button = $ProfilePopup/VBoxContainer/CloseButton

@onready var lobby_id_label = $LobbyId/LobbyIdLabel
@onready var copy_lobby_id_button = $LobbyId/CopyLobbyButton

var lobby_id: String = GameManager.current_lobby_id
var refresh_timer: Timer
var selected_user_id: int = -1 
var avatar_textures = [
	preload("res://Images/бард.png"),
	preload("res://Images/войн.png"),
	preload("res://Images/паладин.png")
	# Добавь другие аватары, если есть
]

func _ready():
	if not participants_container:
		push_error("ParticipantsContainer not found!")
		return
	lobby_id_label.text = "Lobby ID: " + GameManager.current_lobby_id

	profile_close_button.pressed.connect(func(): profile_popup.hide())
	
	copy_lobby_id_button.pressed.connect(func():
		DisplayServer.clipboard_set(GameManager.current_lobby_id)
		print("📋 Lobby ID скопирован:", GameManager.current_lobby_id)
	)
	lobby_id = GameManager.current_lobby_id
	setup_participants_container()

	NetworkManager.participant_update_received.connect(_on_participant_update_received)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.profile_data_received.connect(_on_profile_data_received)

	refresh_timer = Timer.new()
	add_child(refresh_timer)
	refresh_timer.timeout.connect(request_participants)
	refresh_timer.wait_time = 2.0
	refresh_timer.autostart = true
	refresh_timer.one_shot = false
	refresh_timer.start()

	request_participants()

func setup_participants_container():
	for child in participants_container.get_children():
		child.queue_free()

	var title = Label.new()
	title.name = "TitleLabel"
	title.text = "Loading participants..."
	title.add_theme_font_size_override("font_size", 18)
	participants_container.add_child(title)

func _on_player_disconnected():
	request_participants()

func request_participants():
	var message = {
		"message": Message.Message.requestParticipants,
		"lobby_id": lobby_id,
		"orgPeer": NetworkManager.id
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_participant_update_received(data: Dictionary):
	if data.get("lobby_id", "") == lobby_id:
		update_participants_display(data.get("participants", []), data.get("host_id", -1))

func update_participants_display(participants: Array, host_id: int):
	for i in range(participants_container.get_child_count() - 1, 0, -1):
		var child = participants_container.get_child(i)
		if child.name != "TitleLabel":
			child.queue_free()

	var title = participants_container.get_node("TitleLabel")
	title.text = "Participants (%d)" % participants.size()

	for participant in participants:
		if participant.get("user_id", -1) == host_id:
			add_participant_card(participant, true)
	for participant in participants:
		if participant.get("user_id", -1) != host_id:
			add_participant_card(participant, false)

func add_participant_card(participant: Dictionary, is_host: bool):
	var button = Button.new()
	button.text = participant.get("name", "Unknown")
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(0, 40)

	if participant.get("is_host") == 1:
		button.text += " 👑"
		button.add_theme_color_override("font_color", Color.GOLD)

	var user_id = int(participant.get("id", -1))
	var name = participant.get("name", "Unknown")

	button.pressed.connect(_on_participant_selected.bind(user_id, name))
	participants_container.add_child(button)

func _on_participant_selected(user_id: int, name: String) -> void:
	print("▶️ Выбран участник: %s (ID: %d)" % [name, user_id])
	selected_user_id = user_id
	
	NetworkManager.request_profile_for_user(user_id, GameManager.current_lobby_id)

func _on_profile_data_received(data: Dictionary):
	# Extract the user_id from the response
	var received_user_id = int(data.get("user_id", -1))
	
	if received_user_id != selected_user_id:
		return
	
	var profile_data = data.get("profile", {})
	
	print("✅ Профиль получен: ", profile_data)
	
	var avatar_id = profile_data.get("avatar_id", 0)
	if avatar_id >= 0 and avatar_id < avatar_textures.size():
		profile_avatar_button.texture_normal = avatar_textures[avatar_id]
	else:
		profile_avatar_button.texture_normal = null
	
	profile_name_label.text = "Имя: %s" % profile_data.get("name", "Unknown")
	profile_class_label.text = "Класс: %s" % profile_data.get("class", "Не указан")
	profile_description_label.text = "Описание: %s" % profile_data.get("description", "–")
	
	profile_popup.popup_centered()


func _on_create_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/create.tscn")

func _on_inventory_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/inventory.tscn")

func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobbies.tscn")

func _on_profile_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/PlayerProfile.tscn")
	pass # Replace with function body.
