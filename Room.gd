extends Node

"""
This room will contain only the data needed for
those who play inside of it
"""
enum RoomState { WAITING, STARTED, FINISHED }

onready var processing = $StateProcessing

var max_players = 2
var state = RoomState.WAITING

const puppets = {}

func is_player_in_room(player_id) -> bool:
	return puppets.has(player_id)

func get_players_number() -> int:
	return puppets.keys().size()

func is_room_full() -> bool:
	return get_players_number() == max_players

func can_join_room() -> bool:
	return state == RoomState.WAITING && !is_room_full()

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

func join_room(player_id):
	if !can_join_room():
		return
	puppets[player_id] = default_puppet()
	if is_room_full():
		get_node("/root/Server").load_battlefields(self.name)
		processing.synch = true # the room will start sending state

func leave_room(player_id):
	if puppets.has(player_id):
		puppets.erase(player_id)
		if get_players_number() == 0:
			processing.synch = false # the room will stop sending state

func room_status():
	return {
		"id": self.name,
		"status": RoomState.keys()[state],
		"players": puppets.keys()
	}

func send_room_state(room_state):
	get_node("/root/Server").send_room_state(room_state, puppets.keys())

func _ready():
	pass
