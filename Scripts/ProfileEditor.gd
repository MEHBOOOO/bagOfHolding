extends Control

@onready var avatar_button = $VBoxContainer/AvatarButton
@onready var class_input = $VBoxContainer/HBoxContainer/ClassInput
@onready var description_input = $VBoxContainer/HBoxContainer2/DescriptionInput
@onready var avatar_popup = $AvatarPopup
@onready var avatar_grid = $AvatarPopup/AvatarGrid
@onready var save_button = $VBoxContainer/HBoxContainer3/SaveButton
@onready var back_button = $VBoxContainer/HBoxContainer3/BackButton

var selected_avatar_index := 0
var user_id := 0

func _ready():
	user_id = NetworkManager.current_user_id

	avatar_button.pressed.connect(_on_avatar_pressed)
	save_button.pressed.connect(_on_save_pressed)
	back_button.pressed.connect(_on_back_pressed)

	for i in avatar_grid.get_child_count():
		var btn := avatar_grid.get_child(i)
		btn.pressed.connect(_on_avatar_selected.bind(i, btn))

	_load_profile()

func _on_avatar_pressed():
	avatar_popup.popup_centered()

func _on_avatar_selected(index: int, button: TextureButton):
	selected_avatar_index = index
	avatar_button.texture_normal = button.texture_normal
	avatar_popup.hide()

func _on_save_pressed():
	var data = {
		"avatar_id": selected_avatar_index,
		"class": class_input.text,
		"description": description_input.text
	}

	# создаём папку, если нет
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("user://profiles"):
		dir.make_dir("user://profiles")

	var path = "user://profiles/%s_profile.json" % user_id
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	print("✅ Профиль сохранён для пользователя ID:", user_id)

func _load_profile():
	var path = "user://profiles/%s_profile.json" % user_id
	if not FileAccess.file_exists(path):
		print("ℹ️ Профиль не найден. Новый пользователь.")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data:
		class_input.text = data.get("class", "")
		description_input.text = data.get("description", "")
		selected_avatar_index = data.get("avatar_id", 0)

		if selected_avatar_index < avatar_grid.get_child_count():
			var avatar_btn = avatar_grid.get_child(selected_avatar_index)
			if avatar_btn:
				avatar_button.texture_normal = avatar_btn.texture_normal

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
