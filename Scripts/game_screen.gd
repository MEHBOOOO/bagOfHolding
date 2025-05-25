extends Control

@onready var player_list = $VBoxContainer/PlayerList
@onready var join_button = $VBoxContainer/JoinButton
@onready var game_manager = preload("res://scripts/game_manager.gd").new()

var current_user = ""
var current_game = ""

func _ready():
	add_child(game_manager)
	load_game()

func load_game():
	var game_data = game_manager.games.get(current_game)
	if game_data:
		$VBoxContainer.get_node("Label").text = "Игра: " + current_game
		$VBoxContainer.get_node("Label2").text = "Гейм-мастер: " + game_data["master"]
		player_list.clear()
		for p in game_data["players"]:
			player_list.add_item(p)

		# Прячем кнопку, если пользователь — гейм-мастер или уже в игре
		join_button.visible = !(current_user == game_data["master"] or current_user in game_data["players"])

func _on_JoinButton_pressed():
	if game_manager.add_player_to_game(current_game, current_user):
		print("Вы присоединились к игре")
		load_game()
	else:
		print("Не удалось присоединиться")

func _on_BackButton_pressed():
	var room = preload("res://scenes/GameRoom.tscn").instantiate()
	room.current_user = current_user
	get_tree().root.add_child(room)
	queue_free()

func _on_ProfileButton_pressed():
	var profile = preload("res://scenes/PlayerProfile.tscn").instantiate()
	profile.current_user = current_user
	profile.current_game = current_game
	get_tree().root.add_child(profile)
	queue_free()

func _on_InventoryButton_pressed():
	var inventory = preload("res://scenes/InventoryScreen.tscn").instantiate()
	inventory.current_user = current_user
	inventory.current_game = current_game
	get_tree().root.add_child(inventory)
	queue_free()

func _on_EndGameButton_pressed():
	var end_screen = preload("res://scenes/EndScreen.tscn").instantiate()
	end_screen.reason = "Мастер завершил игру"
	end_screen.current_game = current_game
	get_tree().root.add_child(end_screen)
	queue_free()


func _on_label_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.
