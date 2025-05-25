extends Node

var users = {}
const SAVE_PATH := "user://users.json"

func _ready():
	load_users()

func load_users():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var data = file.get_as_text()
		users = JSON.parse_string(data) if data != "" else {}
	else:
		users = {}

func save_users():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(users))

func register_user(email: String, nickname: String, password: String) -> bool:
	if nickname in users:
		return false
	users[nickname] = {
		"email": email,
		"password": password
	}
	save_users()
	return true

func login_user(nickname: String, password: String) -> bool:
	if nickname in users and users[nickname]["password"] == password:
		return true
	return false
