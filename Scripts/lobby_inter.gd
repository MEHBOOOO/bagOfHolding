extends Node2D

@onready var participants_container = $ScrollContainer/VBoxContainer
var lobby_id : String = GameManager.current_lobby_id
var refresh_timer : Timer

func _ready():
	if not participants_container:
		push_error("ParticipantsContainer not found!")
		return
	
	lobby_id = GameManager.current_lobby_id
	setup_participants_container()
	
	NetworkManager.participant_update_received.connect(_on_participant_update_received)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	
	refresh_timer = Timer.new()
	add_child(refresh_timer)
	refresh_timer.timeout.connect(request_participants)
	refresh_timer.start(2.0)
	request_participants()

func _on_player_disconnected():
	request_participants()

func setup_participants_container():  # FIXED SPELLING
	for child in participants_container.get_children():
		child.queue_free()
	
	var title = Label.new()
	title.text = "Loading participants..."
	title.name = "TitleLabel"
	title.add_theme_font_size_override("font_size", 18)
	participants_container.add_child(title)

func _on_participant_update_received(data: Dictionary):
	# Check if this update is for our lobby
	if data.get("lobby_id") == lobby_id:
		update_participants_display(data.get("participants", []), data.get("host_id", -1))
func update_participants_display(participants: Array, host_id: int):
	# Clear existing children except title
	for i in range(participants_container.get_child_count() - 1, 0, -1):
		var child = participants_container.get_child(i)
		if child.name != "TitleLabel":
			child.queue_free()
	
	var title = participants_container.get_node("TitleLabel")
	if participants:
		title.text = "Participants (%d)" % participants.size()
	else:
		title.text = "No participants found"
	
	# Add host first
	for participant in participants:
		if participant.get("is_host") == host_id:  # Using .get() is safer
			add_participant_card(participant, true)
	
	# Add other participants
	for participant in participants:
		if participant.get("is_host") != host_id:  # Using .get() is safer
			add_participant_card(participant, false)

func add_participant_card(participant: Dictionary, is_host: bool):
	var card = HBoxContainer.new()
	card.custom_minimum_size = Vector2(0, 30)
	
	var name_label = Label.new()
	name_label.text = participant.get("name", "Unknown")  # Default value if key missing
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(name_label)
	
	if is_host:
		var host_label = Label.new()
		host_label.text = "👑 Host"
		host_label.add_theme_color_override("font_color", Color.GOLD)
		card.add_child(host_label)
	
	participants_container.add_child(card)

func request_participants():
	var message = {
		"message": Message.Message.requestParticipants,
		"lobby_id": lobby_id,
		"orgPeer": NetworkManager.id,
		"requesting_lobby": lobby_id  # Add this to identify which lobby is requesting
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func simulate_participants_data():
	var test_data = {
		"message": Message.Message.participantsData,
		"participants": [
			{"user_id": 1, "name": "Player1"},
			{"user_id": 2, "name": "Player2"},
			{"user_id": 3, "name": "You (Host)"}
		],
		"host_id": 3
	}
	update_participants_display(test_data.participants, test_data.host_id)


func _on_create_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/create.tscn")
	pass # Replace with function body.


func _on_inventory_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/inventory.tscn")
	pass # Replace with function body.


func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobbies.tscn")
	pass # Replace with function body.
