extends Control

@onready var nickname_field = $VBoxContainer/Nickname
@onready var password_field = $VBoxContainer/Password
@onready var user_manager = preload("res://scripts/user_manager.gd").new()

func _ready():
	add_child(user_manager)

func _on_Login_pressed():
	var nick = nickname_field.text.strip_edges()
	var pwd = password_field.text.strip_edges()  # ⚠️ заменено с "pass"

	if user_manager.login_user(nick, pwd):
		print("Успешный вход!")
		var room = preload("res://scenes/MainMenu.tscn").instantiate()
		
		room.current_user = nick
		get_tree().root.add_child(room)
		queue_free()
	else:
		print("Неверный логин или пароль")

func _on_Register_pressed():
	get_tree().change_scene_to_file("res://scenes/Register.tscn")


#func _on_войти_pressed() -> void:
	#pass # Replace with function body.


func _on_login_pressed() -> void:
	pass # Replace with function body.
