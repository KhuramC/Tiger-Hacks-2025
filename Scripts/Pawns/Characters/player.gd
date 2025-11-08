extends CharacterBody2D

# Pawn interface
enum CELL_TYPES{ ACTOR, OBSTACLE, EVENT }
@export var type: CELL_TYPES = CELL_TYPES.ACTOR

# Character properties
@export var speed: float = 1.0
@export var move_duration: float = 0.2  # Duration in seconds to move one tile
@export var attack_damage: int = 10  # Damage dealt per attack

var max_health: int = 100
var health: int = max_health
var health_bar: ProgressBar  # Health bar node (can be named "HealthBar" or "ProgressBar")

func _ready():
	# Try to find health bar with either name
	if has_node("HealthBar"):
		health_bar = $HealthBar
	elif has_node("ProgressBar"):
		health_bar = $ProgressBar
	
	# Ensure health starts full
	health = max_health
	update_health_bar()
	print("Player ready with full health:", health)

var move_tween: Tween
var is_moving: bool = false
var is_talking: bool = false

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var Grid: Node2D = get_parent()

const MOVEMENTS: Dictionary = {
	'ui_up': Vector2i.UP,
	'ui_left': Vector2i.LEFT,
	'ui_right': Vector2i.RIGHT,
	'ui_down': Vector2i.DOWN
}

var input_history: Array[String] = []
var cur_direction: Vector2i = Vector2i.DOWN


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
	queue_free()  # You can replace this with respawn logic later

func can_move() -> bool:
	return not is_moving and not is_talking

func move_to(target_position: Vector2) -> void:
	# Play walk animation based on direction
	play_walk_animation()
	
	move_tween = create_tween()
	move_tween.connect("finished", _move_tween_done)
	move_tween.tween_property(self, "position", target_position, move_duration)
	is_moving = true

func _move_tween_done() -> void:
	move_tween.kill()
	is_moving = false
	Grid.request_event(self, Vector2i.ZERO) # Check if there's an event
	
	# Check if a key is still being held and continue moving
	var held_direction: Vector2i = Vector2i.ZERO
	
	# Check for currently pressed direction keys
	for direction_key in MOVEMENTS.keys():
		if Input.is_action_pressed(direction_key):
			held_direction = MOVEMENTS[direction_key]
			break
	
	if held_direction != Vector2i.ZERO:
		cur_direction = held_direction
		var target_position: Vector2i = Grid.request_move(self, held_direction)
		if target_position:
			move_to(target_position)  # This will set walk animation
		else:
			play_idle_animation()
	else:
		play_idle_animation()

func set_talking(talk_state: bool) -> void:
	is_talking = talk_state
	if is_talking: input_history.clear()

func _process(_delta) -> void:
	input_priority()
	
	if can_move():
		if Input.is_action_just_pressed("ui_accept"):
			Grid.request_actor(self, cur_direction) # To Request dialogue
		
		# Check for attack input (Space key)
		if Input.is_action_just_pressed("ui_select"):
			attack()
		
		# Check for movement - both initial press and held keys
		var pressed_direction: Vector2i = Vector2i.ZERO
		
		# Check for currently pressed direction keys
		for direction_key in MOVEMENTS.keys():
			if Input.is_action_pressed(direction_key):
				pressed_direction = MOVEMENTS[direction_key]
				break  # Use the first pressed direction
		
		# If a direction is pressed, try to move
		if pressed_direction != Vector2i.ZERO:
			cur_direction = pressed_direction
			
			# Try to move (will be handled in _move_tween_done if already moving)
			if not is_moving:
				# Set direction and try to move
				set_animation_direction(pressed_direction)  # Set idle animation first
				var target_position: Vector2i = Grid.request_move(self, pressed_direction)
				if target_position:
					move_to(target_position)  # This will set walk animation
			# If already moving, don't override the walk animation

func input_priority() -> void:
	# Input priority system, prioritize the latest inputs
	for direction in MOVEMENTS.keys():
		if Input.is_action_just_released(direction):
			var index: int = input_history.find(direction)
			if index != -1:
				input_history.remove_at(index)
		
		if Input.is_action_just_pressed(direction):
			input_history.append(direction)

func set_animation_direction(input_direction: Vector2i) -> void:
	# Set animation based on direction
	if input_direction == Vector2i.UP:
		animated_sprite.animation = "idle_up"
	elif input_direction == Vector2i.DOWN:
		animated_sprite.animation = "idle_down"
	elif input_direction == Vector2i.LEFT:
		animated_sprite.animation = "idle_left"
	elif input_direction == Vector2i.RIGHT:
		animated_sprite.animation = "idle_right"

func play_walk_animation() -> void:
	# Play walk animation based on current direction
	if cur_direction == Vector2i.UP:
		animated_sprite.animation = "walk_up"
	elif cur_direction == Vector2i.DOWN:
		animated_sprite.animation = "walk_down"
	elif cur_direction == Vector2i.LEFT:
		animated_sprite.animation = "walk_left"
	elif cur_direction == Vector2i.RIGHT:
		animated_sprite.animation = "walk_right"

func play_idle_animation() -> void:
	# Play idle animation based on current direction
	if cur_direction == Vector2i.UP:
		animated_sprite.animation = "idle_up"
	elif cur_direction == Vector2i.DOWN:
		animated_sprite.animation = "idle_down"
	elif cur_direction == Vector2i.LEFT:
		animated_sprite.animation = "idle_left"
	elif cur_direction == Vector2i.RIGHT:
		animated_sprite.animation = "idle_right"

func attack() -> void:
	# Get the actor grid to check for NPCs in the facing direction
	var actor_grid = Grid.actor_grid
	if not actor_grid:
		return
	
	# Get the cell data in the direction the player is facing
	var cell: Dictionary = actor_grid.get_cell_data(position, cur_direction)
	
	# Check if there's an actor in that cell
	if cell.target_type == actor_grid.ACTOR:
		var target = actor_grid.get_cell_pawn(cell.target)
		if target:
			# Check if target has take_damage method (Character or NPC_Mobile)
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
				print("Player attacked ", target.name, " for ", attack_damage, " damage!")
			elif target.has_method("trigger_event"):
				# If it's an event NPC, trigger it instead
				target.trigger_event(cur_direction)
