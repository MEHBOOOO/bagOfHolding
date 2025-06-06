extends Panel

signal CreateUser(email, username, password)

func _on_submit_button_down():
	var email_input = $VBoxContainer/HBoxContainer/EmailText
	var username_input = $VBoxContainer/HBoxContainer3/UserNameText
	var password_input = $VBoxContainer/HBoxContainer2/PasswordText
	
	# Get the text values
	var email = email_input.text.strip_edges()
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	# Validate inputs
	if email.is_empty():
		show_error("Email cannot be empty")
		return
	if username.is_empty():
		show_error("Username cannot be empty")
		return
	if password.is_empty():
		show_error("Password cannot be empty")
		return
	
	CreateUser.emit(email, username, password)

func show_error(message):
	$RichTextLabel.text = "[color=red]" + message + "[/color]"

func _on_close_button_down():
	queue_free()
