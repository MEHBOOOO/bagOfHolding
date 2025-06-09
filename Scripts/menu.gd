extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_shop_button_down() -> void:
	pass # Replace with function body.


func _on_lobby_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby.tscn")
	pass # Replace with function body.


func _on_create_button_down() -> void:
	get_tree().change_scene_to_file("res://Scenes/create.tscn")
	pass # Replace with function body.


func _on_inventory_button_down() -> void:
	NetworkManager.load_item_names_from_db()
	get_tree().change_scene_to_file("res://Scenes/inventory.tscn")
	pass # Replace with function body.
