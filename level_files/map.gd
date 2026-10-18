extends Node2D

@export var camera_node : Camera2D
const CAMERA_TWEEN_DURATION := 0.5

#var room_history : Array[Room] # A stack that keeps track of rooms entered, to identify backtracking
var current_room : Room
var most_recent_junk_pile_room : Room # Junk piles should respawn on death (especially when backtracking)
									  # But if you die in the same room you just destroyed a junk pile, it shouldn't respawn to save time.


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var room_parent = $Rooms
	for room : Room in room_parent.get_children():
		room.player_entered_room.connect(on_player_room_enter)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func restart_room(room : Room) -> void:
	if !(Room.potential_special_properties.START_WITH_NO_SCRAP in room.special_properties): # Level 1, for example, needs you to have no scrap
		GameManager.scrap = 1 # You should always have 1 scrap for the junk pile when entering a room from the front
	
	# No need to make the player destroy the junk every level, becomes busywork
	if room.big_junk_destroyed:
		GameManager.scrap += room.starting_scrap_count
	
	GameManager.player_node.global_position = room.respawn_point.global_position

func on_player_room_enter(room : Room) -> void:
	current_room = room
	set_room_camera_position(room)


func set_room_camera_position(room : Room) -> void:
	var target_pos := room.bounding_box.global_position
	var target_zoom := Vector2(1, 1) / room.room_size_multiplier
	
	var camera_tween = get_tree().create_tween()
	camera_tween.set_ease(Tween.EASE_IN_OUT)
	camera_tween.set_trans(Tween.TRANS_QUAD)
	camera_tween.tween_property(camera_node, "global_position", target_pos, CAMERA_TWEEN_DURATION)
	camera_tween.parallel().tween_property(camera_node, "zoom", target_zoom, CAMERA_TWEEN_DURATION)
