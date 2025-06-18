extends Control

@onready var inventory_list = $VBoxContainer/InventoryList
@onready var title_label = $VBoxContainer/TitleLabel
@onready var back_button = $VBoxContainer/BackButton

var user_id: int
var lobby_id: String

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	if user_id != null and lobby_id != null:
		request_inventory_from_server(user_id, lobby_id)
	print("🔍 InventoryView — user_id:", user_id)
	print("🔍 InventoryView — lobby_id:", lobby_id)

	if user_id != null and lobby_id != null:
		load_inventory_for_profile(user_id, lobby_id)

	NetworkManager.inventory_data_received.connect(_on_inventory_data_received)
	NetworkManager.request_inventory(user_id, lobby_id)
	
func request_inventory_from_server(uid: int, lid: String):
	var message = {
		"message": Message.Message.LoadInventory,
		"user_id": uid,
		"lobby_id": lid,
		"orgPeer": NetworkManager.id
	}
	NetworkManager.peer.put_packet(JSON.stringify(message).to_utf8_buffer())

func _on_inventory_data_received(items: Array):
	inventory_list.clear()
	if items.size() == 0:
		inventory_list.add_item("⚠ Нет предметов")
		return

	for item in items:
		inventory_list.add_item("- %s" % item.get("name", "Неизвестный предмет"))

		
func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/CharacterOverview.tscn") # Назад

func load_inventory_for_profile(uid: int, lid: String):
	var path = "user://inventory/%s_%s_inventory.json" % [uid, lid]
	if not FileAccess.file_exists(path):
		inventory_list.add_item("⚠ Нет предметов")
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var items = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(items) == TYPE_ARRAY:
		for item in items:
			inventory_list.add_item("- %s" % item.get("name", "Неизвестный предмет"))
	else:
		inventory_list.add_item("⚠ Ошибка чтения инвентаря")
