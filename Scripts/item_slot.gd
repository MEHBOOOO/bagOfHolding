extends Node2D

var item_data: Dictionary = {}

func set_item_data(data: Dictionary):
	item_data = data
	# Update your slot visuals here (name, icon, etc.)
	$Name.text = data.get("name", "Unknown")
