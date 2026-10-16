extends Node2D
const TIME_SLOW := true # control whether or not time slows before/after time stops for a smooth transition
const ENTER_TIME_SLOW_SPAN := 0.25 # how long in seconds the transition to stopped time is
const EXIT_TIME_SLOW_SPAN := 0.4 # how long in seconds the transition from stopped time is
const TIME_SLOW_FINAL_SPEED := 0.1
# for something to not be paused, go to Process->Mode and set it to Always
# should be done for this node, as well as bomb/platform placement node

var is_time_stopped := false
var time_stop_tween : Tween

# slows time then pauses
func stop_time() -> void:
	Engine.time_scale = 1.0
	if time_stop_tween:
		time_stop_tween.kill()
	time_stop_tween = get_tree().create_tween()
	time_stop_tween.set_ignore_time_scale(true)
	time_stop_tween.tween_property(Engine, "time_scale", TIME_SLOW_FINAL_SPEED, ENTER_TIME_SLOW_SPAN)
	is_time_stopped = true
	#await tween.finished
	#get_tree().paused = true




# unpauses then unslows time
func resume_time() -> void:
	#get_tree().paused = false
	Engine.time_scale = TIME_SLOW_FINAL_SPEED
	if time_stop_tween:
		time_stop_tween.kill()
	time_stop_tween = get_tree().create_tween()
	time_stop_tween.set_ignore_time_scale(true)
	time_stop_tween.tween_property(Engine, "time_scale", 1, EXIT_TIME_SLOW_SPAN)
	is_time_stopped = false

#func _process(delta: float) -> void:
	#if Input.is_action_just_pressed("time_stop_temp"): # temporary input for testing, TODO remove
		#if !is_time_stopped: 
			#stop_time()
		#else: 
			#resume_time()
	
# (polish, not a priority)
# fades in the time stop shader 
func start_shader() -> void:
	pass # TODO

# (polish, not a priority)
# fades out the time stop shader
# set instant to true to remove fade out
func end_shader(instant: bool = false) -> void:
	pass # TODO
	
