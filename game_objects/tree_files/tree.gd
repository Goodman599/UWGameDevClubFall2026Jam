class_name JunkTree
extends Node2D

var score := 0
var perfect_score_threshold := 1
const GROW_RATE : float = 2 # how fast the tree grows in scrap per second 
var player_node : Player
var enabled := true # tree will be turned off if the player enters from the wrong direction or with more than one scrap

var player_touching := false
var grow_cooldown := 0.0
var fully_bloomed := false

func _ready() -> void:				
	$AnimatedSprite2D.play("sprout")
	player_node = GameManager.player_node

func _process(delta: float) -> void:
	if player_touching and grow_cooldown <= 0 and enabled:
		if GameManager.scrap <= 1: # deposit process finished
			player_node.tree_finished()
			if perfect_score_threshold <= score:
				$AnimatedSprite2D.play("blossoming_tree")
				$RewardPlayer.play()
		else: # depositing scrap
			player_node.tree_growing()
			GameManager.remove_scrap_resource(1)
			score += 1
			grow_cooldown += 1 / GROW_RATE
			# TODO sound effect
			if score < perfect_score_threshold:
				$AnimatedSprite2D.play("tree")
				$DepositPlayer.play()
	if grow_cooldown > 0:
		grow_cooldown -= delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		player_touching = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		player_touching = false

func set_perfect_score_threshold(threshold: int) -> void:
	perfect_score_threshold = threshold
	
func reset() -> void:
	score = 0
	enabled = true
	$AnimatedSprite2D.play("sprout")

func disable() -> void:
	enabled = false
