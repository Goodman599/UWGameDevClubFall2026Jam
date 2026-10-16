class_name Player
extends CharacterBody2D

const SPEED := 300.0
const JUMP_VELOCITY := -650.0
const TERMINAL_VELOCITY := 1000.0
const ACCELERATED_TERMINAL_VELOCITY := 1500.0 # Used when holding downwards
const AIR_DRAG := 10.0 # Used when falling faster than terminal velocity

const MAX_JUMP_HOLD_DURATION = 0.5 # In seconds
const JUMP_HOLD_BOOST := -1000.0
var can_jump_hold := true

const COYOTE_WINDOW := 0.15 # In seconds
var can_coyote_jump := false
const JUMP_BUFFER_WINODW := 0.1 # In seconds
var can_buffer_jump := false
var was_on_floor_last_frame : bool # Used to start/stop CoyoteTimer and JumpBufferTimer

@export var object_spawn_parent : Node2D
const PLATFORM_PLACE_OFFSET := 150.0
const HORIZONTAL_PLATFORM := preload("res://game_objects/platform_files/horizontal_platform.tscn")
const VERTICAL_PLATFORM := preload("res://game_objects/platform_files/vertical_platform.tscn")
var platform_hologram_H : Platform
var platform_hologram_V : Platform

var last_pressed_direction : Vector2i # {(1, 0), (-1, 0), (0, 1), (0, -1)}, used for immediate press & releases
var aiming_platform := false
var platform_aim_direction := Vector2i(0, 0) # {(1, 0), (-1, 0), (0, 1), (0, -1)}
var aiming_bomb := false
var bomb_aim_direction := Vector2i(0, 0) # {(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (-1, 1), (1, -1)}

func _ready() -> void:
	GameManager.player_node = self

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
		aiming_platform = true
		TimeStop.stop_time()
		create_platform_hologram()
	if Input.is_action_just_pressed("create_bomb") and !aiming_platform and !aiming_bomb:
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

	move_and_slide()

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
		velocity.y = move_toward(velocity.y, terminal_velocity, AIR_DRAG)

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
		$JumpHoldTimer.wait_time = MAX_JUMP_HOLD_DURATION
		$JumpHoldTimer.start()
	else:
		$JumpBufferTimer.wait_time = JUMP_BUFFER_WINODW
		can_buffer_jump = true
		$JumpBufferTimer.start()

func on_grounded_state_changed(just_landed : bool):
	if just_landed:
		can_jump_hold = false
		
		if can_buffer_jump:
			can_buffer_jump = false
			attempt_jump()
	else:
		$CoyoteTimer.wait_time = COYOTE_WINDOW
		can_coyote_jump = true
		$CoyoteTimer.start()

func add_velocity(incoming_velocity : Vector2):
	velocity += incoming_velocity

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
	# Record the direction pressed (NESW + diagonals)
	pass

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
		else:
			platform_hologram_H.queue_free()
		platform_hologram_V.queue_free()
	else:
		if platform_hologram_V.valid_hologram:
			platform_hologram_V.set_hologram(false)
		else:
			platform_hologram_V.queue_free()
		platform_hologram_H.queue_free()
		
	# Reset for the next place
	platform_hologram_H = null
	platform_hologram_V = null
	platform_aim_direction = Vector2i(0, 0)

func create_bomb():
	# Place a bomb based on recorded direction while aiming
	pass

func _on_coyote_timer_timeout() -> void:
	can_coyote_jump = false


func _on_jump_buffer_timer_timeout() -> void:
	can_buffer_jump = false


func _on_jump_hold_timer_timeout() -> void:
	can_jump_hold = false
