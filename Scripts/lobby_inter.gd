extends Node2D

@onready var participants_container = $ScrollContainer/VBoxContainer
@onready var profile_popup = $ProfilePopup
@onready var profile_name_label = $ProfilePopup/VBoxContainer/PlayerNameLabel
@onready var profile_class_label = $ProfilePopup/VBoxContainer/PlayerClassLabel
@onready var profile_description_label = $ProfilePopup/VBoxContainer/PlayerDescriptionLabel
@onready var profile_avatar_button = $ProfilePopup/VBoxContainer/AvatarButton
@onready var profile_close_button = $ProfilePopup/VBoxContainer/CloseButton
@onready var inventory_container = $ProfilePopup/VBoxContainer/InventoryScroll/InventoryContainer
@onready var admin_container = $ProfilePopup/VBoxContainer/AdminContainer
@onready var kick_button = $ProfilePopup/VBoxContainer/AdminContainer/KickButton
@onready var lobby_id_label = $LobbyId/LobbyIdLabel
@onready var copy_lobby_id_button = $LobbyId/CopyLobbyButton
@onready var player_name_label = $ProfilePopup/VBoxContainer/PlayerNameLabel
#@onready var avatar_grid = $AvatarPopup/ScrollContainer/AvatarGrid

var pending_profile_data: Dictionary = {}
var pending_inventory_data: Array = []
var waiting_for_inventory: bool = false
var lobby_id: String = GameManager.current_lobby_id
var refresh_timer: Timer
var selected_user_id: int = -1 
var host_id: int = -1  # Track the lobby host ID
var current_user_id: int = NetworkManager.current_user_id  # Current viewer's ID
var avatar_textures = [
	preload("res://Images/бард.png"),
	preload("res://Images/варвар.png"),
	preload("res://Images/войн.png"),
	preload("res://Images/волшебник.png"),
	preload("res://Images/друид.png"),
	preload("res://Images/жрец.png"),
	preload("res://Images/изобретатель.png"),
	preload("res://Images/колдун.png"),
	preload("res://Images/монах.png"),
	preload("res://Images/паладин.png"),
	preload("res://Images/плут.png"),
	preload("res://Images/следопыт.png"),
	preload("res://Images/чародей.png")
]



func _ready():
	if not participants_container:
		push_error("ParticipantsContainer not found!")
		return
	lobby_id_label.text = "Lobby ID: " + GameManager.current_lobby_id

	profile_close_button.pressed.connect(func(): profile_popup.hide())
	kick_button.pressed.connect(_on_kick_button_pressed)
	
	copy_lobby_id_button.pressed.connect(func():
		DisplayServer.clipboard_set(GameManager.current_lobby_id)
		print("📋 Lobby ID скопирован:", GameManager.current_lobby_id)
	)
	var user_id = NetworkManager.current_user_id
	var lobby_id = GameManager.current_lobby_id
	
	# Подключаемся к сигналу
	if not NetworkManager.profile_data_received.is_connected(_on_profile_loaded):
		NetworkManager.profile_data_received.connect(_on_profile_loaded)
	
	# Запрашиваем заново данные профиля
	NetworkManager.request_profile_for_user(user_id, lobby_id)
	lobby_id = GameManager.current_lobby_id
	setup_participants_container()

	NetworkManager.participant_update_received.connect(_on_participant_update_received)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.profile_data_received.connect(_on_profile_data_received)
	NetworkManager.inventory_data_received.connect(_on_inventory_data_received)
	

	refresh_timer = Timer.new()
	add_child(refresh_timer)
	refresh_timer.timeout.connect(request_participants)
	refresh_timer.wait_time = 2.0
	refresh_timer.autostart = true
	refresh_timer.one_shot = false
	refresh_timer.start()

	request_participants()
func _on_profile_loaded(profile_data: Dictionary):
	if profile_data.get("user_id") != NetworkManager.current_user_id:
		return
	
	# Обновить UI — имя, аватар и т.д.
	profile_name_label.text = "Имя: %s" % profile_data.get("name", "Игрок")
	#$AvatarPopup/ScrollContainer/AvatarGrid.texture = get_avatar_texture(profile_data.get("avatar_id", 0))

func get_avatar_texture(avatar_index: int) -> Texture:
	var avatar_grid = preload("res://Scenes/PlayerProfile.tscn").instantiate().get_node("AvatarPopup/ScrollContainer/AvatarGrid")
	if avatar_index >= 0 and avatar_index < avatar_grid.get_child_count():
		var btn := avatar_grid.get_child(avatar_index)
		return btn.texture_normal
	else:
		return null

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
		host_id = data.get("host_id", -1)  # Store host ID
		update_participants_display(data.get("participants", []), host_id)

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


func _on_delete_item_pressed(item_id: int) -> void:
	print("🗑️ Requesting deletion of item: ", item_id)
	var message = {
		"message": Message.Message.deleteItem, 
		"item_id": item_id,
		"user_id": selected_user_id,
		"lobby_id": GameManager.current_lobby_id,
		"orgPeer": NetworkManager.id
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	
	# Refresh inventory after deletion
	var timer = Timer.new()
	timer.wait_time = 0.5  # Short delay for server processing
	timer.one_shot = true
	timer.timeout.connect(func():
		NetworkManager.request_inventory(selected_user_id, GameManager.current_lobby_id)
		timer.queue_free()
	)
	add_child(timer)
	timer.start()


func _on_participant_selected(user_id: int, name: String) -> void:
	print("▶️ Выбран участник: %s (ID: %d)" % [name, user_id])
	selected_user_id = user_id
	inventory_container.get_children().map(func(c): c.queue_free())
	admin_container.visible = false
	
	NetworkManager.request_profile_for_user(user_id, GameManager.current_lobby_id)
	NetworkManager.request_inventory(user_id, GameManager.current_lobby_id)


func _on_profile_data_received(user_id: int, profile_data: Dictionary):
	if user_id != selected_user_id: return
	
	# Update profile UI
	profile_name_label.text = "Имя: %s" % profile_data.get("name", "Unknown")
	profile_class_label.text = "Класс: %s" % profile_data.get("class", "Не указан")
	profile_description_label.text = "Описание: %s" % profile_data.get("description", "–")
	
	# Set avatar
	var avatar_id = profile_data.get("avatar_id", 0)
	if avatar_id >= 0 and avatar_id < avatar_textures.size():
		profile_avatar_button.texture_normal = avatar_textures[avatar_id]
	
	# Show profile immediately
	profile_popup.popup_centered()

func _on_inventory_data_received(user_id: int, items: Array):
	if user_id != selected_user_id: return
	
	# Update inventory UI
	for child in inventory_container.get_children():
		child.queue_free()
	
	var title = Label.new()
	title.text = "Инвентарь:"
	title.add_theme_font_size_override("font_size", 16)
	inventory_container.add_child(title)
	var is_admin = (current_user_id == host_id)
	var not_viewing_self = (selected_user_id != current_user_id)
	var not_viewing_host = (selected_user_id != host_id)
	admin_container.visible = is_admin && not_viewing_self && not_viewing_host
	if is_admin:
		if items.size() == 0:
			var empty_label = Label.new()
			empty_label.text = "Пусто"
			inventory_container.add_child(empty_label)
		else:
			for item in items:
				var hbox = HBoxContainer.new()
				var item_label = Label.new()
				item_label.text = "• " + item.get("name", "Безымянный предмет")
				if item.has("description") and not item["description"].is_empty():# ВОТ ЭТО Я ДОБАВИЛ
					item_label.text += " - " + item["description"] # ВОТ ЭТО Я ДОБАВИЛ
				hbox.add_child(item_label)
				
				
				var delete_button = Button.new()
				delete_button.text = "Удалить"
				delete_button.connect("pressed", _on_delete_item_pressed.bind(item["id"]))
				hbox.add_child(delete_button)
				
				inventory_container.add_child(hbox)
	


func _show_profile_with_inventory() -> void:
	# Only admins should see the inventory
	var is_admin = (current_user_id == host_id)
	
	# Set profile information
	#var profile_data = pending_profile_data.get("profile", {})
	var profile_data = pending_profile_data  # ❗ Уже сам профиль
	profile_name_label.text = "Имя: %s" % profile_data.get("name", "Unknown")
	profile_class_label.text = "Класс: %s" % profile_data.get("class", "Не указан")
	profile_description_label.text = "Описание: %s" % profile_data.get("description", "–")
	
	# Set avatar
	var avatar_id = profile_data.get("avatar_id", 0)
	if avatar_id >= 0 and avatar_id < avatar_textures.size():
		profile_avatar_button.texture_normal = avatar_textures[avatar_id]
	else:
		profile_avatar_button.texture_normal = null
	
	var not_viewing_self = (selected_user_id != current_user_id)
	var not_viewing_host = (selected_user_id != host_id)
	admin_container.visible = is_admin && not_viewing_self && not_viewing_host
	
	if is_admin:
		for child in inventory_container.get_children():
			child.queue_free()
		
		var title = Label.new()
		title.text = "Инвентарь:"
		title.add_theme_font_size_override("font_size", 16)
		inventory_container.add_child(title)
		
		if pending_inventory_data.size() == 0:
			var empty_label = Label.new()
			empty_label.text = "Пусто"
			empty_label.add_theme_color_override("font_color", Color.GRAY)
			inventory_container.add_child(empty_label)
		else:
			for item in pending_inventory_data:
				var hbox = HBoxContainer.new()
				hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				
				var item_label = Label.new()
				item_label.text = "• " + item.get("name", "Безымянный предмет")
				
				if item.has("description") && !item["description"].is_empty():
					item_label.text += " - " + item["description"]
				
				hbox.add_child(item_label)
				
				# Add delete button
				var delete_button = Button.new()
				delete_button.text = "Удалить"
				delete_button.connect("pressed", _on_delete_item_pressed.bind(item["id"]))
				hbox.add_child(delete_button)
				
				inventory_container.add_child(hbox)
	
	profile_popup.popup_centered()
	
	pending_profile_data = {}
	pending_inventory_data = []

func _on_kick_button_pressed():
	print("🚫 Выгнать пользователя ID:", selected_user_id)
	var message = {
		"message": Message.Message.kickParticipant, 
		"user_id": selected_user_id,
		"lobby_id": GameManager.current_lobby_id,
		"orgPeer": NetworkManager.id
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())
	profile_popup.hide()
	request_participants() 

func _on_create_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/create.tscn")

func _on_inventory_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/inventory.tscn")

func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobbies.tscn")

func _on_profile_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/PlayerProfile.tscn")
	pass # Replace with function body.
