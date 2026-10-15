extends CharacterBody2D


const SPEED := 300.0
const JUMP_VELOCITY := -600.0
const TERMINAL_VELOCITY := 1000.0
const ACCELERATED_TERMINAL_VELOCITY := 1500.0 # Used when holding downwards
const AIR_DRAG := 10.0 # Used when falling faster than terminal velocity

const MAX_JUMP_HOLD_DURATION = 0.5 # In seconds
const JUMP_HOLD_BOOST := -10.0
var can_jump_hold := true

const COYOTE_WINDOW := 0.15 # In seconds
var can_coyote_jump := false
const JUMP_BUFFER_WINODW := 0.1 # In seconds
var can_buffer_jump := false
var was_on_floor_last_frame : bool # Used to start/stop CoyoteTimer and JumpBufferTimer

var aiming_platform := false
var platform_aim_direction := Vector2i(0, 0) # {(1, 0), (-1, 0), (0, 1), (0, -1)}
var aiming_bomb := false
var bomb_aim_direction := Vector2i(0, 0) # {(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (-1, 1), (1, -1)}

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
		velocity.y += JUMP_HOLD_BOOST
	
	if Input.is_action_just_pressed("create_platform") and !aiming_bomb:
		aiming_platform = true
	if Input.is_action_just_pressed("create_bomb") and !aiming_platform:
		aiming_bomb = true
	if aiming_platform:
		aim_platform()
	if aiming_bomb:
		aim_bomb()
	if Input.is_action_just_released("create_platform") and aiming_platform:
		aiming_platform = false
		create_platform()
	if Input.is_action_just_released("create_bomb") and aiming_bomb:
		aiming_bomb = false
		create_bomb()
	
	# If aiming, then all direction inputs must become aiming instead of movement
	if !aiming_bomb and !aiming_platform:
		# Get the input direction and handle the movement/deceleration.
		var direction := Input.get_axis("left", "right")
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func fall(delta : float):
	var terminal_velocity : float
	if Input.is_action_pressed("down"):
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
	pass

func aim_bomb():
	# Record the direction pressed (NESW + diagonals)
	pass

func create_platform():
	# Place a platform based on recorded direction while aiming
	pass

func create_bomb():
	# Place a bomb based on recorded direction while aiming
	pass

func _on_coyote_timer_timeout() -> void:
	can_coyote_jump = false


func _on_jump_buffer_timer_timeout() -> void:
	can_buffer_jump = false


func _on_jump_hold_timer_timeout() -> void:
	can_jump_hold = false
