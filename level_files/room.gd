@tool
class_name Room
extends Area2D

signal player_entered_room(room : Room)
signal player_exited_room(room : Room)

const SCREEN_SIZE := Vector2(1920, 1080)

const room_size := SCREEN_SIZE
		
@export var room_size_multiplier := Vector2(1, 1):
	set(value):
		room_size_multiplier = value
		_update_room_visuals()

@export var starting_scrap_count := 0
var big_junk_destroyed := false

@export var perfect_score_threshold := 1

@onready var bounding_box : CollisionShape2D = $BoundingBox
@onready var respawn_point : Marker2D = $PlayerSpawnPoint
@onready var scrap_pile : Node2D = $ScrapPile
@onready var scrap_tree : JunkTree = $Tree

enum potential_special_properties {
	NO_SCRAP_PILE, # Level 1, for example, needs you to have no scrap
	HAS_FREE_SCRAP, # Level 2, for example, give the player a scrap for free
	ENTER_WITH_NO_SCRAP, # Eg Level 1->2
}
@export var special_properties : Array[potential_special_properties] = []
var free_scrap_positions : Dictionary[Vector2, Scrap] = {}

const SCRAP_SCENE := preload("res://game_objects/scrap_files/scrap_metal.tscn")

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_room_visuals()
	scrap_tree.set_perfect_score_threshold(perfect_score_threshold)
	
	if not Engine.is_editor_hint():
		# If the project is running (not in the editor), remove the player hologram
		$PlayerSpawnPoint/Player.hide()
		$ScrapPile.scrap_amount = starting_scrap_count
		if potential_special_properties.NO_SCRAP_PILE in special_properties:
			$Tree.queue_free()
			$ScrapPile.queue_free()
		if potential_special_properties.HAS_FREE_SCRAP in special_properties:
			for child in get_children():
				if child is Scrap:
					free_scrap_positions[child.position] = child

func _update_room_visuals() -> void:
	if not bounding_box:
		bounding_box = get_node_or_null("CollisionShape2D")

	if not bounding_box or not respawn_point or not scrap_pile:
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


func get_respawn_position() -> Vector2:
	return respawn_point.global_position

func get_global_room_rect() -> Rect2:
	return Rect2(global_position, room_size)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_entered_room.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_exited_room.emit(self)

func _on_scrap_pile_explodable_component_explode() -> void:
	big_junk_destroyed = true

func respawn_junk():
	big_junk_destroyed = false
	if scrap_tree and scrap_tree.fully_bloomed == false: # doesn't reset if perfect score achieved
		scrap_tree.reset()
	
	if get_node_or_null("ScrapPile"):
		$ScrapPile.respawn()
	
	if potential_special_properties.HAS_FREE_SCRAP in special_properties:
		for spawn_pos in free_scrap_positions.keys():
			var current_scrap = free_scrap_positions[spawn_pos]
			
			# If the slot is empty or the scrap node was freed/collected:
			if not is_instance_valid(current_scrap) or current_scrap.collected:
				var new_scrap: Scrap = SCRAP_SCENE.instantiate()
				new_scrap.is_static = true
				new_scrap.position = spawn_pos
				
				# Update the dictionary with the new node using the safe Vector2 key
				free_scrap_positions[spawn_pos] = new_scrap
				add_child(new_scrap)
