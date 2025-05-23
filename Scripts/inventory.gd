extends Node2D

const ITEM_SLOT = preload("res://scenes/item_slot.tscn")
@export var database_path: String = "res://data.db"
@export var grid_rows: int = 3   
@export var grid_columns: int = 3
@export var slot_size: Vector2 = Vector2(100, 100)

var database: SQLite
var item_names: Array = []

func _ready() -> void:
	# Center the inventory grid
	position = get_viewport_rect().size / 2 - Vector2(
		(grid_columns * slot_size.x) / 2,
		(grid_rows * slot_size.y) / 2
	)
	
	database = SQLite.new()
	database.path = database_path
	
	if database.open_db():
		load_item_names()
		create_inventory_grid()
	else:
		push_error("Database open failed: ", database.error_message)

func create_inventory_grid() -> void:
	for row in range(grid_rows):
		for col in range(grid_columns):
			var slot = ITEM_SLOT.instantiate()
			var pos = Vector2(col * slot_size.x, row * slot_size.y)
			
			slot.position = pos
			
			var flat_index = row * grid_columns + col
			set_slot_text(slot, flat_index)
			
			add_child(slot)

func set_slot_text(slot: Node, index: int) -> void:
	var label = slot.find_child("Name", true, false)
	if label:
		label.text = item_names[index] if index < item_names.size() else "Empty"
	else:
		push_warning("missing ", index)

func load_item_names() -> void:
	if database.query("SELECT name FROM items ORDER BY id ASC"):
		for record in database.query_result:
			item_names.append(str(record["name"]))
		print("Loaded items: ", item_names)
	else:
		push_error("failed: ", database.error_message)

func _exit_tree() -> void:
	if database:
		database.close_db()
