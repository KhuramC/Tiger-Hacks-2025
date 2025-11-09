extends Node

# Bounty Manager - Handles bounty assignment, points tracking, and enemy spawning

signal bounty_assigned(bounty_target: Node2D)
signal bounty_completed()
signal points_changed(new_points: int)

var current_bounty: Node2D = null  # The current bounty target
var points: int = 0  # Player's points/score
var enemies: Array[Node2D] = []  # All spawned enemies
var enemy_scene: PackedScene = null  # Scene to spawn for enemies

@export var enemy_count: int = 5  # Number of enemies to spawn
@export var min_spawn_distance: int = 10  # Minimum distance from player to spawn enemies

var Grid: Node2D = null
var player: Node2D = null

func _ready():
	# Find the Grid (Pawns node) and player
	Grid = get_tree().get_first_node_in_group("Grid")
	if not Grid:
		# Try to find it by name
		Grid = get_tree().root.get_node_or_null("World/Pawns")
	
	_find_player()
	
	# Load enemy scene
	enemy_scene = load("res://Scenes/Pawns/npc_mobile.tscn")
	
	# Don't spawn enemies automatically - wait for player to request a bounty

func _find_player() -> void:
	# Find the player in the scene
	if Grid:
		var pawns = Grid.get_children()
		for pawn in pawns:
			if pawn.name == "Player":
				player = pawn
				break
			# Check if it's a player by checking for type property
			var type_value = pawn.get("type")
			if type_value != null and type_value == Pawn.CELL_TYPES.ACTOR and pawn != self:
				# Check if it's the player (CharacterBody2D with type ACTOR)
				if pawn is CharacterBody2D:
					player = pawn
					break

func spawn_enemies() -> void:
	if not Grid or not player or not enemy_scene:
		print("Bounty Manager: Cannot spawn enemies - missing Grid, player, or enemy scene")
		return
	
	# Clear existing enemies
	clear_enemies()
	
	# Get valid spawn positions
	var spawn_positions = get_valid_spawn_positions()
	
	if spawn_positions.is_empty():
		print("Bounty Manager: No valid spawn positions found")
		return
	
	# Spawn enemies at random positions
	var spawned_count = 0
	var positions_used = []
	
	for i in range(min(enemy_count, spawn_positions.size())):
		var random_pos = spawn_positions[randi() % spawn_positions.size()]
		
		# Make sure we don't spawn at the same position
		while positions_used.has(random_pos) and spawn_positions.size() > positions_used.size():
			random_pos = spawn_positions[randi() % spawn_positions.size()]
		
		positions_used.append(random_pos)
		
		# Spawn enemy
		var enemy = enemy_scene.instantiate()
		enemy.position = random_pos
		enemy.name = "Enemy_" + str(i)
		Grid.add_child(enemy)
		enemies.append(enemy)
		spawned_count += 1
		
		# Wait a frame to let the enemy initialize and register with grid
		await get_tree().process_frame
		
		# Manually add enemy to grid if needed
		if Grid and Grid.actor_grid:
			var actor_grid = Grid.actor_grid
			var enemy_cell = actor_grid.local_to_map(enemy.position)
			actor_grid.set_cell(enemy_cell, actor_grid.ACTOR, Vector2i.ZERO)
			# Add to pawn_coords dictionary
			actor_grid.pawn_coords[enemy_cell] = enemy
	
	# Assign one random enemy as the bounty
	if enemies.size() > 0:
		await get_tree().create_timer(0.1).timeout  # Wait a bit for all enemies to initialize
		assign_random_bounty()
	
	print("Bounty Manager: Spawned ", spawned_count, " enemies")

func get_valid_spawn_positions() -> Array[Vector2]:
	var valid_positions: Array[Vector2] = []
	
	if not Grid or not player:
		return valid_positions
	
	var actor_grid = Grid.actor_grid
	if not actor_grid:
		return valid_positions
	
	# Get player position in grid coordinates
	var player_cell = actor_grid.local_to_map(player.position)
	
	# Get all empty cells in the grid
	# We'll check a reasonable area around the map
	var map_bounds = get_map_bounds()
	
	for x in range(map_bounds.min_x, map_bounds.max_x + 1):
		for y in range(map_bounds.min_y, map_bounds.max_y + 1):
			var cell_pos = Vector2i(x, y)
			var world_pos = actor_grid.map_to_local(cell_pos)
			
			# Check if cell is empty
			var cell_type = actor_grid.get_cell_source_id(cell_pos)
			if cell_type == actor_grid.EMPTY:
				# Check minimum distance from player
				var cell_diff = cell_pos - player_cell
				var distance = max(abs(cell_diff.x), abs(cell_diff.y))  # Chebyshev distance
				
				if distance >= min_spawn_distance:
					valid_positions.append(world_pos)
	
	return valid_positions

func get_map_bounds() -> Dictionary:
	# Get map bounds from tilemap layers
	var bounds = {
		"min_x": -100,
		"max_x": 100,
		"min_y": -100,
		"max_y": 100
	}
	
	# Try to get bounds from tilemap
	var tilemaps = get_tree().get_nodes_in_group("Tilemap")
	if tilemaps.size() > 0:
		var tilemap = tilemaps[0] as TileMapLayer
		if tilemap:
			var used_cells = tilemap.get_used_cells()
			if used_cells.size() > 0:
				var min_pos = used_cells[0]
				var max_pos = used_cells[0]
				
				for cell in used_cells:
					min_pos.x = min(min_pos.x, cell.x)
					min_pos.y = min(min_pos.y, cell.y)
					max_pos.x = max(max_pos.x, cell.x)
					max_pos.y = max(max_pos.y, cell.y)
				
				bounds.min_x = min_pos.x - 5
				bounds.max_x = max_pos.x + 5
				bounds.min_y = min_pos.y - 5
				bounds.max_y = max_pos.y + 5
	
	return bounds

func assign_random_bounty() -> void:
	if enemies.is_empty():
		return
	
	# Clear previous bounty
	if current_bounty and is_instance_valid(current_bounty):
		if current_bounty.has_method("set_is_bounty"):
			current_bounty.set_is_bounty(false)
	
	# Pick a random enemy as bounty
	var random_index = randi() % enemies.size()
	current_bounty = enemies[random_index]
	
	if current_bounty and is_instance_valid(current_bounty):
		if current_bounty.has_method("set_is_bounty"):
			current_bounty.set_is_bounty(true)
		bounty_assigned.emit(current_bounty)
		print("Bounty Manager: Assigned bounty to ", current_bounty.name)

func assign_bounty() -> void:
	# Called by bounty giver NPC to assign a new bounty
	# Only assign if there's no current active bounty
	if current_bounty and is_instance_valid(current_bounty):
		print("Bounty Manager: Cannot assign new bounty - current bounty still active")
		return
	
	# Clear any existing enemies first
	clear_enemies()
	
	# Spawn new enemies and assign bounty
	spawn_enemies()

func on_enemy_killed(enemy: Node2D) -> void:
	if enemy == current_bounty:
		# Bounty was killed - award point
		points += 1
		points_changed.emit(points)
		bounty_completed.emit()
		print("Bounty Manager: Bounty killed! Points: ", points)
		
		# Clear the current bounty (don't spawn new enemies automatically)
		current_bounty = null
		
		# Remove the killed enemy from the list
		enemies.erase(enemy)
		
		# Clear all remaining enemies
		clear_enemies()
	else:
		# Regular enemy killed
		enemies.erase(enemy)
		print("Bounty Manager: Enemy killed (not bounty)")

func clear_enemies() -> void:
	# Remove all existing enemies
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies.clear()
	current_bounty = null

func get_current_bounty() -> Node2D:
	return current_bounty

func get_points() -> int:
	return points
