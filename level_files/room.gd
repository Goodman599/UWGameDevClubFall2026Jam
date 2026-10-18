@tool
class_name Room
extends Area2D

signal player_entered_room(room : Room)

const SCREEN_SIZE := Vector2(1920, 1080)

@export var coordinate_position := Vector2(0, 0):
	set(value):
		coordinate_position = value
		global_position = coordinate_position * SCREEN_SIZE
		
const room_size := SCREEN_SIZE
		
@export var room_size_multiplier := Vector2(1, 1):
	set(value):
		room_size_multiplier = value
		_update_room_visuals()

@export var respawn_offset := Vector2(0, 0):
	set(value):
		respawn_offset = value
		_update_room_visuals()
		
@export var starting_scrap_count := 0
var big_junk_destroyed := false

@onready var bounding_box: CollisionShape2D = $BoundingBox
@onready var respawn_point: Marker2D = $PlayerSpawnPoint

enum potential_special_properties {
	START_WITH_NO_SCRAP,
}
@export var special_properties : Array[potential_special_properties] = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_room_visuals()

func _update_room_visuals() -> void:
	if not bounding_box:
		bounding_box = get_node_or_null("CollisionShape2D")
	if not respawn_point:
		respawn_point = get_node_or_null("RespawnPoint")

	if not bounding_box or not respawn_point:
		return

	# Update collision bounds
	var rect_shape: RectangleShape2D
	if bounding_box.shape is RectangleShape2D:
		# If it's already a rectangle, make it unique (or create one if it's shared)
		if bounding_box.shape.is_local_to_scene() == false:
			bounding_box.shape = bounding_box.shape.duplicate()
		rect_shape = bounding_box.shape
	else:
		rect_shape = RectangleShape2D.new()
		bounding_box.shape = rect_shape

	rect_shape.size = room_size * room_size_multiplier
	bounding_box.position = room_size / 2.0

	# Update respawn marker
	respawn_point.position = respawn_offset

func get_respawn_position() -> Vector2:
	return respawn_point.global_position

func get_global_room_rect() -> Rect2:
	return Rect2(global_position, room_size)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered_room.emit(self)
