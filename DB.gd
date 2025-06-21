extends RefCounted
class_name DB

var db

func _init():
	db = SQLite.new()
	var db_path = "user://data.db"
	
	if not FileAccess.file_exists(db_path):
		var dir = DirAccess.open("user://")
		dir.make_dir_recursive("user://")
		
		var source = FileAccess.open("user://data.db", FileAccess.READ)
		if source:
			var buffer = source.get_buffer(source.get_length())
			source.close()
			
			var dest = FileAccess.open(db_path, FileAccess.WRITE)
			if dest:
				dest.store_buffer(buffer)
				dest.close()
	
	db.path = db_path
	if db.open_db() != true:
		push_error("Database open failed: ", db.error_message)
		return
		
	var table = {
		"id" : {
			"data_type": "int",
			"primary_key": true,
			"not_null": true,
			"auto_increment": true
		},
		"name": {
			"data_type": "text",
			"unique": true
		},
		"email": {
			"data_type": "text",
			"unique": true
		},
		"password": {
			"data_type": "text"
		},
		"salt": {
			"data_type": "text"
		}
	}
	var items_schema = {
	"id": {"data_type":"int", "primary_key":true, "not_null":true, "auto_increment":true},
	"name": {"data_type":"text", "not_null":true},
	"ind": {"data_type":"int", "not_null":true},
	"description": {"data_type":"text"},
	"user_id": {"data_type":"int", "not_null":true},
	"lobby_id": {"data_type":"text", "not_null":true}
}
	var lobby_schema = {
		"id": {"data_type":"int", "primary_key":true, "auto_increment":true},
		"lobby_id": {"data_type":"text", "unique":true, "not_null":true},
		"host_id": {"data_type":"int", "not_null":true},
		"lobby_name": {"data_type":"text", "not_null":true},
		"created_at": {"data_type":"text", "not_null":true}
	}
	var user_lobbies_schema = {
		"user_id": {"data_type":"int", "not_null":true},
		"lobby_id": {"data_type":"text", "not_null":true}
	}
	
	
	var lobby_participants_schema = {
		"lobby_id": {
			"data_type": "text", 
			"not_null": true
		},
		"user_id": {
			"data_type": "int", 
			"not_null": true
		},
		"is_host": {
			"data_type": "bool", 
			"not_null": true, 
			"default": false
		},
		"joined_at": {
			"data_type": "text", 
			"not_null": true
		}
	}

	db.create_table("lobby_participants", lobby_participants_schema)
	db.create_table("user_lobbies", user_lobbies_schema)
	db.create_table("lobbies", lobby_schema)
	db.create_table("items", items_schema)
	db.create_table("players", table)
	

func get_lobby_host(lobby_id: String) -> int:
	var query = "SELECT host_id FROM lobbies WHERE lobby_id = ? LIMIT 1"
	if db.query_with_bindings(query, [lobby_id]) and db.query_result.size() > 0:
		return db.query_result[0]["host_id"]
	return -1

func add_participant(lobby_id: String, user_id: int, is_host: bool) -> bool:
	var data = {
		"lobby_id": lobby_id,
		"user_id": user_id,
		"is_host": is_host,
		"joined_at": Time.get_datetime_string_from_system()
	}
	return db.insert_row("lobby_participants", data)

func remove_participant(lobby_id: String, user_id: int) -> bool:
	var query = "DELETE FROM lobby_participants WHERE lobby_id = ? AND user_id = ?"
	return db.query_with_bindings(query, [lobby_id, user_id])

func get_lobby_participants(lobby_id: String) -> Array:
	var query = """
		SELECT p.id, p.name, lp.is_host
		FROM players p
		JOIN lobby_participants lp ON p.id = lp.user_id
		WHERE lp.lobby_id = ?
		ORDER BY lp.joined_at
	"""
	if db.query_with_bindings(query, [lobby_id]):
		return db.query_result
	return []



func insert_lobby(data: Dictionary) -> bool:
	return db.insert_row("lobbies", data) && db.insert_row("user_lobbies", {
			   "user_id": data["host_id"],
			   "lobby_id": data["lobby_id"]
		   })

func get_user_lobbies(user_id: int) -> Array:
	var query = """
		SELECT l.lobby_id, l.lobby_name, l.created_at 
		FROM lobbies l
		JOIN lobby_participants lp ON l.lobby_id = lp.lobby_id
		WHERE lp.user_id = ?
	"""
	var params = [user_id]
	db.query_with_bindings(query, params)
	return db.query_result
	
func load_items_by_lobby(lobby_id: String, user_id: String) -> Array:
	var items = []
	var query = "SELECT * FROM items WHERE lobby_id = ? AND user_id = ?"
	var params = [lobby_id, user_id]
	
	if db.query_with_bindings(query, params):
		for record in db.query_result:
			items.append({
				"id": record["id"],
				"name": record["name"],
				"ind": record["ind"],
				"description": record["description"],
				"user_id": record["user_id"]
			})
	else:
		push_error("DB Query failed: " + db.error_message)
	
	return items
func load_items_by_user(user_id: int) -> Array:
	var items = []
	var query = "SELECT * FROM items WHERE user_id = ?"
	var params = [user_id]
	
	if db.query_with_bindings(query, params):
		for record in db.query_result:
			items.append({
				"id": record["id"],
				"name": record["name"],
				"ind": record["ind"],
				"description": record["description"]
			})
	else:
		push_error("DB Query failed: " + db.error_message)
	
	return items
	
func insertItem(data):
	print("Attempting to insert data: ", data)
	var result = db.insert_row("items", data)
	if result == false:
		var error_msg = "Failed to insert item: " + db.error_message
		push_error(error_msg)
		print(error_msg)  # Ensure it shows in console
		return false
	print("Item inserted successfully")
	return true

func InsertUserData(name: String, email: String, password: String) -> void:
	var salt = generate_salt()
	var hashed_password = hash_password(password, salt)

	var data = {
		"name": name,
		"email": email,
		"password": hashed_password,
		"salt": salt
	}
	db.insert_row("players", data)

func UsernameExists(username: String) -> bool:
	var query = "SELECT name FROM players WHERE name = ?"
	var paramBindings = [username]
	db.query_with_bindings(query, paramBindings)
	return db.query_result.size() > 0
	


func EmailExists(email: String) -> bool:
	var query = "SELECT email FROM players WHERE email = ?"
	var paramBindings = [email]
	db.query_with_bindings(query, paramBindings)
	return db.query_result.size() > 0

func GetUserFromDB(email):
	var paramBindings = [email]
	db.query_with_bindings(
		"SELECT id, name, password, salt FROM players WHERE email = ?",
		paramBindings
	)
	for i in db.query_result:
		return {
			"id": i["id"],
			"name": i["name"],
			"email": email,
			"password": i["password"],
			"salt": i["salt"]
		}

func VerifyUser(email: String, password: String) -> bool:
	var user = GetUserFromDB(email)
	if user:
		var attempt_hash = hash_password(password, user.salt)
		return attempt_hash == user.password
	return false


func load_item_names():
	var item_names: Array = []
	if db.query("SELECT name FROM items ORDER BY id ASC") == true:
		for record in db.query_result:
			item_names.append(str(record["name"]))
	else:
		push_error("DB Query failed: " + db.error_message)
	
	return item_names
	
func generate_salt() -> String:
	randomize()
	var salt = ""
	for i in range(16):
		salt += char(randi() % 256)
	return salt.to_utf8_buffer().hex_encode()

func hash_password(password: String, salt: String) -> String:
	var ctx = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)

	var salt_bytes = salt.hex_decode()
	ctx.update(salt_bytes)
	ctx.update(password.to_utf8_buffer())

	return ctx.finish().hex_encode()

func save_profile(user_id: int, lobby_id: String, profile: Dictionary) -> bool:
	var json = JSON.stringify(profile)
	var query = "INSERT OR REPLACE INTO profiles (user_id, lobby_id, profile_json) VALUES (?, ?, ?)"
	return db.execute(query, [user_id, lobby_id, json])

func load_profile(user_id: int, lobby_id: String) -> Dictionary:
	var query = "SELECT profile_json FROM profiles WHERE user_id = ? AND lobby_id = ?"
	if db.query_with_bindings(query, [user_id, lobby_id]) and db.query_result.size() > 0:
		return JSON.parse_string(db.query_result[0]["profile_json"])
	return {}

func delete_item(item_id: int, user_id: int, lobby_id: String) -> bool:
	var query = "DELETE FROM items WHERE id = ? AND user_id = ? AND lobby_id = ?"
	return db.query_with_bindings(query, [item_id, user_id, lobby_id])

func get_items_for_user_in_lobby(user_id: int, lobby_id: String) -> Array:
	var query = """
		SELECT id, name, ind, description 
		FROM items 
		WHERE user_id = ? AND lobby_id = ?
		ORDER BY ind
	"""
	if db.query_with_bindings(query, [user_id, lobby_id]):
		return db.query_result
	return []
