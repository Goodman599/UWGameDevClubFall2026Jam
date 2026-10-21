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

const SPROUT_SPRITE_Y = 64
const TREE_SPRITE_Y = 16

var display_fade_tween : Tween

@onready var score_req_display : Label = $ScoreReqDisplay
@onready var not_enough_scrap_display_bg : ColorRect = $NotEnoughScrapDisplayBG
@onready var not_enough_scrap_display : Label = $NotEnoughScrapDisplayBG/NotEnoughScrapDisplay
@onready var sprite : AnimatedSprite2D = $TreeSprite

func _ready() -> void:				
	sprite.play("sprout")
	sprite.position.y = SPROUT_SPRITE_Y
	player_node = GameManager.player_node
	score_req_display.text = "0/" + str(perfect_score_threshold)
	not_enough_scrap_display_bg.hide()

func _process(delta: float) -> void:
	
	if player_touching and grow_cooldown <= 0:
		if GameManager.scrap > 1: # depositing scrap
			GameManager.remove_scrap_resource(1)
			score += 1
			score_req_display.text = str(score) + "/" + str(perfect_score_threshold)
			grow_cooldown += 1 / GROW_RATE
			# TODO sound effect
			if score < perfect_score_threshold:
				sprite.play("tree")
				sprite.position.y = TREE_SPRITE_Y
			if score != perfect_score_threshold or has_bloomed:
				$DepositPlayer.play()
			
			if score == perfect_score_threshold: # deposit process finished
				if perfect_score_threshold <= score and !has_bloomed:
					has_bloomed = true
					sprite.play("blossoming_tree")
					sprite.position.y = TREE_SPRITE_Y
					$RewardPlayer.play()
					GameManager.fruit_ui.add_fruit()
			
			if GameManager.scrap == 1:
				player_node.tree_finished()
				player_touching = false
	
	if grow_cooldown > 0:
		grow_cooldown -= delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and enabled:
		if GameManager.scrap > 1:
			player_touching = true
			player_node.tree_growing()
			if laser_door:
				laser_door.fade()
			
			if display_fade_tween:
				display_fade_tween.kill()
			display_fade_tween = create_tween()
			display_fade_tween.tween_property(score_req_display, "self_modulate:a", 1.0, 0.5)
		else:
			if GameManager.scrap == 0:
				not_enough_scrap_display.text = "You have no scrap to deposit! Press R to restart!"
				not_enough_scrap_display.add_theme_font_size_override("font_size", 48)
				not_enough_scrap_display_bg.show()
			elif GameManager.scrap == 1:
				not_enough_scrap_display.text = "You need to keep this piece of scrap to bring into the next level!"
				not_enough_scrap_display.add_theme_font_size_override("font_size", 42)
				not_enough_scrap_display_bg.show()
		
		
func _on_area_2d_body_exited(body: Node2D, instant := false) -> void:
	if body is Player:
		#player_touching = false
		
		if display_fade_tween:
			display_fade_tween.kill()
		if instant:
			score_req_display.self_modulate.a = 0.0
		else:
			display_fade_tween = create_tween()
			display_fade_tween.tween_property(score_req_display, "self_modulate:a", 0.0, 1.0)
	not_enough_scrap_display_bg.hide()
	
func reset() -> void:
	score = 0
	score_req_display.text = str(score) + "/" + str(perfect_score_threshold)
	_on_area_2d_body_exited(player_node, true)
	enabled = true
	if !has_bloomed:
		sprite.play("sprout")
		sprite.position.y = SPROUT_SPRITE_Y
	if laser_door:
		laser_door.appear()
