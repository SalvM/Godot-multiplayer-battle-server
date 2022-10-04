extends Node

func create_new_match_room():
	return {
	"status": "waiting",
	"players": {}
}

func fetch_player_damage():
	return 10

func _ready():
	pass 
