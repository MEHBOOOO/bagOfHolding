extends Control

@onready var character_list = $ScrollContainer/CharacterList
@onready var back_button = $BackButton
@onready var title_label = $TitleLabel
@onready var avatar_popup = $AvatarPopup
@onready var avatar_grid = $AvatarPopup/ScrollContainer/AvatarGrid

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

var current_user_id := NetworkManager.current_user_id

func _ready():
	title_label.text = "📜 Ваши персонажи"
	back_button.pressed.connect(_on_back_pressed)
	load_all_profiles()

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")

func add_character_card(character_data: Dictionary):
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.custom_minimum_size = Vector2(0, 80)

	var avatar_id = character_data.get("avatar_id", 0)

	# Основная аватар-кнопка
	var avatar_btn = TextureButton.new()
	avatar_btn.texture_normal = avatar_textures[avatar_id] if avatar_id < avatar_textures.size() else null
	avatar_btn.custom_minimum_size = Vector2(64, 64)
	avatar_btn.set_size(Vector2(64, 64))
	avatar_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	avatar_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	avatar_btn.disabled = false

	avatar_btn.pressed.connect(func():
		var local_avatar_btn = avatar_btn  # сохранить ссылку
		var local_character_data = character_data.duplicate(true)  # делаем копию
		populate_avatar_popup(func(selected_id):
			print("✅ Выбран аватар:", selected_id)
			local_avatar_btn.texture_normal = avatar_textures[selected_id]
			
			# Обновляем данные
			local_character_data["avatar_id"] = selected_id
			var profile_path = "user://profiles/%s_%s_profile.json" % [
				str(current_user_id),
				local_character_data["lobby_id"]
			]
			
			var file = FileAccess.open(profile_path, FileAccess.WRITE)
			if file:
				file.store_string(JSON.stringify(local_character_data))
				file.close()
				load_all_profiles()
				print("💾 Сохранено:", profile_path)
			else:
				push_error("❌ Не удалось сохранить профиль")
		)
		avatar_popup.popup_centered(Vector2(300, 300))
	)


	hbox.add_child(avatar_btn)

	# Информация: имя и класс
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
	var lobby_id = character_data.get("lobby_id", "unknown")

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

#func populate_avatar_popup(on_avatar_selected: Callable):
	#for child in avatar_grid.get_children():
		#child.queue_free()
#
	#for i in range(avatar_textures.size()):
		#var avatar_btn = TextureButton.new()
		#avatar_btn.texture_normal = avatar_textures[i]
		#avatar_btn.custom_minimum_size = Vector2(64, 64)
#
		#var index := i  # ✅ сохраняем индекс, чтобы не путался в замыкании
#
		#avatar_btn.pressed.connect(func():
			#on_avatar_selected.call(index)
			#avatar_popup.hide()
		#)
#
		#avatar_grid.add_child(avatar_btn)
func populate_avatar_popup(on_avatar_selected: Callable):
	for child in avatar_grid.get_children():
		child.queue_free()

	for i in range(avatar_textures.size()):
		var avatar_btn = TextureButton.new()
		avatar_btn.texture_normal = avatar_textures[i]
		avatar_btn.custom_minimum_size = Vector2(64, 64)

		# ✅ Используем bind
		avatar_btn.pressed.connect(_on_avatar_selected.bind(i, on_avatar_selected))

		avatar_grid.add_child(avatar_btn)

# Обработчик выбора аватара
func _on_avatar_selected(index: int, on_avatar_selected: Callable) -> void:
	on_avatar_selected.call(index)
	avatar_popup.hide()


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
						seen_lobbies[lobby_id] = true

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
