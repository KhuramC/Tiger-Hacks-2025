class_name Character
extends CharacterBody2D

@onready var death_screen_scene = preload("res://Scenes/UI/death_screen.tscn")
var death_screen = null

@export var speed: float = 100.0

var max_health: int = 100
var health: int = max_health
@onready var health_bar: ProgressBar = $ProgressBar  # Health bar node (can be named "HealthBar" or "ProgressBar")

var is_talking: bool = false
var last_direction: Vector2 = Vector2.DOWN

@onready var chara_skin: Sprite2D = $Skin

func _ready():
	collision_layer = 2
	update_health_bar()

func _physics_process(delta):
	# Child classes should set the 'velocity' vector based on their logic (e.g., player input or AI).
	# This base function then handles movement, collision, and animation.
	if not can_move():
		velocity = Vector2.ZERO
	
	move_and_slide()
	_update_animation()

func _update_animation():
	if velocity.length() > 0:
		last_direction = velocity.normalized()
		chara_skin.play_walk_animation()
		chara_skin.set_animation_direction(last_direction)
	else:
		chara_skin.play_idle_animation()
		chara_skin.set_animation_direction(last_direction) # Keep facing the last direction when idle

func heal(amount: int) -> void:
	health += amount
	health = clamp(health, 0, max_health)
	update_health_bar()

func take_damage(amount: int) -> void:
	health -= amount
	health = clamp(health, 0, max_health)
	update_health_bar()
	
	if health <= 0:
		die()

func update_health_bar() -> void:
	if health_bar:
		# Use the custom function defined in progressbar.gd
		health_bar.set_health(health, max_health)

func die() -> void:
	if is_in_group("player"):
		velocity = Vector2.ZERO
		
		if not death_screen:
			death_screen = death_screen_scene.instantiate()
			death_screen.restart_game.connect(_on_death_screen_restart)
			
			var canvas_layer: CanvasLayer
			var root = get_tree().root.get_node("/root")
			
			var existing_canvas = root.get_node_or_null("UILayer")
			if existing_canvas and existing_canvas is CanvasLayer:
				canvas_layer = existing_canvas
			else:
				canvas_layer = CanvasLayer.new()
				canvas_layer.name = "UILayer"
				canvas_layer.layer = 100 # Ensure it's on top
				canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
				root.add_child(canvas_layer)
				
			canvas_layer.add_child(death_screen)
			
		death_screen.show_death_screen()
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		queue_free()
			
func _on_death_screen_restart():
	process_mode = Node.PROCESS_MODE_INHERIT
	health = max_health
	update_health_bar()
	global_position = Vector2.ZERO

func can_move() -> bool:
	return not is_talking

func set_talking(talk_state: bool) -> void:
	is_talking = talk_state
