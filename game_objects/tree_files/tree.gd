class_name JunkTree
extends Node2D

var score := 0
var perfect_score_threshold := 1 # will be assigned by the room
const GROW_RATE : float = 2 # how fast the tree grows in scrap per second 
var player_node : Player
var enabled := true # tree will be turned off if the player enters from the wrong direction or with more than one scrap

var player_touching := false
var grow_cooldown := 0.0
var fully_bloomed := false

var has_bloomed := false
@export var laser_door : LaserDoor

func _ready() -> void:				
	$AnimatedSprite2D.play("sprout")
	player_node = GameManager.player_node

func _process(delta: float) -> void:
	
	if player_touching and grow_cooldown <= 0 and enabled:
		if GameManager.scrap > 1: # depositing scrap
			GameManager.remove_scrap_resource(1)
			score += 1
			grow_cooldown += 1 / GROW_RATE
			# TODO sound effect
			if score < perfect_score_threshold:
				$AnimatedSprite2D.play("tree")
				$DepositPlayer.play()
			
			if GameManager.scrap == 1: # deposit process finished
				player_node.tree_finished()
				if perfect_score_threshold <= score and !has_bloomed:
					has_bloomed = true
					$AnimatedSprite2D.play("blossoming_tree")
					$RewardPlayer.play()
					GameManager.fruit_ui.add_fruit()
	if grow_cooldown > 0:
		grow_cooldown -= delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and GameManager.scrap > 1:
		player_touching = true
		player_node.tree_growing()
		if laser_door:
			laser_door.fade()
		print("====")
		print(player_touching)
		print(grow_cooldown <= 0)
		print(enabled)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		player_touching = false
	
func reset() -> void:
	print("tree reset")
	score = 0
	enabled = true
	$AnimatedSprite2D.play("sprout")
	if laser_door:
		laser_door.appear()
