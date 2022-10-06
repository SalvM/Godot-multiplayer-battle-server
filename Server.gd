extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 2
var puppets = {}
var match_room = null

func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	printt("Server started at port", port)
	match_room = Fight.create_new_match_room()
	
	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")

remote func fetch_server_time(client_time):
	rpc_id(get_tree().get_rpc_sender_id(), "return_server_time", OS.get_system_time_msecs(), client_time)

remote func determine_latency(client_time):
	rpc_id(get_tree().get_rpc_sender_id(), "return_latency", client_time)

remote func fetch_user_join_room():
	var peer_id = get_tree().get_rpc_sender_id()
	printt("fetch_user_join_room", peer_id)
	if match_room.status == "waiting":
		if match_room.players.size() <= max_players:
			match_room.players[peer_id] = peer_id
			rpc_id(peer_id, "return_room_status", match_room)
			if match_room.players.size() == max_players:
				load_battlefields()
		else:
			rpc_unreliable_id(peer_id, "return_message_from_server", "The room is full")
	else:
		rpc_unreliable_id(peer_id, "return_message_from_server", "The game is already started")

remote func load_battlefields():
	if not match_room.players.size() > 0:
		return
	for player_id in match_room.players:
		user_load_battlefield(player_id)
	match_room.status = "started"

remote func user_load_battlefield(peer_id):
	rpc_id(peer_id, "user_load_battlefield", peer_id)

remote func receive_player_state(player_state):
	#printt("receive_player_state", player_state)
	var player_id = get_tree().get_rpc_sender_id()
	var tmp_bars = [100, 80, 3]
	if puppets.has(player_id):
		if puppets[player_id]["T"] < player_state["T"]:
			tmp_bars = puppets[player_id]["B"]
			puppets[player_id] = player_state
	else:
		puppets[player_id] = player_state
	puppets[player_id]["B"] = tmp_bars

remote func send_world_state(world_state):
	rpc_unreliable_id(0, "receive_world_state", world_state)

remote func register_player(peer_id):
	puppets[peer_id] = {
		"T": OS.get_system_time_msecs(),	# time in ms
		"P": Vector2(Fight.random_puppet_position(), 30),	# position
		"S": 0, # State
		"L": false, # Is looking left
		"B": [100, 80, 3]
	}

remote func fetch_player_damage():
	var player_id = get_tree().get_rpc_sender_id()
	var damage = Fight.fetch_player_damage()
	puppets[player_id]["B"][0] -= damage
	puppets[player_id]["S"] = 4 # HURT
	print("Sending " + str(damage) + " to player #" + str(player_id))
	
func _ready():
	start_server()

func _on_peer_connected(peer_id):
	print("User #" + str(peer_id) + " connected")
	register_player(peer_id)
	# rpc_id(peer_id, "user_load_battlefield", peer_id)
	
func _on_peer_disconnected(peer_id):
	var string_peer_id = str(peer_id)
	print("User #" + string_peer_id + " disconnected")
	if has_node(string_peer_id):
		get_node(string_peer_id).queue_free()
	if match_room.players.has(peer_id):
		match_room.players.erase(peer_id)
		rpc_id(0, "return_room_status", match_room)
	if puppets.has(peer_id):
		puppets.erase(peer_id)
		rpc_id(0, "despawn_player", peer_id)
