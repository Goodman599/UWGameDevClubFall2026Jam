class_name ScrapUI
extends CanvasLayer

func _ready() -> void:
	GameManager.scrap_ui = self

# adds scrap to the counter, should only be done through the game manager
func add_scrap_resource(amount: int = 1) -> void:
	pass #TODO
	
# removes scrap from the counter, should only be done through the game manager
func remove_scrap_resource(amount: int = 1) -> void:
	pass #TODO
	
# sets the amount of scrap for the counter, should only be done through the game manager
func set_scrap_resource(amount: int) -> void:
	pass #TODO
