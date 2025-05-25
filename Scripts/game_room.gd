extends Control

var current_user: String = ""

@onready var game_list = $VBoxContainer/GameList
@onready var new_game_name = $VBoxContainer/NewGameName

var game_manager = preload("res://scripts/game_manager.gd").new()
var user_manager = preload("res://scripts/user_manager.gd").new()


func _ready():
	add_child(game_manager)
	add_child(user_manager)
	load_games()

func load_games():
	game_list.clear()
	for game_name in game_manager.get_games().keys():
		game_list.add_item(game_name)

func _on_CreateGameButton_pressed():
	var gameName = new_game_name.text.strip_edges()
	if gameName == "":
		print("Введите имя игры")
		return

	if game_manager.create_game(name, current_user):
		print("Игра создана")
		load_games()
	else:
		print("Игра с таким названием уже существует")

func _on_ExitButton_pressed():
	get_tree().change_scene_to_file("res://scenes/Login.tscn")

func _on_GameList_item_activated(index):
	var game_name = game_list.get_item_text(index)
	var game = preload("res://scenes/GameScreen.tscn").instantiate()
	game.current_user = current_user  # Теперь работает
	game.current_game = game_name
	get_tree().root.add_child(game)
	queue_free()
