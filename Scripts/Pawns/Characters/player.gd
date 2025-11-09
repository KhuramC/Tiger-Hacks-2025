extends Character

# Character properties
@export var attack_damage: int = 10 # Damage dealt per attack


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
	
	# Create sword visual
	_create_sword_visual()


@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var Grid: Node2D = get_parent()

var sword_visual: Line2D # Visual sword that appears during attack
var attack_tween: Tween

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
	
	# Remove from grid system before freeing
	if Grid and Grid.has_method("remove_pawn_from_grid"):
		Grid.remove_pawn_from_grid(self)
	
	queue_free() # You can replace this with respawn logic later

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
			move_to(target_position) # This will set walk animation
		else:
			play_idle_animation()
	else:
		play_idle_animation()

func set_talking(talk_state: bool) -> void:
	is_talking = talk_state
	if is_talking: input_history.clear()


# This function is called by Godot every physics frame.
# It's the standard place to put all movement and physics code.
func _physics_process(delta):
	input_priority()


	if Input.is_action_just_pressed("ui_select"):
		attack()

	if can_move():
		# Check for movement - both initial press and held keys
		var pressed_direction: Vector2i = Vector2i.ZERO
		
		# Check for currently pressed direction keys
		for direction_key in MOVEMENTS.keys():
			if Input.is_action_pressed(direction_key):
				pressed_direction = MOVEMENTS[direction_key]
				break # Use the first pressed direction
		
		# If a direction is pressed, try to move
		if pressed_direction != Vector2i.ZERO:
			cur_direction = pressed_direction
			
			# Try to move (will be handled in _move_tween_done if already moving)
			if not is_moving:
				# Set direction and try to move
				set_animation_direction(pressed_direction) # Set idle animation first
				# We multiply the direction by the speed.
				velocity = pressed_direction * speed

				# 3. Move the player!
				# This is the magic built-in function.
				# It moves the player based on 'velocity',
				# and it will *automatically* collide and stop
				# against your TileMap walls (or any other physics body).
				move_and_slide()


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

func _create_sword_visual() -> void:
	# Create a Line2D to represent the sword
	sword_visual = Line2D.new()
	sword_visual.width = 3.0
	sword_visual.default_color = Color(0.8, 0.8, 0.9, 1.0) # Light gray/white sword color
	sword_visual.visible = false
	sword_visual.z_index = 10 # Make sure it appears above other sprites
	add_child(sword_visual)

func attack() -> void:
	# Show sword swing animation
	_show_sword_swing_animation()
	
	# Get the actor grid to check for NPCs in the swing area
	var actor_grid = Grid.actor_grid
	if not actor_grid:
		return
	
	# Swing hits multiple cells: primary direction and diagonally adjacent (90-degree arc in front)
	# Hits the cell directly in front and cells diagonally in front (left and right of front cell)
	var attack_directions: Array[Vector2i] = []
	
	match cur_direction:
		Vector2i.UP:
			# Hit directly up, and diagonally up-left and up-right
			attack_directions = [Vector2i.UP, Vector2i.UP + Vector2i.LEFT, Vector2i.UP + Vector2i.RIGHT]
		Vector2i.DOWN:
			# Hit directly down, and diagonally down-left and down-right
			attack_directions = [Vector2i.DOWN, Vector2i.DOWN + Vector2i.LEFT, Vector2i.DOWN + Vector2i.RIGHT]
		Vector2i.LEFT:
			# Hit directly left, and diagonally left-up and left-down
			attack_directions = [Vector2i.LEFT, Vector2i.LEFT + Vector2i.UP, Vector2i.LEFT + Vector2i.DOWN]
		Vector2i.RIGHT:
			# Hit directly right, and diagonally right-up and right-down
			attack_directions = [Vector2i.RIGHT, Vector2i.RIGHT + Vector2i.UP, Vector2i.RIGHT + Vector2i.DOWN]
	
	# Check all cells in the swing arc
	for attack_dir in attack_directions:
		var cell: Dictionary = actor_grid.get_cell_data(position, attack_dir)
		
		# Check if there's an actor in that cell
		if cell.target_type == actor_grid.ACTOR:
			var target = actor_grid.get_cell_pawn(cell.target)
			if target and target != self: # Don't hit yourself
				# Check if target has take_damage method (Character or NPC_Mobile)
				if target.has_method("take_damage"):
					target.take_damage(attack_damage)
					print("Player attacked ", target.name, " for ", attack_damage, " damage!")
				elif target.has_method("trigger_event"):
					# If it's an event NPC, trigger it instead
					target.trigger_event(cur_direction)

func _show_sword_swing_animation() -> void:
	if not sword_visual:
		return
	
	# Calculate sword for swing animation
	var sword_length: float = 24.0 # Length of the sword
	var start_pos: Vector2 = Vector2(0, -8) # Start from character center
	
	# Set initial sword position (straight line pointing in direction)
	sword_visual.clear_points()
	sword_visual.add_point(start_pos)
	
	# Calculate swing arc based on direction (swing from one side to the other in front)
	# Always set the line to point straight in the facing direction, then rotate through the arc
	var rotation_start: float = 0.0
	var rotation_end: float = 0.0
	var swing_arc: float = PI / 2 # 90-degree swing
	
	match cur_direction:
		Vector2i.UP:
			# Swing from left to right in front (up-left to up-right)
			# Line points straight up, rotate from -45° to +45° relative to up
			rotation_start = - PI / 4 # Start 45° to the left of up
			rotation_end = PI / 4 # End 45° to the right of up
			sword_visual.add_point(start_pos + Vector2(0, -sword_length)) # Point straight up
		Vector2i.DOWN:
			# Swing from left to right in front (down-left to down-right)
			# Line points straight down, rotate from -45° to +45° relative to down
			rotation_start = - PI / 4 # Start 45° to the left of down
			rotation_end = PI / 4 # End 45° to the right of down
			sword_visual.add_point(start_pos + Vector2(0, sword_length)) # Point straight down
		Vector2i.LEFT:
			# Swing from top to bottom in front (left-up to left-down)
			# Line points straight left, rotate from -45° to +45° relative to left
			rotation_start = - PI / 4 # Start 45° above left
			rotation_end = PI / 4 # End 45° below left
			sword_visual.add_point(start_pos + Vector2(-sword_length, 0)) # Point straight left
		Vector2i.RIGHT:
			# Swing from top to bottom in front (right-up to right-down)
			# Line points straight right, rotate from -45° to +45° relative to right
			rotation_start = - PI / 4 # Start 45° above right
			rotation_end = PI / 4 # End 45° below right
			sword_visual.add_point(start_pos + Vector2(sword_length, 0)) # Point straight right
	
	# Show the sword
	sword_visual.visible = true
	sword_visual.rotation = rotation_start
	
	# Animate the sword swinging
	if attack_tween:
		attack_tween.kill()
	
	attack_tween = create_tween()
	attack_tween.set_parallel(true)
	
	# Fade in quickly
	sword_visual.modulate.a = 0.0
	attack_tween.tween_property(sword_visual, "modulate:a", 1.0, 0.05)
	
	# Rotate the sword through the swing arc (swing from one side to the other)
	attack_tween.tween_property(sword_visual, "rotation", rotation_end, 0.15)
	
	# Fade out after swing
	attack_tween.tween_property(sword_visual, "modulate:a", 0.0, 0.1).set_delay(0.15)
	
	# Hide after animation
	attack_tween.tween_callback(func(): sword_visual.visible = false; sword_visual.rotation = 0.0).set_delay(0.25)
