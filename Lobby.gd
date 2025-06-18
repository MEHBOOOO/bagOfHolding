class_name Lobby
extends RefCounted

# Declare all properties at the class level
var host_user_id: int
var host_peer_id: int
var Players: Dictionary
var openSlots: int
var timeToLive: int
var lobby_name: String
var created_at: String

func _init(initial_host_user_id: int):
	host_user_id = initial_host_user_id
	host_peer_id = -1  # -1 means no peer connected
	Players = {}
	openSlots = 6
	timeToLive = 60
	lobby_name = "Unnamed Lobby"
	created_at = Time.get_datetime_string_from_system()

func AddPlayer(id: int, name: String) -> Dictionary:
	Players[id] = {
		"name": name,
		"id": id,
		"index": Players.size() + 1
	}
	return Players[id]

func RemovePlayer(id: int):
	if Players.has(id):
		Players.erase(id)
		# Reindex remaining players
		var index = 1
		for player_id in Players:
			Players[player_id]["index"] = index
			index += 1
