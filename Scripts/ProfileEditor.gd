extends Control

@onready var avatar_button = $VBoxContainer/AvatarButton
@onready var class_input = $VBoxContainer/HBoxContainer/ClassInput
@onready var description_input = $VBoxContainer/HBoxContainer2/DescriptionInput
@onready var avatar_popup = $AvatarPopup
@onready var avatar_grid = $AvatarPopup/ScrollContainer/AvatarGrid
@onready var save_button = $VBoxContainer/HBoxContainer3/SaveButton
@onready var back_button = $VBoxContainer/HBoxContainer3/BackButton
@onready var name_input = $VBoxContainer/HBoxContainer_Name/NameInput

var selected_avatar_index := 0
var user_id := 0
var lobby_id := ""

func _ready():
	user_id = NetworkManager.current_user_id
	lobby_id = GameManager.current_lobby_id

	avatar_button.pressed.connect(_on_avatar_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)

	for i in avatar_grid.get_child_count():
		var btn := avatar_grid.get_child(i)
		btn.pressed.connect(_on_avatar_selected.bind(i, btn))

	# 🔗 Подключаем сигнал
	if not NetworkManager.profile_data_received.is_connected(_on_profile_loaded):
		NetworkManager.profile_data_received.connect(_on_profile_loaded)

	# 📥 Запрашиваем профиль асинхронно
	NetworkManager.request_profile_for_user(user_id, lobby_id)

func _on_avatar_pressed():
	avatar_popup.popup_centered()

func _on_avatar_selected(index: int, button: TextureButton):
	selected_avatar_index = index
	avatar_button.texture_normal = button.texture_normal
	avatar_popup.hide()

func _on_save_pressed():
	var data = {
		"name": name_input.text,
		"avatar_id": selected_avatar_index,
		"class": class_input.text,
		"description": description_input.text,
		"lobby_id": lobby_id
	}

	NetworkManager.save_profile(user_id, lobby_id, data)
	print("✅ Профиль сохранён для пользователя ID:", user_id)

#func _load_profile():
	##var profile = NetworkManager.request_profile_for_user(user_id, lobby_id)
	##name_input.text = profile.get("name", "")
#
	#if profile:
		#class_input.text = profile.get("class", "")
		#description_input.text = profile.get("description", "")
		#selected_avatar_index = profile.get("avatar_id", 0)
#
		#if selected_avatar_index < avatar_grid.get_child_count():
			#var avatar_btn = avatar_grid.get_child(selected_avatar_index)
			#if avatar_btn:
				#avatar_button.texture_normal = avatar_btn.texture_normal

func _on_profile_loaded(profile_data: Dictionary):
	if profile_data.get("user_id") != user_id:
		return

	name_input.text = profile_data.get("name", "")
	class_input.text = profile_data.get("class", "")
	description_input.text = profile_data.get("description", "")
	selected_avatar_index = profile_data.get("avatar_id", 0)

	if selected_avatar_index < avatar_grid.get_child_count():
		var avatar_btn = avatar_grid.get_child(selected_avatar_index)
		if avatar_btn:
			avatar_button.texture_normal = avatar_btn.texture_normal

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/LobbyInter.tscn")
