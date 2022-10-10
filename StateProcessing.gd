extends Node

var room_state

"""
You can decide how many times per seconds 
the server will send the word status to
the clients.
"""
const FPS = 20
const frames_to_skip = 60 / FPS
var current_frame = 0

var synch = false # the parent will turn it on when the match can start

func _physics_process(delta):
	if !synch:
		return
	current_frame += 1
	if current_frame == frames_to_skip:
		current_frame = 0
		if get_parent().puppets.empty():
			return
		room_state = get_parent().puppets.duplicate(true)
		for player_id in room_state.keys():
			room_state[player_id].erase("T")
			room_state[player_id].erase("anti_cheat")
		room_state["T"] = OS.get_system_time_msecs()
		# Verifications
		# Anti-Cheat
		# Cuts ( chunkings / maps )
		# Physics checks
		get_parent().send_room_state(room_state)
