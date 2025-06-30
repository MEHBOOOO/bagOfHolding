extends Panel

signal LoginUser(email, password)
signal CreateUser(email, user, password)

@export var CreateUserWindow : PackedScene

func _ready():
	NetworkManager.login_failed.connect(SetSystemErrorLabel)
	
	#if $AuthorPopup.has_node("CloseButton"):
		#$AuthorPopup/CloseButton.connect("pressed", Callable(self, "_on_close_button_pressed"))

func _on_author_image_pressed():
	var author_popup = get_node("/root/Login/AuthorPopup")  # Полный путь
	if author_popup.is_visible():
		author_popup.hide()
	else:
		author_popup.popup_centered()
		
func _on_close_button_pressed():
	$AuthorPopup.hide()
			


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


func _on_server_button_down() -> void:
	Server.StartServer()


func _on_author_image_gui_input(event: InputEvent) -> void:
	pass # Replace with function body.


func _on_about_button_down(event: InputEvent) -> void:
	pass # Replace with function body.
