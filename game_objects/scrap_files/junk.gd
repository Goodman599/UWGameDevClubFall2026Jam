class_name Junk
extends Node2D

@export var scrap_amount := 1
@export var object_spawn_parent : Node2D
@export var explodable_component : ExplodableComponent

const SCRAP_SCENE := preload("res://game_objects/scrap_files/scrap_metal.tscn")

var destroyed := false

func _ready() -> void:
	$ExplodableComponent.explode.connect(destroy)


func destroy():
	if destroyed:
		return
	
	var collision_shape = $ExplodableComponent/ExplosionDetectionArea/CollisionShape2D

	# 1. Get the bounding rect in local shape space
	var rect = collision_shape.shape.get_rect()
	for i in range(scrap_amount):
		# 2. Pick a random X and Y inside that rect
		var x = randf_range(rect.position.x, rect.position.x + rect.size.x)
		var y = randf_range(rect.position.y, rect.position.y + rect.size.y)
		var local_point = Vector2(x, y)

		# 3. Correctly convert the local point to global space (respects position, rotation, & scale)
		var rand_point = collision_shape.to_global(local_point)

		# 4. Instantiate and add to parent FIRST, then set global position
		var new_scrap = SCRAP_SCENE.instantiate()
		
		object_spawn_parent.add_child(new_scrap)
		
		new_scrap.global_position = rand_point
	
	destroyed = true
	$DestructionPlayer.play()
	hide()

func respawn():
	destroyed = false
	show()
