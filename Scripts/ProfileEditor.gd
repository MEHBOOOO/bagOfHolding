extends Control

@onready var avatar_button = $VBoxContainer/AvatarButton
@onready var class_input = $VBoxContainer/HBoxContainer/ClassInput
@onready var description_input = $VBoxContainer/HBoxContainer2/DescriptionInput
@onready var avatar_popup = $AvatarPopup
@onready var avatar_grid = $AvatarPopup/ScrollContainer/AvatarGrid
@onready var save_button = $VBoxContainer/HBoxContainer3/SaveButton
@onready var back_button = $VBoxContainer/HBoxContainer3/BackButton
@onready var name_input: LineEdit = $VBoxContainer/HBoxContainer_Name/NameInput

var selected_avatar_index := 0
var user_id := 0
var lobby_id := ""

func _ready():
	user_id = NetworkManager.current_user_id
	lobby_id = GameManager.current_lobby_id

	# Connect UI signals
	avatar_button.pressed.connect(_on_avatar_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect avatar selection buttons
	for i in avatar_grid.get_child_count():
		var btn := avatar_grid.get_child(i) as TextureButton
		btn.pressed.connect(_on_avatar_selected.bind(i))

	# Connect profile data signal
	NetworkManager.profile_data_received.connect(_on_profile_loaded)

	# Request profile (will load asynchronously via signal)
	
	lobby_id = GameManager.current_lobby_id  # Ensure this is set correctly
	NetworkManager.request_profile_for_user(user_id, lobby_id)
	
	# Set default avatar immediately
	_update_avatar_display()

func _update_avatar_display():
	# Always ensure we have a valid avatar displayed
	if selected_avatar_index < avatar_grid.get_child_count():
		var avatar_btn = avatar_grid.get_child(selected_avatar_index) as TextureButton
		if avatar_btn and avatar_btn.texture_normal:
			avatar_button.texture_normal = avatar_btn.texture_normal

func _on_avatar_pressed():
	avatar_popup.popup_centered()

func _on_avatar_selected(index: int):
	selected_avatar_index = index
	_update_avatar_display()
	avatar_popup.hide()

func _on_save_pressed():
	var data = {
		"name": name_input.text,
		"avatar_id": selected_avatar_index,  # Use avatar_id instead of index
		"class": class_input.text,
		"description": description_input.text
	}

	# Save with current lobby_id
	NetworkManager.save_profile(user_id, lobby_id, data)
	print("💾 Saving profile for lobby: ", lobby_id)

func _on_profile_loaded(received_user_id: int, profile_data: Dictionary) -> void:
	if received_user_id != user_id:
		return
	
	print("📥 Received profile data: ", profile_data)
	
	name_input.text = profile_data.get("name", "Игрок %d" % user_id)
	class_input.text = profile_data.get("class", "")
	description_input.text = profile_data.get("description", "")
	selected_avatar_index = profile_data.get("avatar_id", 0)
	
	selected_avatar_index = clampi(selected_avatar_index, 0, avatar_grid.get_child_count() - 1)
	_update_avatar_display()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/LobbyInter.tscn")
