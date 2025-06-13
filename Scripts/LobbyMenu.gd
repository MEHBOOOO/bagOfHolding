extends Control

@onready var room_name_input = $VBoxContainer/RoomNameInput

func _ready():
	$VBoxContainer/CreateLobbyButton.pressed.connect(_on_create_lobby_pressed)
	$VBoxContainer/JoinLobbyButton.pressed.connect(_on_join_lobby_pressed)

func _on_create_lobby_pressed():
	var room_name = room_name_input.text.strip_edges()
	if room_name == "":
		print("Введите название комнаты")
		return

	# Запуск сервера
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(12345)  # Порт можно рандомизировать
	if result != OK:
		print("Ошибка запуска сервера")
		return

	multiplayer.multiplayer_peer = peer
	print("Сервер запущен: " + room_name)

func _on_join_lobby_pressed():
	var room_name = room_name_input.text.strip_edges()
	if room_name == "":
		print("Введите название комнаты")
		return

	# Подключение к серверу (для упрощения IP — localhost)
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client("127.0.0.1", 12345)  # Здесь можно использовать имя комнаты как IP или ключ
	if result != OK:
		print("Не удалось подключиться к серверу")
		return

	multiplayer.multiplayer_peer = peer
	print("Подключено к лобби: " + room_name)
