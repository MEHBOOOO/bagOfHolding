extends Control

signal item_created()

var ind: int = 0

func _ready() -> void:
	pass


func _on_option_button_item_selected(index: int) -> void:
	ind = index

func _on_insertdata_button_down() -> void:
	var data = {
		"name": $Name.text,
		"ind": ind,
		"description": $Description.text
	}
	
	NetworkManager.request_create_item(data)
	
	$Name.text = ""
	$Description.text = ""
	
func _on_button_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Menu.tscn")
	pass # Replace with function body.
