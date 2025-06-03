extends Node2D

const ITEM_SLOT = preload("res://scenes/item_slot.tscn")
@export var database_path: String = "res://data.db"
@export var grid_rows: int = 3
@export var grid_columns: int = 3
@export var slot_size: Vector2 = Vector2(100, 100)

var database: SQLite
var item_names: Array = []
var current_page: int = 0
var slots: Array = []
var prev_button: Button
var next_button: Button

func _ready() -> void:
	position = get_viewport_rect().size / 2 - Vector2(
		(grid_columns * slot_size.x) / 2,
		(grid_rows * slot_size.y) / 2
	)
	
	database = SQLite.new()
	database.path = database_path
	
	if database.open_db():
		load_item_names()
		create_inventory_grid()
		create_navigation_buttons()
		update_grid()
	else:
		push_error("Database open failed: ", database.error_message)

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
			if item_index < item_names.size():
				label.text = item_names[item_index]
			else:
				label.text = "Empty"
		else:
			push_warning("Label not found in slot ", i)
	
	update_button_states()

func update_button_states() -> void:
	var total_pages = ceil(item_names.size() / float(grid_rows * grid_columns))
	prev_button.visible = current_page > 0
	next_button.visible = current_page < total_pages - 1

func next_page() -> void:
	current_page += 1
	update_grid()

func prev_page() -> void:
	current_page = max(0, current_page - 1)
	update_grid()

func load_item_names() -> void:
	if database.query("SELECT name FROM items ORDER BY id ASC"):
		for record in database.query_result:
			item_names.append(str(record["name"]))
		print("Loaded items: ", item_names)
	else:
		push_error("Query failed: ", database.error_message)

func _exit_tree() -> void:
	if database:
		database.close_db()
