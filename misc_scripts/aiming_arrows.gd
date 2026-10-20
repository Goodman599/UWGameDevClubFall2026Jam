extends Node2D

var last_arrow : Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disappear()

func show_orthogonal():
	$Orthogonal.show()

func show_diagonal():
	show_orthogonal()
	$Diagonal.show()

func disappear():
	$Orthogonal.hide()
	$Diagonal.hide()
	reset()

func make_blue(arrow : Sprite2D):
	if arrow:
		arrow.material.set_shader_parameter("enabled", false)
	
func make_last_white():
	#return
	if last_arrow:
		last_arrow.material.set_shader_parameter("enabled", true)

func highlight(direction : Vector2i):
	var arrow : Sprite2D
	match direction:
		Vector2i(1, 0):
			arrow = $Orthogonal/E
		Vector2i(1, 1):
			arrow = $Diagonal/SE
		Vector2i(0, 1):
			arrow = $Orthogonal/S
		Vector2i(-1, 1):
			arrow = $Diagonal/SW
		Vector2i(-1, 0):
			arrow = $Orthogonal/W
		Vector2i(-1, -1):
			arrow = $Diagonal/NW
		Vector2i(0, -1):
			arrow = $Orthogonal/N
		Vector2i(1, -1):
			arrow = $Diagonal/NE
	
	make_blue(arrow)
	if arrow != last_arrow:
		make_last_white()
		last_arrow = arrow

func reset():
	for arrow : Sprite2D in $Orthogonal.get_children():
		arrow.material.set_shader_parameter("enabled", true)
	for arrow : Sprite2D in $Diagonal.get_children():
		arrow.material.set_shader_parameter("enabled", true)
