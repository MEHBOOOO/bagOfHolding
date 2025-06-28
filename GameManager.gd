#extends Node
#
#var Players = {}
#var current_lobby_id : String
## Called when the node enters the scene tree for the first time.
#var current_user_id: int = -1
#var current_profile: Dictionary = {}  # 👈 хранит профиль игрока
#
#func _ready():
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass


extends Node

# Словарь всех игроков в текущем лобби: ключ — user_id, значение — профиль
var players: Dictionary = {}

# ID текущего лобби
var current_lobby_id: String = ""

# ID текущего пользователя (назначается после входа)
var current_user_id: int = -1

# Профиль текущего пользователя
var current_profile: Dictionary = {}

# Сигнал на случай обновления профиля
signal profile_updated

# Вызывается при запуске узла
func _ready():
	print("PlayerManager загружен")
	# Здесь можно загрузить профиль пользователя
	# load_profile(current_user_id)

# Вызывается каждый кадр
func _process(delta: float) -> void:
	pass

# Установить профиль текущего игрока
func set_profile(profile: Dictionary) -> void:
	current_profile = profile
	emit_signal("profile_updated")
	print("Профиль обновлён: %s" % profile)

# Вход в лобби
func join_lobby(lobby_id: String) -> void:
	current_lobby_id = lobby_id
	print("Вошёл в лобби: %s" % lobby_id)

# Выход из лобби
func leave_lobby() -> void:
	current_lobby_id = ""
	print("Покинул лобби")
