class_name MainMenu
extends Control

@onready var start_button: Button = $StartButton
@onready var start_button_sprite : AnimatedSprite2D = $StartButton/StartButtonTexture
@onready var fade_rect : ColorRect = $FadeToBlackShader/Shader # Point to your ColorRect node
var is_starting: bool = false
var hover_tween: Tween # Reference to track and cancel active hover tweens
const PLAYER_LEVEL_1_START_POS := Vector2(224.0, 832.0)

@export var fruit_ui : FruitUI

func _ready() -> void:
	start_button.mouse_entered.connect(_on_start_button_mouse_entered)
	start_button.mouse_exited.connect(_on_start_button_mouse_exited)
	start_button.pressed.connect(start)
	
	start_button.pivot_offset = start_button.size / 2.0
	if fruit_ui:
		fruit_ui.hide()

func _on_start_button_mouse_entered() -> void:
	if is_starting:
		return
	
	# Kill the previous tween instantly if it's still running
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_QUAD)
	hover_tween.tween_property(start_button, "scale", Vector2(1.1, 1.1), 0.15)
	start_button_sprite.play("spin")

func _on_start_button_mouse_exited() -> void:
	if is_starting:
		return
	
	# Kill the previous tween instantly if it's still running
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	hover_tween = create_tween()
	hover_tween.set_ease(Tween.EASE_OUT)
	hover_tween.set_trans(Tween.TRANS_QUAD)
	hover_tween.tween_property(start_button, "scale", Vector2(1.0, 1.0), 0.15)
	start_button_sprite.pause()

func start() -> void:
	if is_starting:
		return
		
	is_starting = true
	start_button.disabled = true
	
	# Kill any remaining hover tween so it doesn't fight the click/transition
	if hover_tween and hover_tween.is_valid():
		hover_tween.kill()
		
	if fruit_ui:
		fruit_ui.show()
	GameManager.player_node.global_position = PLAYER_LEVEL_1_START_POS
	var fade_duration = 0.25
	fade_to_black(fade_duration)
	await get_tree().create_timer(fade_duration).timeout
	fade_from_black(fade_duration)
	

func fade_to_black(duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	# Animates the shader's 'progress' uniform from 0.0 to 1.0
	tween.tween_property(fade_rect.material, "shader_parameter/progress", 1.0, duration)

func fade_from_black(duration: float = 1.0) -> void:
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	# Animates back from 1.0 to 0.0
	tween.tween_property(fade_rect.material, "shader_parameter/progress", 0.0, duration)
