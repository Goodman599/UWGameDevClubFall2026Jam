@tool
class_name LaserDoor
extends NinePatchRect

@export var collision_shape: CollisionShape2D

const FADE_DURATION := 1.0
var fade_tween : Tween

func _notification(what: int) -> void:
	# Triggers automatically whenever the Control's size or rect changes
	if what == NOTIFICATION_RESIZED:
		_update_collision_shape()

func _update_collision_shape() -> void:
	size.x = 64
	
	if not collision_shape or not collision_shape.shape:
		return
	
	# If your collision shape is a RectangleShape2D, match its size directly to the NinePatchRect
	if collision_shape.shape is RectangleShape2D:
		collision_shape.shape.size = size / 4.0
		collision_shape.shape.size.x -= 40
		
		# Optional: If your collision shape is offset from the center, 
		# you can center it automatically by setting its position to half the size:
		collision_shape.position = size / 8.0

func fade():
	fade_tween = get_tree().create_tween()
	fade_tween.tween_property(self, "self_modulate:a", 0, FADE_DURATION)
	await fade_tween.finished
	$LaserDoor.set_process_mode(PROCESS_MODE_DISABLED)
	hide()
	
	
func appear():
	if fade_tween:
		fade_tween.kill()
	self_modulate.a = 1.0
	$LaserDoor.set_process_mode(PROCESS_MODE_INHERIT)
	show()
