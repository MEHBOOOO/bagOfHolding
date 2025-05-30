extends RefCounted
class_name DB

var db

func _init():
	db = SQLite.new()
	db.path = "res://data.db"
	db.open_db()
	
	var table = {
		"id" : {"data_type": "int", "primary_key" : true, "not_null" : true, "auto_increment"  : true},
		"name": {"data_type" : "text"},
		"password" : {"data_type" : "text"} 
	}
	
	db.create_table("players", table)

func InsertUserData(name, password):
	var data = {
		"name" : name,
		"password" : password,
	}
	db.insert_row("players", data)
func UsernameExists(username):
	var query = "SELECT name FROM players WHERE name = ?"
	var paramBindings = [username]
	db.query_with_bindings(query, paramBindings)
	return db.query_result.size() > 0
	
func GetUserFromDB(username):
	var paramBindings = [username]
	db.query_with_bindings("SELECT password, id from players where name = ?", paramBindings)
	for i in db.query_result:
		return{
			"id" : i["id"],
			"password" : i["password"],
			"name" : username
		} 
