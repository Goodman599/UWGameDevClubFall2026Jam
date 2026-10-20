class_name Scrap
extends RigidBody2D

const MIN_SCALE_MODIFIER := 0.9
const MAX_SCALE_MODIFIER := 1.5
const MIN_LAUNCH_VELOCITY := 500.0
const MAX_LAUNCH_VELOCITY := 1000.0
const MIN_ANGULAR_VELOCITY := 10.0
const MAX_ANGULAR_VELOCITY := 25.0

const MAGNETIZE_DELAY := 1.5 # In seconds
var is_magnetizing := false

const ACCELERATION_TO_PLAYER := 1000.0
const TOP_SPEED_TO_PLAYER := 7500.0
var speed_to_player := 0.0
var player_node : Player

var collected := false

@export var is_static := false # Determines if it will launch randomly and magnetize to the player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !is_static:
		launch()
		
		
func launch():
	var rng = RandomNumberGenerator.new()
	var random_launch_angle := rng.randf() * (2 * PI) # Because Godot works in radian
	var random_launch_velocity := rng.randf_range(MIN_LAUNCH_VELOCITY, MAX_LAUNCH_VELOCITY)
	
	override_scale(scale * rng.randf_range(MIN_SCALE_MODIFIER, MAX_SCALE_MODIFIER))
	linear_velocity = Vector2.from_angle(random_launch_angle) * random_launch_velocity
	angular_velocity = rng.randf_range(MIN_ANGULAR_VELOCITY, MAX_ANGULAR_VELOCITY)
	
	await get_tree().create_timer(MAGNETIZE_DELAY).timeout
	magnetize_to_player()


func _physics_process(delta: float) -> void:
	if is_magnetizing:
		if speed_to_player <= TOP_SPEED_TO_PLAYER:
			speed_to_player += ACCELERATION_TO_PLAYER * delta
		
		var vector_to_player : Vector2 = player_node.global_position - global_position
		vector_to_player = vector_to_player.normalized() * speed_to_player
		global_position += vector_to_player * delta
		

func override_scale(new_scale : Vector2) -> void:
	for child in get_children():
		if "scale" in child:
			child.scale *= new_scale

func magnetize_to_player() -> void:
	# Ignore terrain
	set_collision_mask_value(1, false)
	# Ignore all physics
	set_freeze_enabled(true)
	
	player_node = GameManager.player_node
	if player_node:
		is_magnetizing = true
	else:
		print(self, ": Scrap didn't find player!")

func collect() -> void:
	if collected:
		return
	
	GameManager.add_scrap_resource() 
	$ScrapCollectionPlayer.play()
	collected = true
	hide()
	await $ScrapCollectionPlayer.finished
	queue_free()

func _on_player_detection_area_body_entered(body: Node2D) -> void:
	if body is Player:
		collect()
