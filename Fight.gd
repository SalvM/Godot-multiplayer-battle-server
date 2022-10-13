extends Node

var randomizer = RandomNumberGenerator.new()


func create_new_match_room():
	return {
	"status": "waiting",
	"players": {}
}

func fetch_player_damage():
	return 25
	
func basic_attack_cost():
	return 20

func quick_attack_cooldown():
	return 0.4 * 1000
	
func charged_attack_cooldown():
	return 0.6 * 1000
	
func random_puppet_position():
	randomizer.randomize()
	return randomizer.randi_range(100, 900)

func default_puppet_bar():
	return [100, 80, 3]

func _ready():
	pass 
