extends Control

func _on_Button_pressed():
	get_tree().change_scene_to_file("res://scenes/Login.tscn")
	
func _on_GameRoom_pressed():
	get_tree().change_scene_to_file("res://scenes/GameRoom.tscn")
	
func _on_GameScreen_pressed():
	get_tree().change_scene_to_file("res://scenes/GameScreen.tscn")
