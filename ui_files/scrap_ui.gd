class_name ScrapUI
extends CanvasLayer
var scrap: int

const FONT_SIZE = 50


func _ready() -> void:
	GameManager.scrap_ui = self
	$ScrapCounter.push_font_size(FONT_SIZE)
	set_scrap_resource(GameManager.scrap)
	# $ScrapCounter.push_font(FONT)

# adds scrap to the counter, should only be done through the game manager
func add_scrap_resource(amount: int = 1) -> void:
	scrap += amount
	$ScrapCounter.text = "x" + str(scrap)
	$ScrapIcon.show()
	$ScrapCounter.show()
	
# removes scrap from the counter, should only be done through the game manager
func remove_scrap_resource(amount: int = 1) -> void:
	scrap -= amount
	$ScrapCounter.text = "x" + str(scrap)
	if scrap == 0:
		$ScrapIcon.hide()
		$ScrapCounter.hide()

# sets the amount of scrap for the counter, should only be done through the game manager
func set_scrap_resource(amount: int) -> void:
	scrap = amount
	$ScrapCounter.text = "x" + str(scrap)
	
	if scrap == 0:
		$ScrapIcon.hide()
		$ScrapCounter.hide()
	else:
		$ScrapIcon.show()
		$ScrapCounter.show()
