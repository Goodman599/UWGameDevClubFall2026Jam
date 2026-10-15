# Because junk and platforms may have different destruction behaviors
# It is better to write the explosion code in those themselves
# and let this component notify them to explode
class_name ExplodableComponent
extends Node2D

signal explode


func exploded():
	emit_signal("explode")
