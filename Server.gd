extends Node

var randomizer = RandomNumberGenerator.new()
var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 4
var puppets = {}
var match_room = null

func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	printt("Server started at port", port)
	match_room = Fight.create_new_match_room()
	
	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")

remote func fetch_user_join_room():
	var peer_id = get_tree().get_rpc_sender_id()
	printt("fetch_user_join_room", peer_id)
	if match_room.status == "waiting":
		if match_room.players.size() <= max_players:
			match_room.players[peer_id] = peer_id
			rpc_id(peer_id, "return_room_status", match_room)
		else:
			rpc_unreliable_id(peer_id, "return_message_from_server", "The room is full")
	else:
		rpc_unreliable_id(peer_id, "return_message_from_server", "The game is already started")

remote func user_load_battlefield(peer_id):
	rpc_id(peer_id, "user_load_battlefield", peer_id)

remote func user_spawn_puppet(peer_id, is_player_puppet):
	randomizer.randomize()
	var x_coordinates = randomizer.randi_range(100, 900)
	rpc_id(peer_id, "user_spawn_puppet", peer_id, x_coordinates, is_player_puppet)

remote func register_player(peer_id):
	var id = get_tree().get_rpc_sender_id()
	puppets[peer_id] = null

remote func fetch_battlefield_loaded():
	var player_id = get_tree().get_rpc_sender_id()
	if puppets[player_id] == null:
		user_spawn_puppet(player_id, true)
	print("User #" + str(player_id) + " has loaded the battlefield")

remote func fetch_player_damage(requester_instance_id):
	var player_id = get_tree().get_rpc_sender_id()
	var damage = Fight.fetch_player_damage()
	rpc_id(player_id, "return_player_damage", damage, requester_instance_id)
	print("Sending " + str(damage) + " to player #" + str(player_id))
	
func _ready():
	start_server()

func _on_peer_connected(peer_id):
	print("User #" + str(peer_id) + " connected")
	register_player(peer_id)
	# rpc_id(peer_id, "user_load_battlefield", peer_id)
	
func _on_peer_disconnected(peer_id):
	print("User #" + str(peer_id) + " disconnected")
	if match_room.players.has(peer_id):
		match_room.players.erase(peer_id)
		rpc_id(0, "return_room_status", match_room)
	puppets.erase(peer_id)
