class_name Platform
extends Node2D

const SCRAP_REFUND := 3
const SCRAP_SCENE := preload("res://game_objects/scrap_files/scrap_metal.tscn")

var object_spawn_parent : Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ExplodableComponent.explode.connect(destroy)

func destroy() -> void:
	spawn_scrap(SCRAP_REFUND)
	queue_free()

func spawn_scrap(count : int) -> void:
	if !object_spawn_parent:
		print(self, ": Platform does not have a reference to the object_spawn_parent!")
		return
	
	for i in range(count):
		var new_scrap = SCRAP_SCENE.instantiate()
		new_scrap.global_position = global_position
		object_spawn_parent.call_deferred("add_child", new_scrap)
		
