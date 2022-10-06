extends Node

var randomizer = RandomNumberGenerator.new()

func create_new_match_room():
	return {
	"status": "waiting",
	"players": {}
}

func fetch_player_damage():
	return 10
	
func basic_attack_cost():
	return 20
	
func random_puppet_position():
	randomizer.randomize()
	return randomizer.randi_range(100, 900)

func _ready():
	pass 
