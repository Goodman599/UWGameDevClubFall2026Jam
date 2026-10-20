class_name Platform
extends Node2D

const SCRAP_COST := 4
const SCRAP_REFUND := 3
const SCRAP_SCENE := preload("res://game_objects/scrap_files/scrap_metal.tscn")

var object_spawn_parent : Node2D

var is_hologram := false
var valid_hologram : bool
var is_destroyed := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ExplodableComponent.explode.connect(destroy)
	$HologramSprite.hide()

func set_hologram(value : bool):
	is_hologram = value
	if is_hologram:
		$CollisionBox.set_process_mode(PROCESS_MODE_DISABLED)
		
		$PlatformSprite.hide()
		
		# The Detection area doesn't update until the frame after the hologram is spawned in
		await get_tree().physics_frame
		
		$HologramSprite.show()
		
		if $HologramDetectionArea.get_overlapping_bodies().is_empty():
			valid_hologram = true
			$HologramSprite.self_modulate = Color(0, 1, 0, 0.5)
		else:
			valid_hologram = false
			$HologramSprite.self_modulate = Color(1, 0, 0, 0.5)
			$PlacementPlayer.play()
			
	else:
		$CollisionBox.set_process_mode(PROCESS_MODE_INHERIT)
		$HologramSprite.hide()
		$PlatformSprite.show()


func destroy() -> void:
	if !is_hologram and !is_destroyed:
		is_destroyed = true
		spawn_scrap(SCRAP_REFUND)
		$DestructionPlayer.play()
		hide()
		await $DestructionPlayer.finished
		queue_free()

func spawn_scrap(count : int) -> void:
	if !object_spawn_parent:
		print(self, ": Platform does not have a reference to the object_spawn_parent!")
		return
	
	var scrap_scene = load("res://game_objects/scrap_files/scrap_metal.tscn") # using SCRAP_SCENE breaks this. IDK why.
	for i in range(count):
		var rect : Rect2 = $CollisionBox/CollisionShape2D.shape.get_rect()
		var x = randf_range(rect.position.x, rect.position.x + rect.size.x)
		var y = randf_range(rect.position.y, rect.position.y + rect.size.y)
		var rand_point = global_position + Vector2(x, y)
		var new_scrap = scrap_scene.instantiate() # using SCRAP_SCENE breaks this. IDK why.
		new_scrap.global_position = rand_point
		object_spawn_parent.add_child(new_scrap)



func _on_hologram_detection_area_body_entered(_body: Node2D) -> void:
	valid_hologram = false
	$HologramSprite.self_modulate = Color(1, 0, 0, 0.5)


func _on_hologram_detection_area_body_exited(_body: Node2D) -> void:
	if $HologramDetectionArea.get_overlapping_bodies().is_empty():
		valid_hologram = true
		$HologramSprite.self_modulate = Color(0, 1, 0, 0.5)
