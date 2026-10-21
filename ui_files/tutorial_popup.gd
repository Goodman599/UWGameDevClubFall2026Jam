extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		show()
	


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		hide()
