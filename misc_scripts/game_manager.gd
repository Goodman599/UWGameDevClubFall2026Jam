extends Node

var player_node : CharacterBody2D = null
var map_node : Map 
var scrap : int
var scrap_ui : ScrapUI


func _ready() -> void:
	scrap = 0
	

# adds scrap to the counter
func add_scrap_resource(amount: int = 1) -> void:
	scrap += amount
	scrap_ui.add_scrap_resource(amount)
	
# removes scrap from the counter
func remove_scrap_resource(amount: int = 1) -> void:
	scrap -= amount
	scrap_ui.remove_scrap_resource(amount)
	
# sets the amount of scrap for the counter
func set_scrap_resource(amount: int) -> void:
	scrap = amount
	scrap_ui.set_scrap_resource(amount)

func kill_player():
	map_node.on_player_death()
