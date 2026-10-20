class_name GameCamera
extends Camera2D

@export var shake_strength := 12.0
@export var shake_decay := 100.0

var shake_amount := 0.0


func _process(delta):
	shake_amount = move_toward(shake_amount, 0.0, shake_decay * delta)

	offset = Vector2(
		randf_range(-shake_amount, shake_amount),
		randf_range(-shake_amount, shake_amount)
	)


func shake(strength := shake_strength):
	shake_amount = max(shake_amount, strength)
