extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 2
var puppets = {}
var randomizer = RandomNumberGenerator.new()

func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	printt("Server started at port", port)
	
	network.connect("peer_connected", self, "_on_peer_connected")
	network.connect("peer_disconnected", self, "_on_peer_disconnected")

remote func user_load_battlefield(peer_id):
	rpc_id(peer_id, "user_load_battlefield", peer_id)

remote func user_spawn_puppet(peer_id, is_player_puppet):
	randomizer.randomize()
	var x_coordinates = randomizer.randi_range(100, 900)
	rpc_id(peer_id, "user_spawn_puppet", peer_id, x_coordinates, is_player_puppet)

remote func register_player(peer_id):
	var id = get_tree().get_rpc_sender_id()
	puppets[peer_id] = null
	printt('New player registered on server', id)
	print(puppets)

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
	rpc_id(peer_id, "user_load_battlefield", peer_id)
	
func _on_peer_disconnected(peer_id):
	print("User #" + str(peer_id) + " disconnected")
	puppets.erase(peer_id)
