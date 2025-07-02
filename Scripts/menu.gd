extends Control

@onready var view_characters_button = $ViewCharactersButton

func _ready() -> void:
	#view_characters_button.pressed.connect(_on_view_characters_pressed)
	#pass # Replace with function body.

	#$AuthorImage.connect("pressed", Callable(self, "_on_author_image_pressed"))
	pass


func _on_author_image_pressed():
	if $AuthorPopup.is_visible():
		$AuthorPopup.hide()
	else:
		$AuthorPopup.popup_centered()


func _on_close_button_pressed():
	$AuthorPopup.hide()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_view_characters_pressed():
	get_tree().change_scene_to_file("res://Scenes/CharacterOverview.tscn")


func _on_lobby_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
	pass # Replace with function body.


func _on_create_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/create.tscn")
	pass # Replace with function body.


func _on_inventory_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/inventory.tscn")
	pass # Replace with function body.


func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobbies.tscn")
	pass # Replace with function body.

func _on_ExitButton_pressed():
	get_tree().quit()


#func _on_author_image_pressed() -> void:
	#pass # Replace with function body.
