class_name Bomb
extends Node2D

const SCRAP_COST := 1

@export var explosion_radius := 100.0
@export var player_launch_speed := 800.0

var surface_normal := Vector2.ZERO
var player: Player = null
const EXPLOSION := preload("res://game_objects/bomb_files/explosion.tscn")

@onready var sprite: Sprite2D = $Sprite2D

func detonate():
	var camera := get_viewport().get_camera_2d()

	if camera is GameCamera:
		camera.shake(16.0)
		
	var circle := CircleShape2D.new()
	circle.radius = explosion_radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var results := get_world_2d().direct_space_state.intersect_shape(query)

	var already_exploded: Array[Node] = []

	for result in results:
		var collider := result["collider"] as Node

		# Explode anything with an ExplodableComponent.
		var target := find_explodable_parent(collider)

		if target != null and target not in already_exploded:
			already_exploded.append(target)

			var component := find_explodable_component(target)

			if component != null:
				component.exploded()

		# Launch the player if they're inside the blast.
		if player != null and is_node_or_parent(collider, player):
			player.apply_velocity(surface_normal * player_launch_speed)
	
	var new_explosion = EXPLOSION.instantiate()
	new_explosion.hide()
	new_explosion.global_position = self.global_position
	player.object_spawn_parent.add_child(new_explosion)
	$ExplodePlayer.play()
	hide()
	await $ExplodePlayer.finished
	queue_free()


func find_explodable_parent(node: Node) -> Node:
	var current := node

	while current != null:
		if find_explodable_component(current) != null:
			return current

		current = current.get_parent()

	return null


func find_explodable_component(node: Node) -> ExplodableComponent:
	for child in node.get_children():
		if child is ExplodableComponent:
			return child as ExplodableComponent

	return null


func is_node_or_parent(node: Node, target: Node) -> bool:
	var current := node

	while current != null:
		if current == target:
			return true

		current = current.get_parent()

	return false

func play_placement_animation() -> void:
	# Start the sprite slightly away from the surface.
	sprite.position = Vector2(0.0, -20.0)

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		sprite,
		"position",
		Vector2.ZERO,
		0.12
	)
	
	$PlacementPlayer.play()
