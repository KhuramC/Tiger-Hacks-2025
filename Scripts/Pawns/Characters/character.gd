class_name Character
extends CharacterBody2D

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
	print(name, "has died")
	queue_free() # You can replace this with respawn logic later

func can_move() -> bool:
	return not is_talking

func set_talking(talk_state: bool) -> void:
	is_talking = talk_state
