extends Node2D

const ITEM_SLOT = preload("res://Scenes/item_slot.tscn")
@export var grid_rows: int = 5
@export var grid_columns: int = 2
@export var slot_size: Vector2 = Vector2(200, 200)

@onready var item_popup = $ItemPopup
@onready var item_name_label = $ItemPopup/VBoxContainer/ItemNameLabel
@onready var item_description_label = $ItemPopup/VBoxContainer/ScrollContainer/ItemDescriptionLabel
@onready var close_button = $ItemPopup/VBoxContainer/CloseButton

var Items: Array = []
var current_page: int = 0
var slots: Array = []
var prev_button: Button
var next_button: Button

func _ready() -> void:
	$Label.text = "started"
	NetworkManager.inventory_data_received.connect(_on_inventory_data_received)
	close_button.pressed.connect(func(): item_popup.hide())
	position = get_viewport_rect().size / 2 - Vector2(
		(grid_columns * slot_size.x) / 2,
		(grid_rows * slot_size.y) / 2
	)
	create_inventory_grid()
	create_navigation_buttons()
	load_inventory()
	

func create_inventory_grid() -> void:
	for row in range(grid_rows):
		for col in range(grid_columns):
			var slot = ITEM_SLOT.instantiate()
			var pos = Vector2(col * slot_size.x, row * slot_size.y)
			slot.position = pos
			slots.append(slot)
			add_child(slot)
func create_navigation_buttons() -> void:
	# Load textures
	var prev_texture = preload("res://Images/button1.png")
	var next_texture = preload("res://Images/button1.png")
	var pointed_texture = preload("res://Images/button3.png")

	# Create normal style
	var normal_style = StyleBoxTexture.new()
	normal_style.texture = prev_texture
	normal_style.expand_margin_left = 10
	normal_style.expand_margin_right = 10
	normal_style.expand_margin_top = 10
	normal_style.expand_margin_bottom = 10

	# Create hover style
	var hover_style = normal_style.duplicate()
	hover_style.texture = pointed_texture

	# PREV BUTTON
	prev_button = Button.new()
	prev_button.text = "Prev"
	prev_button.position = Vector2(0, grid_rows * slot_size.y + 20)
	prev_button.pressed.connect(prev_page)
	prev_button.add_theme_font_size_override("font_size", 30)
	
	# Text colors - BLACK normally, WHITE on hover/pressed
	prev_button.add_theme_color_override("font_color", Color.BLACK)
	prev_button.add_theme_color_override("font_pressed_color", Color.WHITE)  # White when pressed
	prev_button.add_theme_color_override("font_hover_color", Color.WHITE)    # White when hovered
	
	# Apply styles
	prev_button.add_theme_stylebox_override("normal", normal_style)
	prev_button.add_theme_stylebox_override("hover", hover_style)
	prev_button.add_theme_stylebox_override("pressed", hover_style)  # Use hover style when pressed too
	
	prev_button.custom_minimum_size = Vector2(150, 50)
	add_child(prev_button)

	# NEXT BUTTON
	next_button = Button.new()
	next_button.text = "Next"
	next_button.position = Vector2(
		grid_columns * slot_size.x - 150,
		grid_rows * slot_size.y + 20
	)
	next_button.pressed.connect(next_page)
	next_button.add_theme_font_size_override("font_size", 30)
	
	# Text colors - Same as prev_button
	next_button.add_theme_color_override("font_color", Color.BLACK)
	next_button.add_theme_color_override("font_pressed_color", Color.WHITE)
	next_button.add_theme_color_override("font_hover_color", Color.WHITE)
	
	# Apply styles
	var next_normal_style = normal_style.duplicate()
	next_normal_style.texture = next_texture
	next_button.add_theme_stylebox_override("normal", next_normal_style)
	next_button.add_theme_stylebox_override("hover", hover_style)
	next_button.add_theme_stylebox_override("pressed", hover_style)
	
	next_button.custom_minimum_size = Vector2(150, 50)
	add_child(next_button)
	
	update_button_states()


func update_grid() -> void:
	var items_per_page = grid_rows * grid_columns
	var start_index = current_page * items_per_page

	for i in range(slots.size()):
		var item_index = start_index + i
		var slot = slots[i]
		var label = slot.find_child("Name", true, false)

		if label:
			label.autowrap_mode = TextServer.AUTOWRAP_OFF
			label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			label.clip_text = true

			if item_index < Items.size():
				var item = Items[item_index]
				var full_name = item["name"]
				label.text = full_name

				var tooltip_text = full_name
				if item.has("description") and item["description"] != "":
					tooltip_text += "\n\n" + item["description"]
				else:
					tooltip_text += "\n\nНет описания"
				label.tooltip_text = tooltip_text

				## Подключаем клик на слот
				#if slot is Control:
					#slot.mouse_filter = Control.MOUSE_FILTER_STOP
					#if not slot.is_connected("gui_input", _on_slot_clicked):
						#slot.connect("gui_input", _on_slot_clicked.bind(item))
				var button = slot.get_node("ItemButton")  # путь к твоей кнопке внутри слота
				if button and not button.is_connected("pressed", _on_slot_pressed):
					button.pressed.connect(_on_slot_pressed.bind(item))

			else:
				label.text = "Empty"
				label.tooltip_text = ""
		else:
			$Label.text = "label not found"
			push_warning("Label not found in slot ", i)

	update_button_states()
	
func _on_slot_pressed(item: Dictionary) -> void:
	print("Клик по предмету:", item)
	item_name_label.text = "Название: " + item.get("name", "Безымянный предмет")
	item_description_label.text = "Описание: " + item.get("description", "Нет описания")
	item_popup.popup_centered()

func _on_slot_clicked(event: InputEvent, item: Dictionary) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		item_name_label.text = "Название: " + item.get("name", "Безымянный предмет")
		item_description_label.text = "Описание: " + item.get("description", "Нет описания")
		item_popup.popup_centered()


func update_button_states() -> void:
	var total_pages = ceil(Items.size() / float(grid_rows * grid_columns))
	prev_button.visible = current_page > 0
	next_button.visible = current_page < total_pages - 1

func next_page() -> void:
	current_page += 1
	update_grid()

func prev_page() -> void:
	current_page = max(0, current_page - 1)
	update_grid()

# Fixed load_item_names_from_db function
func load_inventory() -> void:
	if NetworkManager:
		# Clear current items
		Items = []
		update_grid()
		
		# Request fresh inventory from server
		NetworkManager.load_item_names_from_db()
		$Label.text = "Loading items..."
	else:
		$Label.text = "NetworkManager not available"
		push_error("NetworkManager not available")
		
func _on_inventory_data_received(items: Array) -> void:
	Items = items
	update_grid()

func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/LobbyInter.tscn")
	pass 
