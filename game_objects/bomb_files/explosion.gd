class_name Explosion
extends Node2D

const RADIUS := 150.0 # radius of regular size, in pixels TODO
const BLACK_THICKNESS := 0.003
const BLUE_THICKNESS := 0.03
const LIFETIME := 0.14 # in seconds
const FINAL_OPACITY := 0.5 # scale of 0 to 1
const SPRITE_RADIUS := 250.0 # radius of sprite the shader covers

var current_scale : float
var lifetime : float

func _ready() -> void:
	current_scale = 0.00
	show()
	lifetime = LIFETIME

func _process(delta):
	current_scale += delta / LIFETIME 
	$Sprite2D.scale = Vector2(current_scale, current_scale) * RADIUS / SPRITE_RADIUS
	# opacity currently not working
	$Sprite2D.material.set_shader_parameter("opacity", 1.0 + (FINAL_OPACITY - 1.0) * current_scale)
	$Sprite2D.material.set_shader_parameter("blue_thickness", BLUE_THICKNESS / current_scale)
	$Sprite2D.material.set_shader_parameter("black_thickness", BLACK_THICKNESS / current_scale)
	lifetime -= delta
	if (lifetime < 0):
		queue_free()
