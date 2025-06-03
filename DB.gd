extends RefCounted
class_name DB

var db

func _init():
	db = SQLite.new()
	db.path = "res://data.db"
	db.open_db()

	# Define table schema with id, name, email, password, salt
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

	db.create_table("players", table)

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
