extends Node
# class_name CustomGameManager — либо вообще убираем эту строку

var games = {}
const SAVE_PATH := "user://games.json"

func _ready():
	load_games()

func load_games():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = file.get_as_text()
		games = JSON.parse_string(data) if data != "" else {}
	else:
		games = {}

func save_games():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(games))

func create_game(game_name: String, master_nick: String) -> bool:
	if game_name in games:
		return false
	games[game_name] = {
		"master": master_nick,
		"players": [],
		"info": {}
	}
	save_games()
	return true

func get_games():
	return games
