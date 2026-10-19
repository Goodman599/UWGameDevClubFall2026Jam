extends Node2D
const ENTER_TIME_SLOW_SPAN := 0.25 # how long in seconds the transition to stopped time is
const EXIT_TIME_SLOW_SPAN := 0.4 # how long in seconds the transition from stopped time is
const TIME_SLOW_FINAL_SPEED := 0.1

# if pausing is used 
const TIME_SLOW := true # control whether or not time slows before/after time stops for a smooth transition
# for something to not be paused, go to Process->Mode and set it to Always
# should be done for this node, as well as bomb/platform placement node

var is_time_stopped := false
var time_stop_tween : Tween

# slows time
func stop_time() -> void:
	Engine.time_scale = 1.0
	if time_stop_tween:
		time_stop_tween.kill()
	time_stop_tween = get_tree().create_tween()
	time_stop_tween.set_ignore_time_scale(true)
	time_stop_tween.tween_property(Engine, "time_scale", TIME_SLOW_FINAL_SPEED, ENTER_TIME_SLOW_SPAN)
	is_time_stopped = true
	start_shader()
	#await tween.finished
	#get_tree().paused = true


# unslows time
func resume_time(instant: bool = false) -> void:
	#get_tree().paused = false
	if time_stop_tween:
		time_stop_tween.kill()
	if not instant: 
		Engine.time_scale = TIME_SLOW_FINAL_SPEED
		time_stop_tween = get_tree().create_tween()
		time_stop_tween.set_ignore_time_scale(true)
		time_stop_tween.tween_property(Engine, "time_scale", 1, EXIT_TIME_SLOW_SPAN)
	else: 
		Engine.time_scale = 1
	is_time_stopped = false
	end_shader(instant)

	
# (polish, not a priority)
# fades in the time stop shader 
func start_shader() -> void:
	var tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(GameManager.player_node.get_node("TimeStopShader/Shader").material, "shader_parameter/intensity", 0.25, ENTER_TIME_SLOW_SPAN)

# (polish, not a priority)
# fades out the time stop shader
# set instant to true to remove without a fade out
func end_shader(instant: bool = false) -> void:
	var tween = create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(GameManager.player_node.get_node("TimeStopShader/Shader").material, "shader_parameter/intensity", 0.0, EXIT_TIME_SLOW_SPAN)
	
