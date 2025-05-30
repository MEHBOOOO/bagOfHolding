extends Panel

signal LoginUser(user, password)
signal CreateUser(user, password)


@export var CreateUserWindow : PackedScene
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_cancel_button_down():
	queue_free()
	pass # Replace with function body.


func _on_create_user_button_down():
	var createUserWindow = CreateUserWindow.instantiate()
	add_child(createUserWindow)
	createUserWindow.CreateUser.connect(createUser)
	pass # Replace with function body.

func createUser(name, password):
	CreateUser.emit(name, password)

func _on_login_button_down():
	LoginUser.emit($Username.text, $Password.text)
	pass # Replace with function body.

func SetSystemErrorLabel(text):
	$RichTextLabel3.text = text
