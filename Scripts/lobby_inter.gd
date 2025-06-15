extends Node2D
var lobby_id : String


func _on_create_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/create.tscn")
	pass # Replace with function body.


func _on_inventory_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/inventory.tscn")
	pass # Replace with function body.


func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobbies.tscn")
	pass # Replace with function body.
