extends Node

var world_state

func _physics_process(delta):
	if not get_parent().puppets.empty():
		world_state = get_parent().puppets.duplicate(true)
		for player_id in world_state.keys():
			world_state[player_id].erase("T")
		world_state["T"] = OS.get_system_time_msecs()
		# Verifications
		# Anti-Cheat
		# Cuts ( chunkings / maps )
		# Physics checks
		get_parent().send_world_state(world_state)
