extends Control

signal item_created()

var database: SQLite
var ind: int = 0

func _ready() -> void:
	database = SQLite.new()
	database.path = "res://data.db"
	var err = database.open_db()
	
	var schema = {
		"id":          {"data_type":"int",  "primary_key":true,  "not_null":true, "auto_increment":true},
		"name":        {"data_type":"text", "not_null":true},
		"ind":         {"data_type":"int",  "not_null":true},
		"description": {"data_type":"text"}
	}
	database.create_table("items", schema)

func _on_option_button_item_selected(index: int) -> void:
	ind = index

func _on_createtable_button_down() -> void:
	var schema = {
		"id":          {"data_type":"int",  "primary_key":true,  "not_null":true, "auto_increment":true},
		"name":        {"data_type":"text", "not_null":true},
		"ind":         {"data_type":"int",  "not_null":true},
		"description": {"data_type":"text"}
	}
	database.create_table("items", schema)
	print("Items table recreated.")

func _on_insertdata_button_down() -> void:
	var data = {
		"name": $Name.text,
		"ind": ind,
		"description": $Description.text
	}
	database.insert_row("items", data)
	print("Inserted item '%s' (ind=%d)" % [data.name, data.ind])
	emit_signal("item_created")
