extends Node
class_name Message

enum Message{
	id,
	userConnected,
	userDisconnected,
	lobby,
	candidate,
	offer,
	answer,
	removeLobby,
	createUser,
	loginUser ,
	playerinfo,
	failedToLogin,
	InventoryRequest,
	InventoryData,
	createItem
}
