extends Node

"""
The player can attack if:
	- He has the right amount of stamina
	- He waited for the cooldown of the attack
	- He is on the floor // we will skip this
@prev_player_state must be the exactly previous player state before the new one
@future_player_state the next player state to calculate, so the T is greater
"""
func can_attack(prev_player_state, future_player_state) -> bool:
	if prev_player_state["B"][1] < Fight.basic_attack_cost():
		printt("Player cannot attack because of stamina", prev_player_state["B"][1])
		return false
	var waited_time = future_player_state["T"] - prev_player_state["anti_cheat"]["last_attack_ms"]
	var time_to_wait = 0
	match future_player_state["S"]:
		5: # quick_attack
			time_to_wait = Fight.quick_attack_cooldown()
		6: # charged_attack
			time_to_wait = Fight.charged_attack_cooldown()
		_:
			time_to_wait = Fight.quick_attack_cooldown()
	if waited_time < time_to_wait:
		printt("Player cannot attack because of time", waited_time)
		return false
	return true

"""
The player can dash if:
	- He has the right amount of dashes stacks
	- He waited for the cooldown of the dash animation
@prev_player_state must be the exactly previous player state before the new one
@future_player_state the next player state to calculate, so the T is greater
"""
func can_dash(prev_player_state, future_player_state) -> bool:
	if prev_player_state["B"][2] < 1:
		return false
	var waited_time = future_player_state["T"] - prev_player_state["anti_cheat"]["last_dash_ms"]
	var time_to_wait = 0.1 * 1000
	if waited_time < time_to_wait:
		return false
	return true

func is_dead(future_player_state) -> bool:
	return future_player_state["B"][0] <= 0

func on_player_cheating(player_id, prev_state, future_state) -> void:
	print("The player #" + str(player_id) + " is cheating! Call the internet police!")
	future_state["S"] = prev_state["S"] # prevent the cheater to change the status
	future_state["P"] = prev_state["P"] # ... and position
	# TODO: Black list the user and/or suspend the match

func _ready():
	pass
