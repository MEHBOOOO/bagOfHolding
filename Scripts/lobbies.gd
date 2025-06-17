extends Control

var debug_label: Label
@onready var participants_container = $ScrollContainer2/VBoxContainer
@onready var lobby_container: VBoxContainer = $ScrollContainer/VBoxContainer/VBoxContainer2
@onready var scroll_container: ScrollContainer = $ScrollContainer


func _ready():
	setup_connections()
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
	# Clear existing participants
	for child in participants_container.get_children():
		child.queue_free()
	
	# Add host first
	var host = null
	for participant in data.participants:
		if participant.user_id == data.host_id:
			host = participant
			break
	
	if host:
		add_participant_card(host, true)
	
	# Add other participants
	for participant in data.participants:
		if participant.user_id != data.host_id:
			add_participant_card(participant, false)

func add_participant_card(participant: Dictionary, is_host: bool):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 40)
	
	var label = Label.new()
	label.text = participant.name
	if is_host:
		label.text += " (Host)"
		label.add_theme_color_override("font_color", Color.GOLD)
	
	card.add_child(label)
	participants_container.add_child(card)


func setup_connections():
	# Clean existing connections
	if NetworkManager.lobbies_received.is_connected(_on_lobbies_received):
		NetworkManager.lobbies_received.disconnect(_on_lobbies_received)
	
	# Connect signal
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
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 60)
	
	var hbox = HBoxContainer.new()
	card.add_child(hbox)
	
	# Group info
	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)
	
	var name_label = Label.new()
	name_label.text = lobby.get("lobby_name", "Unnamed Group")
	name_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(name_label)
	
	var date_label = Label.new()
	date_label.text = "Created: %s" % lobby.get("created_at", "?").replace("T", " ").substr(0, 16)
	date_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(date_label)
	
	var open_btn = Button.new()
	open_btn.text = "OPEN"
	open_btn.pressed.connect(_on_open_group.bind(lobby["lobby_id"]))
	hbox.add_child(open_btn)
	
	lobby_container.add_child(card)
	

func _on_open_group(lobby_id: String):
	print("Opening Lobby: ", lobby_id)

	GameManager.current_lobby_id = lobby_id
	get_tree().change_scene_to_file("res://Scenes/LobbyInter.tscn")
	
func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
	pass # Replace with function body.


func _on_button_2_button_down() -> void:
	NetworkManager.request_user_lobbies()
	pass # Replace with function body.
