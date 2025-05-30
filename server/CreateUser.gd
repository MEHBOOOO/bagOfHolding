extends Panel

signal CreateUser(user, password)

# Called when the node enters the scene tree for the first time.


func _on_submit_button_down():
	CreateUser.emit($VBoxContainer/HBoxContainer/UserNameText.text, $VBoxContainer/HBoxContainer2/PasswordText.text)
	pass # Replace with function body.


func _on_close_button_down():
	queue_free()
	pass # Replace with function body.
