extends Panel

signal LoginUser(email, password)
signal CreateUser(email, user, password)

@export var CreateUserWindow : PackedScene

func _ready():
	NetworkManager.login_failed.connect(SetSystemErrorLabel)
	NetworkManager.player_info_received.connect(_on_player_info_received)

func _on_player_info_received(info):
	$RichTextLabel3.text = "Logged in as: "

func _on_cancel_button_down():
	queue_free()

func _on_create_user_button_down():
	var createUserWindow = CreateUserWindow.instantiate()
	add_child(createUserWindow)
	createUserWindow.CreateUser.connect(createUser)

func createUser(email, user, password):
	NetworkManager.create_user_requested.emit(email, user, password)
	CreateUser.emit(email, user, password)  

func _on_login_button_down():
	NetworkManager.login_requested.emit($email.text, $Password.text)
	LoginUser.emit($email.text, $Password.text)  

func SetSystemErrorLabel(text):
	$RichTextLabel3.text = text


func _on_client_button_down() -> void:
	NetworkManager._on_start_client_button_down()
	pass # Replace with function body.

@onready var status_label = $Text 

func _on_server_button_down() -> void:

	
	if Server.StartServer():
		status_label.text = "Server: Running on port 8915"
	else:
		status_label.text = "Server: Failed to start (error %d)"
	pass # Replace with function body.
