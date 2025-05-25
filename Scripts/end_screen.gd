extends Control

@onready var reason_label = $VBoxContainer/ReasonLabel
@onready var game_manager = preload("res://scripts/game_manager.gd").new()

var reason := ""
var current_game := ""

func _ready():
	add_child(game_manager)
	reason_label.text = reason

func _on_ExitButton_pressed():
	# Удалить завершённую игру
	if current_game in game_manager.games:
		game_manager.games.erase(current_game)
		game_manager.save_games()
	get_tree().change_scene_to_file("res://scenes/GameRoom.tscn")
