extends Control

@onready var participants_container = $ScrollContainer2/VBoxContainer
@onready var lobby_container: VBoxContainer = $ScrollContainer/VBoxContainer/VBoxContainer2
@onready var scroll_container: ScrollContainer = $ScrollContainer

# Profile popup
@onready var player_popup = $PlayerPopup
@onready var player_name_label = $PlayerPopup/VBoxContainer/PlayerNameLabel
@onready var view_profile_button = $PlayerPopup/VBoxContainer/ViewProfileButton
@onready var kick_button = $PlayerPopup/VBoxContainer/KickButton

var selected_player_id: int = -1
var selected_player_name: String = ""
var is_admin: bool = false

func _ready():
	setup_connections()
	view_profile_button.pressed.connect(_on_view_profile_pressed)
	kick_button.pressed.connect(_on_kick_pressed)

	if NetworkManager.peer.get_connection_status() == WebSocketMultiplayerPeer.CONNECTION_CONNECTED:
		_on_connected()
	else:
		multiplayer.connected_to_server.connect(_on_connected)

func _on_connected():
	print("🟢 Подключение завершено — отправляем запросы")
	request_participants()
	NetworkManager.request_user_lobbies()

func request_participants():
	var message = {
		"message": Message.Message.requestParticipants,
		"lobby_id": GameManager.current_lobby_id,
		"orgPeer": NetworkManager.id
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_message_received(data: Dictionary):
	if data.message == Message.Message.participantsData:
		update_participants_display(data)

func update_participants_display(data: Dictionary):
	for child in participants_container.get_children():
		child.queue_free()

	var host_id = data.get("host_id", -1)
	is_admin = host_id == NetworkManager.current_user_id

	for participant in data.participants:
		var is_host = participant.get("user_id") == host_id
		add_participant_button(participant, is_host)

func add_participant_button(participant: Dictionary, is_host: bool):
	var button = Button.new()

	var player_id = int(participant.get("user_id", -1))
	var name = str(participant.get("name", "Unknown"))

	button.text = name + (" 👑 Host" if is_host else "")
	button.size_flags_horizontal = SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE

	if is_host:
		button.add_theme_color_override("font_color", Color.GOLD)

	button.pressed.connect(_on_participant_selected.bind(player_id, name))
	participants_container.add_child(button)

func _on_participant_selected(user_id: int, name: String):
	selected_player_id = user_id
	selected_player_name = name
	player_name_label.text = name
	player_popup.popup_centered()

func _on_view_profile_pressed():
	if selected_player_id == -1:
		return
	NetworkManager.request_inventory_for_user(selected_player_id)
	player_popup.hide()

func _on_kick_pressed():
	if is_admin and selected_player_id != -1:
		var msg = {
			"message": Message.Message.kickUser,
			"target_user_id": selected_player_id,
			"orgPeer": NetworkManager.id,
			"Lobby": GameManager.current_lobby_id
		}
		NetworkManager.peer.put_packet(JSON.stringify(msg).to_utf8_buffer())
		print("👢 Кикнут:", selected_player_name)
	player_popup.hide()

func setup_connections():
	if NetworkManager.lobbies_received.is_connected(_on_lobbies_received):
		NetworkManager.lobbies_received.disconnect(_on_lobbies_received)
	NetworkManager.lobbies_received.connect(_on_lobbies_received)

func _on_lobbies_received(lobbies: Array):
	$ScrollContainer/VBoxContainer/Label.text = "Received %d groups".format([lobbies.size()])
	for child in lobby_container.get_children():
		child.queue_free()

	if lobbies.is_empty():
		var empty = Label.new()
		empty.text = "You're not in any groups yet"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lobby_container.add_child(empty)
		return

	for lobby in lobbies:
		add_lobby_card(lobby)

func add_lobby_card(lobby: Dictionary):
	# Skip if lobby doesn't have a name
	if not lobby.get("lobby_name"):
		return
		
	# Create main card container
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 60)  # Minimum height
	
	# Apply card background texture
	var card_style = StyleBoxTexture.new()
	card_style.texture = preload("res://Images/button1.png")
	card_style.expand_margin_left = 5  # Increased left margin
	card_style.expand_margin_right = 20  # Increased right margin
	card_style.expand_margin_top = 10
	card_style.expand_margin_bottom = 10
	card.add_theme_stylebox_override("panel", card_style)
	
	# Create horizontal container for name and button
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(hbox)
	
	# Create lobby name label (left side)
	var name_label = Label.new()
	name_label.text = lobby.get("lobby_name", "Unnamed Group")
	name_label.add_theme_font_size_override("font_size", 30)  # Reduced font size
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color.BLACK)
	
	# Add padding to label
	var label_style = StyleBoxFlat.new()
	label_style.bg_color = Color.TRANSPARENT
	label_style.content_margin_left = 20  # Push text right
	name_label.add_theme_stylebox_override("normal", label_style)
	
	hbox.add_child(name_label)
	
	# Create OPEN button (right side)
	var open_btn = Button.new()
	open_btn.text = "OPEN"
	open_btn.custom_minimum_size = Vector2(120, 40)
	open_btn.size_flags_horizontal = Control.SIZE_SHRINK_END
	open_btn.pressed.connect(_on_open_group.bind(lobby["lobby_id"]))
	
	# Apply button styling
	var btn_style = StyleBoxTexture.new()
	btn_style.texture = preload("res://Images/button1.png")
	btn_style.expand_margin_left = 10
	btn_style.expand_margin_right = 20  # Increased right margin for button
	btn_style.expand_margin_top = 5
	btn_style.expand_margin_bottom = 5
	
	open_btn.add_theme_stylebox_override("normal", btn_style)
	open_btn.add_theme_stylebox_override("hover", btn_style)
	open_btn.add_theme_stylebox_override("pressed", btn_style)
	
	# Button text styling - black text
	open_btn.add_theme_font_size_override("font_size", 18)
	open_btn.add_theme_color_override("font_color", Color.BLACK)
	open_btn.add_theme_color_override("font_hover_color", Color(0.2, 0.2, 0.2))
	open_btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.1, 0.1))
	
	var btn_text_style = StyleBoxFlat.new()
	btn_text_style.bg_color = Color.TRANSPARENT
	btn_text_style.content_margin_left = 10  # Push button text right
	open_btn.add_theme_stylebox_override("normal", btn_text_style)
	
	hbox.add_child(open_btn)
	
	lobby_container.add_child(card)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 5)
	lobby_container.add_child(spacer)

func _on_open_group(lobby_id: String):
	print("Opening Lobby: ", lobby_id)
	GameManager.current_lobby_id = lobby_id
	get_tree().change_scene_to_file("res://Scenes/LobbyInter.tscn")

func _on_button_button_down():
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")

func _on_button_2_button_down():
	NetworkManager.request_user_lobbies()
