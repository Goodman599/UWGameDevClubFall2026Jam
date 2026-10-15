extends Node2D


const SCRAP_REFUND := 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ExplodableComponent.explode.connect(destroy)

func destroy() -> void:
	spawn_scrap(SCRAP_REFUND)
	queue_free()

func spawn_scrap(count : int) -> void:
	for i in range(count):
		pass
