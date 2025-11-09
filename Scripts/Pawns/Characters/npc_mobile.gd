extends Character

@export var move_pattern: Array[Vector2i]
@export var detection_range: int = 5  # Number of tiles to detect player
@export var attack_range: int = 1  # Number of tiles to attack player
@export var attack_damage: int = 10  # Damage dealt per attack

var move_step: int = 0
var is_stopped: bool = false
var player: Node2D = null  # Reference to the player
var last_attack_time: float = 0.0
var attack_cooldown: float = 0.5  # Cooldown between attacks in seconds
var is_bounty: bool = false  # Whether this enemy is the current bounty target

@onready var move_max: int = move_pattern.size()
@onready var bounty_indicator: Node2D = null  # Visual indicator for bounty

func _ready():
	# This calls the Character.gd's _ready() function, which runs update_health_bar().
	# This connects the 'health' and 'max_health' values to the $HealthBar node.
	super._ready()
	
	# Make enemy slightly slower than player (player is 0.2, enemy is 0.25)
	move_duration = 0.4
	
	# Find the player
	_find_player()
	
	# Create bounty indicator (will be shown if this enemy is the bounty)
	_create_bounty_indicator()

func _find_player() -> void:
	# Find the player in the scene
	var pawns = Grid.get_children()
	for pawn in pawns:
		if pawn.name == "Player":
			player = pawn
			break
		# Check if it's a player by checking for type property
		var type_value = pawn.get("type")
		if type_value != null and type_value == CELL_TYPES.ACTOR and pawn != self:
			# Check if it's the player (CharacterBody2D with type ACTOR)
			if pawn is CharacterBody2D:
				player = pawn
				break

func _process(_delta) -> void:
	if is_stopped:
		return
	
	# If player not found, try to find it
	if not player:
		_find_player()
	
	# Check for player proximity (make sure player is still valid)
	if player and is_instance_valid(player):
		# Calculate distance in grid tiles
		var actor_grid = Grid.actor_grid
		if actor_grid:
			var npc_cell: Vector2i = actor_grid.local_to_map(position)
			var player_cell: Vector2i = actor_grid.local_to_map(player.position)
			var cell_diff: Vector2i = player_cell - npc_cell
			var tiles_to_player: int = max(abs(cell_diff.x), abs(cell_diff.y))  # Chebyshev distance (max of x and y)
			
			# If player is very close (adjacent), attack
			if tiles_to_player <= attack_range and can_move():
				var current_time = Time.get_ticks_msec() / 1000.0
				if current_time - last_attack_time >= attack_cooldown:
					_attack_player()
					last_attack_time = current_time
				return
			
			# If player is in detection range, move toward them
			if tiles_to_player <= detection_range and can_move():
				_move_toward_player()
				return
	
	# Default behavior: idle (don't move in circles)
	# Only move if there's a move pattern and we're not stopped
	if can_move() and move_pattern.size() > 0:
		var current_step: Vector2i = move_pattern[move_step]
		if current_step:
			chara_skin.set_animation_direction(current_step)
			
			# Checks if the next movement opportunity is possible, if it is move to target position
			var target_position: Vector2i = Grid.request_move(self, current_step)
			if target_position:
				move_to(target_position)
			else:
				return # If player is in the way, return to avoid adding to move_step
		else:
			wait()
		
		# Loops movement when move_step is equal to 0
		move_step += 1
		if move_step >= move_max: move_step = 0

func _move_toward_player() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Calculate direction to player
	var direction_to_player: Vector2i = _get_direction_to_player()
	
	if direction_to_player == Vector2i.ZERO:
		return  # Already at player position
	
	# Set animation direction
	chara_skin.set_animation_direction(direction_to_player)
	
	# Try to move toward player
	var target_position: Vector2i = Grid.request_move(self, direction_to_player)
	if target_position:
		move_to(target_position)

func _get_direction_to_player() -> Vector2i:
	if not player or not is_instance_valid(player):
		return Vector2i.ZERO
	
	var diff: Vector2 = player.position - position
	var direction: Vector2i = Vector2i.ZERO
	
	# Determine primary direction (prioritize horizontal or vertical based on larger difference)
	if abs(diff.x) > abs(diff.y):
		# Move horizontally
		if diff.x > 0:
			direction = Vector2i.RIGHT
		elif diff.x < 0:
			direction = Vector2i.LEFT
	else:
		# Move vertically
		if diff.y > 0:
			direction = Vector2i.DOWN
		elif diff.y < 0:
			direction = Vector2i.UP
	
	return direction

func _attack_player() -> void:
	if not player or not is_instance_valid(player):
		return
	
	# Face the player
	var direction_to_player: Vector2i = _get_direction_to_player()
	if direction_to_player != Vector2i.ZERO:
		chara_skin.set_animation_direction(direction_to_player)
	
	# Check if player is adjacent in the direction we're facing
	var actor_grid = Grid.actor_grid
	if not actor_grid:
		return
	
	var cell: Dictionary = actor_grid.get_cell_data(position, direction_to_player)
	
	# If player is in the adjacent cell, attack them
	if cell.target_type == actor_grid.ACTOR:
		var target = actor_grid.get_cell_pawn(cell.target)
		if target == player and target.has_method("take_damage"):
			target.take_damage(attack_damage)
			print(name, " attacked ", target.name, " for ", attack_damage, " damage!")

func wait() -> void:
	is_stopped = true
	await get_tree().create_timer(1.0).timeout
	is_stopped = false

func trigger_event(direction: Vector2i) -> void:
	if not is_moving:
		chara_skin.set_animation_direction(-direction) # Face player
		print("NPC Mobile")

func set_is_bounty(value: bool) -> void:
	is_bounty = value
	_update_bounty_indicator()

func _create_bounty_indicator() -> void:
	# Create a visual indicator (glowing effect or marker) for bounty targets
	# For now, we'll use a simple colored overlay
	bounty_indicator = Node2D.new()
	bounty_indicator.name = "BountyIndicator"
	add_child(bounty_indicator)
	
	# Create a colored circle or marker above the enemy
	var marker = Sprite2D.new()
	var texture = ImageTexture.new()
	var image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(1.0, 0.0, 0.0, 0.8))  # Red color for bounty
	texture.set_image(image)
	marker.texture = texture
	marker.position = Vector2(0, -20)  # Above the enemy
	marker.z_index = 10
	bounty_indicator.add_child(marker)
	
	bounty_indicator.visible = false

func _update_bounty_indicator() -> void:
	if bounty_indicator:
		bounty_indicator.visible = is_bounty
