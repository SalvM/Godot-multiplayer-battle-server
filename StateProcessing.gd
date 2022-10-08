extends Node

var world_state

func _physics_process(delta):
	if get_parent().puppets.empty():
		return
	if get_parent().match_room.status != "started":
		return
	world_state = get_parent().puppets.duplicate(true)
	for player_id in world_state.keys():
		world_state[player_id].erase("T")
		world_state[player_id].erase("anti_cheat")
	world_state["T"] = OS.get_system_time_msecs()
	# Verifications
	# Anti-Cheat
	# Cuts ( chunkings / maps )
	# Physics checks
	get_parent().send_world_state(world_state)
