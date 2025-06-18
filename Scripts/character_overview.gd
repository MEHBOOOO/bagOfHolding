extends Control

@onready var character_list = $ScrollContainer/CharacterList
@onready var back_button = $BackButton
@onready var title_label = $TitleLabel

var avatar_textures = [
	preload("res://Images/бард.png"),
	preload("res://Images/войн.png"),
	preload("res://Images/паладин.png")
	# добавь больше, если есть
]
var current_user_id := NetworkManager.current_user_id

func _ready():
	title_label.text = "📜 Ваши персонажи"
	back_button.pressed.connect(_on_back_pressed)
	load_all_profiles()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")  # Замени путь на нужный

func add_character_card(character_data: Dictionary):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.custom_minimum_size = Vector2(0, 80)

	var avatar_id = character_data.get("avatar_id", 0)
	var avatar = TextureRect.new()
	avatar.texture = avatar_textures[avatar_id] if avatar_id < avatar_textures.size() else null
	avatar.custom_minimum_size = Vector2(64, 64)
	avatar.expand = true
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(avatar)

	var label = Label.new()
	label.text = "Имя: %s\nКласс: %s" % [
		character_data.get("name", "Unknown"),
		character_data.get("class", "—")
	]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hbox.add_child(label)

	# Кнопка "Инвентарь"
	var btn = Button.new()
	btn.text = "Инвентарь"
	btn.size_flags_horizontal = Control.SIZE_SHRINK_END

	var user_id = character_data.get("user_id", NetworkManager.current_user_id)
	var lobby_id = character_data.get("lobby_id", "unknown")  # добавь это поле при сохранении профиля!

	btn.pressed.connect(func():
		var inv_scene = load("res://Scenes/InventoryView.tscn").instantiate()
		inv_scene.user_id = user_id
		inv_scene.lobby_id = lobby_id
		get_tree().get_root().add_child(inv_scene)
		get_tree().current_scene.queue_free()
		get_tree().current_scene = inv_scene
	)
	hbox.add_child(btn)

	character_list.add_child(hbox)

func load_all_profiles():
	for child in character_list.get_children():
		child.queue_free()
	
	var current_user_id := NetworkManager.current_user_id
	var seen_lobbies := {}

	var dir = DirAccess.open("user://profiles")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with("_profile.json"):
				var split = file_name.split("_")
				if split.size() >= 3:
					var file_user_id = int(split[0])
					var lobby_id = split[1]

					if file_user_id == current_user_id and not seen_lobbies.has(lobby_id):
						seen_lobbies[lobby_id] = true  # помечаем, что уже загрузили профиль для этого лобби

						var full_path = "user://profiles/%s" % file_name
						var file = FileAccess.open(full_path, FileAccess.READ)
						if file:
							var profile = JSON.parse_string(file.get_as_text())
							
							if typeof(profile) == TYPE_DICTIONARY:
								profile["user_id"] = file_user_id
								profile["lobby_id"] = lobby_id
								add_character_card(profile)

							file.close()
			file_name = dir.get_next()
		dir.list_dir_end()
