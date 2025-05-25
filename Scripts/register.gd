extends Control

@onready var email_field = $VBoxContainer/Email
@onready var nickname_field = $VBoxContainer/Nickname
@onready var password_field = $VBoxContainer/Password
@onready var confirm_field = $VBoxContainer/Confirm
@onready var user_manager = preload("res://scripts/user_manager.gd").new()

func _ready():
	add_child(user_manager)

func _on_Register_pressed():
	var email = email_field.text.strip_edges()
	var nick = nickname_field.text.strip_edges()
	var pwd = password_field.text.strip_edges()
	var confirm = confirm_field.text.strip_edges()

	if pwd != confirm:
		print("Пароли не совпадают")
		return

	if user_manager.register_user(email, nick, pwd):
		print("Регистрация прошла успешно")
		get_tree().change_scene_to_file("res://scenes/Login.tscn")
	else:
		print("Никнейм уже занят")
