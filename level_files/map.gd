class_name Map
extends Node2D

@export var player_made_objects_node : Node2D
@export var camera_node : Camera2D
const CAMERA_TWEEN_DURATION := 0.5

@export var room_1 : Room # needed to add to room history.
var room_history : Array[Room] # A stack that keeps track of rooms entered, to identify backtracking
var current_room : Room
var most_recent_junk_pile_room : Room # Junk piles should respawn on death (especially when backtracking)
									  # But if you die in the same room you just destroyed a junk pile, it shouldn't respawn to save time.

var in_between_rooms := false
var is_backtracking := false

const FADE_TO_BLACK_DURATION := 0.25
const FADE_BACK_DURATION := 0.25
var fade_tween : Tween

var overlapped_rooms : Array[Room]
var camera_target_room : Room

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.map_node = self
	var room_parent = $Rooms
	#on_player_room_enter(room_1)
	for room : Room in room_parent.get_children():
		room.player_entered_room.connect(on_player_room_enter)
		room.player_exited_room.connect(on_player_room_exit)
		room.scrap_pile.explodable_component.explode.connect(on_scrap_pile_destruction.bind(room))


func on_player_death():
	if TimeStop.is_time_stopped:
		GameManager.player_node.force_stop_aiming()
		
	fade_to_black()
	GameManager.player_node.set_physics_process(false)
	await fade_tween.finished
	restart_room(current_room)
	await get_tree().create_timer(0.1).timeout
	GameManager.player_node.set_physics_process(true)
	fade_back_out()


func restart_room(room : Room) -> void:
	GameManager.set_scrap_resource(0)
	# No need to make the player destroy the junk every level, becomes busywork
	if room.big_junk_destroyed and most_recent_junk_pile_room == room:
		GameManager.add_scrap_resource(room.starting_scrap_count)
	else:
		# The condition failed because:
		# a) The scrap pile was never destroyed in the first place, so this is fine
		# b) We died in a different room, which means we want to reset the scrap pile, so this is fine
		room.respawn_junk()
		
		# Normally, it is expected that a new junk pile will be destroyed to complete the level, but if there is no junk pile, we need to reset it
		if Room.potential_special_properties.NO_SCRAP_PILE in room.special_properties:
			most_recent_junk_pile_room = null
		
		# TODO: This may cause a bug! IDK lmao
		# In theory, if we die in a level, even when backtracking, the next time we load a level should be a fresh laod
		for room_i : Room in $Rooms.get_children():
			if room_i == room:
				continue # Skip the current room since other code already handles that
			room_i.respawn_junk()
	
	if !(Room.potential_special_properties.NO_SCRAP_PILE in room.special_properties or Room.potential_special_properties.ENTER_WITH_NO_SCRAP in room.special_properties): # Level 1, for example, needs you to have no scrap
		if !room.big_junk_destroyed:
			GameManager.add_scrap_resource(1) # You should always have 1 scrap for the junk pile when entering a room from the front
	
	GameManager.player_node.global_position = room.respawn_point.global_position
	GameManager.player_node.velocity = Vector2.ZERO
	GameManager.player_node.applied_velocity = Vector2.ZERO
	GameManager.player_node.tree_finished()
	GameManager.player_node.can_create_objects = true
	
	is_backtracking = false
	if not (Room.potential_special_properties.NO_SCRAP_PILE in room.special_properties):
		room.get_node("Tree").enabled = true
		room.get_node("Tree").laser_door.appear()
	
	# Delete scrap on the floor
	for scrap in room.get_node("Scrap").get_children():
		scrap.queue_free()
	
	for object in player_made_objects_node.get_children():
		object.queue_free()
	

func get_last_room() -> Room:
	if room_history.size() >= 2:
		return room_history[room_history.size() - 2]
	else:
		return null

func on_player_room_enter(room : Room) -> void:
	if not room in overlapped_rooms:
		overlapped_rooms.append(room)

	GameManager.player_node.can_create_objects = true
	if get_last_room() == room: # We backtracked
		is_backtracking = true
		if not (Room.potential_special_properties.NO_SCRAP_PILE in room.special_properties):
			room.get_node("Tree").enabled = false
		room_history.pop_back()
	else:
		is_backtracking = false
		if not (Room.potential_special_properties.NO_SCRAP_PILE in room.special_properties):
			room.get_node("Tree").enabled = true
		room_history.append(room)
	current_room = room
	set_room_camera_position(room)
	
func on_player_room_exit(room : Room) -> void:
	# Exiting a room has 2 cases: Going forward & backtrack
	# If we exit the last room we were in, that means we went forward. No issues
	# If we backtracked, we would exit the current room
	
	
	
	
	if overlapped_rooms.size() != 2:
		return
		
	var room_to_enter : Room

	if overlapped_rooms[0] == room:
		room_to_enter = overlapped_rooms[1]
	else:
		room_to_enter = overlapped_rooms[0]
	overlapped_rooms.erase(room)
	
	on_player_room_enter(room_to_enter)
	
	
	
	
	#if room == current_room or room == current_room.next_room:
		#is_backtracking = true
		#if not (Room.potential_special_properties.NO_SCRAP_PILE in room.special_properties):
			#room.get_node("Tree").enabled = false
		##on_player_room_enter(get_last_room())
		#on_player_room_enter(room_history[room_history.size() - 1])
	#else: # Not backtracking, go forward
		#if room.next_room:
			#on_player_room_enter(room.next_room)
		
func on_scrap_pile_destruction(room : Room) -> void:
	most_recent_junk_pile_room = room

func set_room_camera_position(room : Room) -> void:
	if room == camera_target_room: # Repeat the same room target, ignore:
		return
	
	camera_target_room = room
	var target_pos := room.bounding_box.global_position
	var target_zoom := Vector2(1, 1) / room.room_size_multiplier
	
	var camera_tween = get_tree().create_tween()
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.set_trans(Tween.TRANS_QUAD)
	camera_tween.tween_property(camera_node, "global_position", target_pos, CAMERA_TWEEN_DURATION)
	camera_tween.parallel().tween_property(camera_node, "zoom", target_zoom, CAMERA_TWEEN_DURATION)

func fade_to_black():
	# Get the player's 2D position and convert it to screen UV coordinates (0.0 to 1.0)
	var screen_uv = GameManager.player_node.get_global_transform_with_canvas().origin / get_viewport_rect().size
	$PlayerDeathFadeShader/Shader.material.set_shader_parameter("center", screen_uv)
	fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_OUT)
	fade_tween.set_trans(Tween.TRANS_LINEAR)
	fade_tween.tween_property($PlayerDeathFadeShader/Shader.material, "shader_parameter/progress", 1.0, FADE_TO_BLACK_DURATION)
	
func fade_back_out():
	var screen_uv = GameManager.player_node.get_global_transform_with_canvas().origin / get_viewport_rect().size
	$PlayerDeathFadeShader/Shader.material.set_shader_parameter("center", screen_uv)
	fade_tween = create_tween()
	fade_tween.set_ease(Tween.EASE_IN)
	fade_tween.set_trans(Tween.TRANS_LINEAR)
	fade_tween.tween_property($PlayerDeathFadeShader/Shader.material, "shader_parameter/progress", 0.0, FADE_BACK_DURATION)
