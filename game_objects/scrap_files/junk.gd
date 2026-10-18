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
	
	for i in range(scrap_amount):
		var new_scrap = SCRAP_SCENE.instantiate()
		
		object_spawn_parent.add_child(new_scrap)
		new_scrap.global_position = global_position
	
	destroyed = true
	hide()

func respawn():
	destroyed = false
	show()
