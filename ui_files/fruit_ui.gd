class_name FruitUI
extends CanvasLayer
var fruit: int

const FONT_SIZE = 64
const TOTAL_FRUITS = 24

func _ready() -> void:
	GameManager.fruit_ui = self
	$FruitCounter.push_font_size(FONT_SIZE)
	set_fruit(0)
	# $ScrapCounter.push_font(FONT)

# adds scrap to the counter, should only be done through the game manager
func add_fruit(amount: int = 1) -> void:
	fruit += amount
	$FruitCounter.text = str(fruit) + "/" + str(TOTAL_FRUITS)
	
# removes scrap from the counter, should only be done through the game manager
func remove_fruit(amount: int = 1) -> void:
	fruit -= amount
	$FruitCounter.text = str(fruit) + "/" + str(TOTAL_FRUITS)
		
# sets the amount of scrap for the counter, should only be done through the game manager
func set_fruit(amount: int) -> void:
	fruit = amount
	$FruitCounter.text = str(fruit) + "/" + str(TOTAL_FRUITS)
