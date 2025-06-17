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
	createItem,
	createLobby,
	requestLobbies,
	lobbyData,
	lobbyCreated,
	lobbyUpdate,
	getLobbies,
	lobbyParticipants,
	requestParticipants,
	participantsData,
	kickUser
}
