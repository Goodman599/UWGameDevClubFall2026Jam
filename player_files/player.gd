class_name Player
extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -450.0
const TERMINAL_VELOCITY := 1000.0
const ACCELERATED_TERMINAL_VELOCITY := 1500.0 # Used when holding downwards
const AIR_DRAG := 1000.0 # Used when falling faster than terminal velocity

const MAX_JUMP_HOLD_DURATION = 0.3 # In seconds
const JUMP_HOLD_BOOST := -1500.0
var can_jump_hold := true
var jump_hold_timer := MAX_JUMP_HOLD_DURATION

const COYOTE_WINDOW := 0.15 # In seconds
var can_coyote_jump := false
var coyote_timer := COYOTE_WINDOW
const JUMP_BUFFER_WINODW := 0.1 # In seconds
var can_buffer_jump := false
var jump_buffer_timer := JUMP_BUFFER_WINODW
var was_on_floor_last_frame : bool # Used to start/stop CoyoteTimer and JumpBufferTimer

@export var object_spawn_parent : Node2D
const PLATFORM_PLACE_OFFSET := 150.0
const HORIZONTAL_PLATFORM := preload("res://game_objects/platform_files/horizontal_platform.tscn")
const VERTICAL_PLATFORM := preload("res://game_objects/platform_files/vertical_platform.tscn")
var platform_hologram_H : Platform
var platform_hologram_V : Platform

const BOMB := preload("res://game_objects/bomb_files/bomb.tscn")
const BOMB_PLACE_DISTANCE := 100.0
const BOMB_SURFACE_OFFSET := 4.0
var bomb_target_surface : Node2D = null
var bomb_target_position := Vector2.ZERO
var bomb_target_normal := Vector2.ZERO
var bomb_has_valid_target := false
var placed_bomb : Bomb = null
var applied_velocity := Vector2(0, 0)
const APPLIED_VELOCITY_DRAG := 750.0
const APPLIED_VELOCITY_FRICTION := 1500.0

var last_pressed_direction : Vector2i # {(1, 0), (-1, 0), (0, 1), (0, -1)}, used for immediate press & releases
var aiming_platform := false
var platform_aim_direction := Vector2i(0, 0) # {(1, 0), (-1, 0), (0, 1), (0, -1)}
var aiming_bomb := false
var bomb_aim_direction := Vector2i(0, 0) # {(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (-1, 1), (1, -1)}

func _ready() -> void:
	GameManager.player_node = self
	last_pressed_direction = Vector2(1, 0)

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		fall(delta)
	
	if was_on_floor_last_frame and !is_on_floor() or !was_on_floor_last_frame and is_on_floor():
		on_grounded_state_changed(is_on_floor())
	
	was_on_floor_last_frame = is_on_floor()
	
	# Handle jump.
	if Input.is_action_just_pressed("jump"):
		attempt_jump()
	if can_jump_hold and Input.is_action_pressed("jump"):
		velocity.y += JUMP_HOLD_BOOST * delta
	
	
	# Aim in the direction the player is holding already
	if Input.is_action_just_pressed("up"):
		last_pressed_direction = Vector2i(0, -1)
	elif Input.is_action_just_pressed("right"):
		last_pressed_direction = Vector2i(1, 0)
	elif Input.is_action_just_pressed("down"):
		last_pressed_direction = Vector2i(0, 1)
	elif Input.is_action_just_pressed("left"):
		last_pressed_direction = Vector2i(-1, 0)

	
	
	if Input.is_action_just_pressed("create_platform") and !aiming_bomb and !aiming_platform:
		if GameManager.scrap >= Platform.SCRAP_COST:
			aiming_platform = true
			TimeStop.stop_time()
			create_platform_hologram()
	if Input.is_action_just_pressed("create_bomb") and !aiming_platform and !aiming_bomb:
		if is_instance_valid(placed_bomb):
			placed_bomb.detonate()
			placed_bomb = null
		else:
			if GameManager.scrap >= Bomb.SCRAP_COST:
				aiming_bomb = true
				TimeStop.stop_time()
	if aiming_platform:
		aim_platform()
	if aiming_bomb:
		aim_bomb()
	if Input.is_action_just_released("create_platform") and aiming_platform:
		aiming_platform = false
		TimeStop.resume_time()
		create_platform()
	if Input.is_action_just_released("create_bomb") and aiming_bomb:
		aiming_bomb = false
		TimeStop.resume_time()
		create_bomb()
	
	# If aiming, then all direction inputs must become aiming instead of movement
	if !aiming_bomb and !aiming_platform:
		# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	velocity.x += applied_velocity.x
	move_and_slide()
	velocity.x -= applied_velocity.x
	
	if applied_velocity.x != 0:
		if is_on_floor():
			applied_velocity.x = move_toward(applied_velocity.x, 0, APPLIED_VELOCITY_FRICTION * delta)
		else:
			applied_velocity.x = move_toward(applied_velocity.x, 0, APPLIED_VELOCITY_DRAG * delta)
			
func fall(delta : float):
	var terminal_velocity : float
	if Input.is_action_pressed("down") and !aiming_bomb and !aiming_platform:
		terminal_velocity = ACCELERATED_TERMINAL_VELOCITY
	else:
		terminal_velocity = TERMINAL_VELOCITY
	
	if velocity.y < terminal_velocity:
		velocity += get_gravity() * delta
		
		if velocity.y > terminal_velocity:
			velocity.y = terminal_velocity
	
	else: # If falling faster than terminal velocity, slow down
		velocity.y = move_toward(velocity.y, terminal_velocity, AIR_DRAG * delta)

func attempt_jump() -> void:
	var can_jump := false
	if is_on_floor():
		can_jump = true
	elif can_coyote_jump:
		if velocity.y >= 0: # We only want to allow coyote jumps when falling
							# Imagine bombing up and then jumping, eating all velocity
			can_jump = true
	
	if can_jump:
		velocity.y = JUMP_VELOCITY
		can_coyote_jump = false # Any successful jump means no more coyote jumps 
								# (would be a double jump otherwise)
		can_jump_hold = true
		
		# Force correct
		if TimeStop.is_time_stopped:
			velocity.y += -35.53302002
		
		start_jump_hold_timer()
	else:
		can_buffer_jump = true
		start_jump_buffer_timer()

func on_grounded_state_changed(just_landed : bool):
	if just_landed:
		can_jump_hold = false
		
		if can_buffer_jump:
			can_buffer_jump = false
			attempt_jump()
	else:
		can_coyote_jump = true
		start_coyote_timer()

func apply_velocity(incoming_velocity : Vector2):
	applied_velocity += incoming_velocity
	if incoming_velocity.y < 0:
		velocity.y = incoming_velocity.y
	else:
		velocity.y += incoming_velocity.y

func aim_platform():
	# Record the direction pressed (NESW)
	# Because this is only NESW, we will just take the most recent input
	if Input.is_action_just_pressed("up"):
		if platform_aim_direction.y == 0: # If was a wall before
			if !platform_hologram_H: # If a hologram hasn't been created yet (possible edgecase)
				platform_aim_direction = Vector2i(0, -1)
				create_platform_hologram()
			platform_hologram_V.hide()
			platform_hologram_H.show()
		platform_aim_direction = Vector2i(0, -1)
	elif Input.is_action_just_pressed("right"):
		if platform_aim_direction.x == 0: # If was a floor before
			if !platform_hologram_H: # If a hologram hasn't been created yet (possible edgecase)
				platform_aim_direction = Vector2i(1, 0)
				create_platform_hologram()
			platform_hologram_H.hide()
			platform_hologram_V.show()
		platform_aim_direction = Vector2i(1, 0)
	elif Input.is_action_just_pressed("down"):
		if platform_aim_direction.y == 0: # If was a wall before
			if !platform_hologram_H: # If a hologram hasn't been created yet (possible edgecase)
				platform_aim_direction = Vector2i(0, 1)
				create_platform_hologram()
			platform_hologram_V.hide()
			platform_hologram_H.show()
		platform_aim_direction = Vector2i(0, 1)
	elif Input.is_action_just_pressed("left"):
		if platform_aim_direction.x == 0: # If was a floor before
			if !platform_hologram_H: # If a hologram hasn't been created yet (possible edgecase)
				platform_aim_direction = Vector2i(-1, 0)
				create_platform_hologram()
			platform_hologram_H.hide()
			platform_hologram_V.show()
		platform_aim_direction = Vector2i(-1, 0)
			
	if platform_hologram_H:
		platform_hologram_H.global_position = global_position + platform_aim_direction * PLATFORM_PLACE_OFFSET
		platform_hologram_V.global_position = global_position + platform_aim_direction * PLATFORM_PLACE_OFFSET

func aim_bomb():
	var x := 0
	var y := 0

	if Input.is_action_pressed("left"):
		x -= 1
	if Input.is_action_pressed("right"):
		x += 1
	if Input.is_action_pressed("up"):
		y -= 1
	if Input.is_action_pressed("down"):
		y += 1

	var held_direction := Vector2i(x, y)

	if held_direction != Vector2i.ZERO:
		bomb_aim_direction = held_direction
	elif bomb_aim_direction == Vector2i.ZERO:
		bomb_aim_direction = last_pressed_direction

	if bomb_aim_direction == Vector2i.ZERO:
		bomb_has_valid_target = false
		return

	var direction := Vector2(bomb_aim_direction).normalized()

	var from := global_position
	var to := from + direction * BOMB_PLACE_DISTANCE

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.exclude = [get_rid()]

	var result := get_world_2d().direct_space_state.intersect_ray(query)

	bomb_has_valid_target = false
	bomb_target_surface = null

	if result.is_empty():
		return

	var collider = result["collider"]
	var surface := find_bomb_surface(collider)

	if surface == null:
		return

	bomb_target_surface = surface
	bomb_target_position = result["position"]
	bomb_target_normal = result["normal"]
	bomb_has_valid_target = true

func find_bomb_surface(node: Node) -> Node2D:
	var current := node

	while current != null:
		if current is Platform:
			return current as Node2D

		if current is Node2D and current.is_in_group(&"bomb_surface"):
			return current as Node2D

		current = current.get_parent()

	if node.owner is Platform:
		return node.owner as Node2D

	return null

func create_platform_hologram():
	if platform_aim_direction == Vector2i(0, 0):
		if last_pressed_direction == Vector2i(0, 0):
			return
		platform_aim_direction = last_pressed_direction
	
	platform_hologram_V = VERTICAL_PLATFORM.instantiate()
	platform_hologram_H = HORIZONTAL_PLATFORM.instantiate()
	
	
	platform_hologram_V.object_spawn_parent = object_spawn_parent
	object_spawn_parent.add_child(platform_hologram_V)
	platform_hologram_V.set_hologram(true)
	
	platform_hologram_H.object_spawn_parent = object_spawn_parent
	object_spawn_parent.add_child(platform_hologram_H)
	platform_hologram_H.set_hologram(true)
	
	if platform_aim_direction.x == 0: # No X offset aka directly above/below
		platform_hologram_V.hide()
	else:
		platform_hologram_H.hide()
	
func create_platform():
	if !platform_hologram_H: # No hologram was generated in the first palce (edgecase)
		return
		
	if platform_aim_direction.x == 0: # No X offset aka directly above/below
		if platform_hologram_H.valid_hologram:
			platform_hologram_H.set_hologram(false)
			GameManager.remove_scrap_resource(Platform.SCRAP_COST)
		else:
			platform_hologram_H.queue_free()
		platform_hologram_V.queue_free()
	else:
		if platform_hologram_V.valid_hologram:
			platform_hologram_V.set_hologram(false)
			GameManager.remove_scrap_resource(Platform.SCRAP_COST)
		else:
			platform_hologram_V.queue_free()
		platform_hologram_H.queue_free()
		
	# Reset for the next place
	platform_hologram_H = null
	platform_hologram_V = null
	platform_aim_direction = Vector2i(0, 0)
	
	

func create_bomb():
	if !bomb_has_valid_target:
		reset_bomb_aim()
		return

	if bomb_target_surface == null:
		reset_bomb_aim()
		return
	
	if GameManager.scrap < Bomb.SCRAP_COST:
		reset_bomb_aim()
		return
	
	var bomb := BOMB.instantiate() as Bomb

	bomb_target_surface.add_child(bomb)

	# Immediately put the actual bomb at its final gameplay position.
	bomb.global_position = (
		bomb_target_position
		+ bomb_target_normal * BOMB_SURFACE_OFFSET
	)

	# Rotate the bomb to match the surface.
	bomb.global_rotation = bomb_target_normal.angle() + PI / 2.0

	# Store which direction the surface faces.
	bomb.surface_normal = bomb_target_normal.normalized()

	# Give the bomb access to the player.
	bomb.player = self

	# Only animate the visual sprite.
	bomb.play_placement_animation()

	placed_bomb = bomb

	GameManager.remove_scrap_resource(Bomb.SCRAP_COST)

	reset_bomb_aim()

func reset_bomb_aim():
	bomb_aim_direction = Vector2i.ZERO
	bomb_target_surface = null
	bomb_target_position = Vector2.ZERO
	bomb_target_normal = Vector2.ZERO
	bomb_has_valid_target = false

func start_coyote_timer() -> void:
	coyote_timer = COYOTE_WINDOW
	while coyote_timer > 0.002: # Yes this is a magic number. No you cannot touch it
		coyote_timer -= get_physics_process_delta_time()
		await get_tree().physics_frame
	can_coyote_jump = false


func start_jump_buffer_timer() -> void:
	jump_buffer_timer = JUMP_BUFFER_WINODW
	while jump_buffer_timer > 0.002: # Yes this is a magic number. No you cannot touch it
		jump_buffer_timer -= get_physics_process_delta_time()
		await get_tree().physics_frame
	can_buffer_jump = false


func start_jump_hold_timer() -> void:
	jump_hold_timer = MAX_JUMP_HOLD_DURATION
	while jump_hold_timer > 0.002: # Yes this is a magic number. No you cannot touch it
		jump_hold_timer -= get_physics_process_delta_time()
		await get_tree().physics_frame
	can_jump_hold = false
	
	# Force correct
	if TimeStop.is_time_stopped:
		velocity.y += -19.99952698
		
# called when growing tree
# turns off physics process until tree is finished growing
# ends bomb/platform placement if currently placing
func tree_growing() -> void:			
	set_physics_process(false)
	if aiming_platform:
		if platform_hologram_H:
			platform_hologram_H.valid_hologram = false
		elif platform_hologram_V:
			platform_hologram_V.valid_hologram = false
		create_platform()
		aiming_platform = false
	if aiming_bomb:
		bomb_has_valid_target = false
		create_bomb()
		aiming_bomb = false
	TimeStop.resume_time(true)

# called when tree is finished growing
# turns back on physics process
func tree_finished() -> void:
	set_physics_process(true)
	
