extends Node

const PORT = 4242
const RECONNECT_TIMEOUT: float = 3.0

onready var MatchRoom = preload("res://Room.tscn")

onready var Logger = $Logger
onready var MatchRooms = $Rooms

var network = NetworkedMultiplayerENet.new()

const FPS = 0.5
const frames_to_skip = 60 / FPS
var current_frame = 0

const max_players_per_room = 2 # how many players in one room
const max_match_rooms = 4 # how many rooms can run
const max_player_per_session = 1000 # it would be nice to add a waiting "room" (=> an array of id)
const connected_players = {} # [peer_id]: [room_id] this will make the disconnection easier

func _print(text: String):
	Logger.text = text
	print(text)

func create_match_room():
	var new_room = MatchRoom.instance()
	new_room.set_name(str(MatchRooms.get_child_count()))
	new_room.max_players = max_players_per_room
	MatchRooms.add_child(new_room)

func create_match_rooms():
	while MatchRooms.get_child_count() < max_match_rooms:
		create_match_room()

func get_match_room(room_id):
	return MatchRooms.get_child(int(room_id))

func get_puppet(player_id, room_id):
	var match_room = get_match_room(room_id)
	if !match_room:
		return false
	if match_room.is_player_in_room(player_id):
		return match_room["puppets"][player_id]
	else:
		return false

func start_server():
	_print("Starting the server on port: " + str(PORT))
	network.create_server(PORT, max_players_per_room)
	get_tree().set_network_peer(network)
	_print("Server started at port: " + str(PORT))
	create_match_rooms()

	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")

func start_server_with_websocket():
	var server = WebSocketServer.new()
	var err = server.listen(PORT, PoolStringArray(), true)
	if err != OK:
		_print("Unable to start server")
		set_process(false)
		return
	_print("Server started at port: " + str(PORT))
	get_tree().set_network_peer(server)
	create_match_rooms()
	server.connect("peer_connected", self, "_on_peer_connected")
	server.connect("peer_disconnected", self, "_on_peer_disconnected")

func default_puppet():
	return {
		"T": OS.get_system_time_msecs(),	# time in ms
		"P": Vector2(Fight.random_puppet_position(), 30),	# position
		"S": 0, # State
		"L": false, # Is looking left
		"B": [100, 80, 3],
		"anti_cheat": {
			"last_attack_ms": 0,
			"last_dash_ms": 0
		} # used to check if the player is cheating, it won't be send to the players
	}

remote func fetch_server_time(client_time):
	rpc_id(get_tree().get_rpc_sender_id(), "return_server_time", OS.get_system_time_msecs(), client_time)

remote func determine_latency(client_time):
	rpc_id(get_tree().get_rpc_sender_id(), "return_latency", client_time)

remote func fetch_user_join_room(room_id):
	var peer_id = get_tree().get_rpc_sender_id()
	print("User #" + str(peer_id) + " is trying enter room #" + str(room_id))
	for match_room in MatchRooms.get_children():
		if !match_room:
			rpc_unreliable_id(peer_id, "return_message_from_server", "The room is closed")
			return
		if int(match_room.name) == int(room_id):
			if match_room.can_join_room() && !match_room.is_player_in_room(peer_id):
				connected_players[peer_id] = room_id
				match_room.join_room(peer_id)
				print("User #" + str(peer_id) + " joined room #" + str(room_id))
			else:
				rpc_unreliable_id(peer_id, "return_message_from_server", "The room is full")
		else:
			#print("User #" + str(peer_id) + " leaved room #" + match_room.name)
			match_room.leave_room(peer_id)
	rpc_unreliable_id(peer_id, "return_match_rooms", get_match_rooms_status().match_rooms)

remote func fetch_user_leave_room(room_id):
	get_match_room(room_id).leave_room(get_tree().get_rpc_sender_id())

remote func load_battlefields(room_id):
	var match_room = get_match_room(room_id)
	if !match_room:
		return
	for player_id in match_room.puppets:
		user_load_battlefield(player_id, room_id)
	match_room.state = 1 # STARTED

remote func user_load_battlefield(peer_id, room_id):
	rpc_id(peer_id, "user_load_battlefield", room_id)

remote func receive_player_state(player_state, room_id):
	var player_id = get_tree().get_rpc_sender_id()
	var tmp_bars = Fight.default_puppet_bar()
	var prev_state = get_puppet(player_id, room_id)
	if !prev_state:
		return
	if prev_state["T"] < player_state["T"]:
		var tmp_anti_cheat = prev_state["anti_cheat"].duplicate(true) # the client doesn't have this
		tmp_bars = prev_state["B"]
		if prev_state.S != player_state.S: # triggered once
			var is_attacking = player_state.S in [5, 6]
			var is_dashing = player_state.S == 7
			if is_attacking:
				if not AntiCheat.can_attack(prev_state, player_state): # the player is cheating!!
					AntiCheat.on_player_cheating(player_id, prev_state, player_state)
				tmp_anti_cheat["last_attack_ms"] = player_state["T"]
				tmp_bars[1] -= Fight.basic_attack_cost() # deduct stamina
			if is_dashing:
				if not AntiCheat.can_dash(prev_state, player_state): # the player is cheating!!
					AntiCheat.on_player_cheating(player_id, prev_state, player_state)
				tmp_anti_cheat["last_dash_ms"] = player_state["T"]
				tmp_bars[2] -= 1 # consume dash stack
		var current_puppet = get_puppet(player_id, room_id)
		if current_puppet:
			current_puppet["L"] = player_state["L"]
			current_puppet["P"] = player_state["P"]
			current_puppet["S"] = player_state["S"]
			current_puppet["T"] = player_state["T"]
			current_puppet["anti_cheat"] = tmp_anti_cheat
			current_puppet["B"] = tmp_bars
			"""
			MatchRooms.get_child(int(room_id)).puppets[player_id]["L"] = player_state["L"]
			MatchRooms.get_child(int(room_id)).puppets[player_id]["P"] = player_state["P"]
			MatchRooms.get_child(int(room_id)).puppets[player_id]["S"] = player_state["S"]
			MatchRooms.get_child(int(room_id)).puppets[player_id]["T"] = player_state["T"]
			MatchRooms.get_child(int(room_id)).puppets[player_id]["anti_cheat"] = tmp_anti_cheat
			MatchRooms.get_child(int(room_id)).puppets[player_id]["B"] = tmp_bars
			"""

func get_match_rooms_status():
	var match_rooms = []
	var excluded_players = [] # they are playing so they don't need this rpc
	for match_room in MatchRooms.get_children():
		var room_status = match_room.room_status()
		match_rooms.append(room_status)
		if room_status.status != "WAITING":
			excluded_players.append_array(room_status.players)
	return { "excluded_players": excluded_players, "match_rooms": match_rooms }

remote func send_match_rooms(): # only for waiting players in the lobby
	var match_rooms_status = get_match_rooms_status()
	var excluded_players = match_rooms_status.excluded_players
	var match_rooms = match_rooms_status.match_rooms
	for player_id in connected_players.keys():
		if not player_id in excluded_players:
			rpc_unreliable_id(player_id, "return_match_rooms", match_rooms)

remote func send_room_state(room_state, players_list):
	for player_id in players_list:
		rpc_unreliable_id(player_id, "receive_room_state", room_state)

remote func fetch_player_damage(room_id):
	var player_id = get_tree().get_rpc_sender_id()
	var damage = Fight.fetch_player_damage()
	var player_puppet = get_puppet(player_id, room_id)
	if !player_puppet:
		return
	player_puppet["B"][0] -= damage
	print("[Room " + str(room_id) + "] Sending " + str(damage) + " to player #" + str(player_id))
	
func _ready():
	#start_server()
	start_server_with_websocket()

func _physics_process(delta):
	current_frame += 1
	if current_frame == frames_to_skip: # 1 each 2 seconds
		current_frame = 0
		send_match_rooms()

func _on_peer_connected(peer_id):
	connected_players[peer_id] = -1 # the player is connected, but it is not in a room
	print("User #" + str(peer_id) + " connected")

func _on_peer_disconnected(peer_id):
	var string_peer_id = str(peer_id)
	if !connected_players.has(peer_id):
		return
	var room_id = connected_players[peer_id]
	var match_room = get_match_room(room_id)
	if match_room:
		match_room.leave_room(peer_id)
	connected_players.erase(peer_id)
	print("User #" + string_peer_id + " disconnected")
