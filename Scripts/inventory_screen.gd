extends Control

@onready var item_list = $VBoxContainer/ScrollContainer/ItemList
@onready var name_field = $VBoxContainer/HBoxContainer/ItemNameField
@onready var desc_field = $VBoxContainer/HBoxContainer/ItemDescField
@onready var game_manager = preload("res://scripts/game_manager.gd").new()

var current_user = ""
var current_game = ""

func _ready():
	add_child(game_manager)
	load_items()

func load_items():
	item_list.clear()
	var inventory = game_manager.games.get(current_game).get("inventory", {}).get(current_user, [])
	for item in inventory:
		var label = Label.new()
		label.text = "- %s: %s" % [item["name"], item["description"]]
		item_list.add_child(label)

func _on_AddItemButton_pressed():
	var item = {
		"name": name_field.text.strip_edges(),
		"description": desc_field.text.strip_edges()
	}

	if item["name"] == "":
		print("Название не может быть пустым")
		return

	if current_user not in game_manager.games[current_game]["inventory"]:
		game_manager.games[current_game]["inventory"][current_user] = []

	game_manager.games[current_game]["inventory"][current_user].append(item)
	game_manager.save_games()
	name_field.text = ""
	desc_field.text = ""
	load_items()

func _on_BackButton_pressed():
	var game_screen = preload("res://scenes/GameScreen.tscn").instantiate()
	game_screen.current_user = current_user
	game_screen.current_game = current_game
	get_tree().root.add_child(game_screen)
	queue_free()
