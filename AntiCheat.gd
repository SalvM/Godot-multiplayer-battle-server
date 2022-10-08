extends Node

"""
The player can attack if:
	- He has the right amount of stamina
	- He waited for the cooldown of the attack
	- He is on the floor // we will skip this
@prev_player_state must be the exactly previous player state before the new one
@future_player_state the next player state to calculate
"""
func can_attack(prev_player_state, future_player_state) -> bool:
	if prev_player_state["B"][1] < Fight.basic_attack_cost():
		return false
	if future_player_state["T"] < prev_player_state["T"]: # TODO
		return false
	return true

func _ready():
	pass
