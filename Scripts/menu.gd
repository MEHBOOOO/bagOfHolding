extends Control


func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_profile_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/PlayerProfile.tscn")
	pass # Replace with function body.


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
