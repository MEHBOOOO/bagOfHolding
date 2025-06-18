extends Node2D

const ITEM_SLOT = preload("res://Scenes/item_slot.tscn")
@export var grid_rows: int = 3
@export var grid_columns: int = 3
@export var slot_size: Vector2 = Vector2(100, 100)

var Items: Array = []
var current_page: int = 0
var slots: Array = []
var prev_button: Button
var next_button: Button

func _ready() -> void:
	$Label.text = "started"
	NetworkManager.inventory_data_received.connect(_on_inventory_data_received)
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
	prev_button = Button.new()
	prev_button.text = "Prev"
	prev_button.position = Vector2(0, grid_rows * slot_size.y + 20)
	prev_button.pressed.connect(prev_page)
	add_child(prev_button)
	
	next_button = Button.new()
	next_button.text = "Next"
	next_button.position = Vector2(
		grid_columns * slot_size.x - next_button.size.x, 
		grid_rows * slot_size.y + 20
	)
	next_button.pressed.connect(next_page)
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
			if item_index < Items.size():
				var item = Items[item_index]
				label.text = item["name"]
				# Add tooltip with description
				if item.has("description") and item["description"] != "":
					label.tooltip_text = item["description"]
				else:
					label.tooltip_text = "No description"
			else:
				label.text = "Empty"
				label.tooltip_text = ""
		else:
			$Label.text = "label not found"
			push_warning("Label not found in slot ", i)
	
	update_button_states()

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
