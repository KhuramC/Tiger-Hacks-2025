extends Node2D

enum {EMPTY = -1, ACTOR, OBSTACLE, EVENT, ENTRANCE}

var actor_grid: TileMapLayer = ActorGrid.new(self)
var event_grid: TileMapLayer = EventGrid.new(self)

const ENTRANCE_SCENE: PackedScene = preload("res://Scenes/Pawns/entrance.tscn")
const NUM_ENTRANCES: int = 12
const UNIQUE_LOCATIONS: Array = [Globals.LOCATION_TYPES.HEADQUARTERS, Globals.LOCATION_TYPES.SPACE_BAR]
const REUSABLE_LOCATIONS: Array = [Globals.LOCATION_TYPES.GAS_GIANT, Globals.LOCATION_TYPES.HOT_PLANET, Globals.LOCATION_TYPES.SATURN_LIKE]

func _ready() -> void:
	_initialize_grids()
	await actor_grid.ready
	_generate_entrances()

func _generate_location_types(num_entrances: int = NUM_ENTRANCES) -> Array:
	var location_types = UNIQUE_LOCATIONS.duplicate()
	
	# make rest of entrances a random reusable location
	# assumes we have at least enough entrances for unique locations
	for i in range(num_entrances - UNIQUE_LOCATIONS.size()):
		location_types.append(REUSABLE_LOCATIONS[randi() % REUSABLE_LOCATIONS.size()])
	
	return location_types

func get_empty_cells(used_rect: Rect2i) -> Dictionary:
	var empty_cells: Dictionary = {}
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var pos = Vector2i(x, y)
			if actor_grid.get_cell_source_id(pos) == EMPTY:
				empty_cells[pos] = true
	return empty_cells

func _get_possible_locations_in_quadrant(empty_cells: Dictionary, quadrants: Array[Rect2i]) -> Dictionary:
	var possible_locations_by_quadrant: Dictionary = {0: [], 1: [], 2: [], 3: []}
	for i in range(quadrants.size()):
		var quadrant: Rect2i = quadrants[i]
		if quadrant.size.x < 3 or quadrant.size.y < 3:
			# print("Quadrant %d is too small, skipping." % i)
			continue
		
		print("Finding locations for Quadrant %d: %s" % [i, quadrant])
		# Iterate through possible center positions of a 3x3 square
		for x in range(quadrant.position.x + 1, quadrant.end.x - 1):
			for y in range(quadrant.position.y + 1, quadrant.end.y - 1):
				var potential_pos: Vector2i = Vector2i(x, y)
				var is_valid_area: bool = true
				var invalid_cell: Vector2i
				# Check 3x3 area around potential_pos
				for dx in range(-1, 2):
					for dy in range(-1, 2):
						var cell: Vector2i = potential_pos + Vector2i(dx, dy)
						var is_empty = empty_cells.has(cell)
						#print("    - Checking cell %s for potential_pos %s. Is empty: %s" % [cell, potential_pos, is_empty])
						if not is_empty:
							is_valid_area = false
							invalid_cell = cell
							break
					if not is_valid_area:
						break
				
				if is_valid_area:
					possible_locations_by_quadrant[i].append(potential_pos)
				#else:
					#print("  - Potential pos %s is invalid. Conflict at %s" % [potential_pos, invalid_cell])

		# print("Found %d possible locations in Quadrant %d" % [possible_locations_by_quadrant[i].size(), i])
	return possible_locations_by_quadrant

func place_entrances(possible_locations_by_quadrant: Dictionary, num_entrances: int = NUM_ENTRANCES) -> void:
	var entrances_placed: int = 0
	var location_types = _generate_location_types(num_entrances)
	for i in range(num_entrances):
		var quadrant_index: int = i % 4
		
		# If the preferred quadrant is out of spots, find another one
		if possible_locations_by_quadrant[quadrant_index].is_empty():
			var found_alternative: bool = false
			for j in range(len(possible_locations_by_quadrant)):
				if not possible_locations_by_quadrant[j].is_empty():
					quadrant_index = j
					found_alternative = true
					break
			if not found_alternative:
				print("No more locations available in any quadrant. Stopping.")
				break # No more locations available in any quadrant

		var locations_in_quadrant: Array = possible_locations_by_quadrant[quadrant_index]
		var random_index: int = randi() % locations_in_quadrant.size()
		var grid_pos: Vector2i = locations_in_quadrant[random_index]

		# Instantiate and place the entrance
		var entrance: Node2D = ENTRANCE_SCENE.instantiate()
		entrance.location_type = location_types[i]
		entrance.position = actor_grid.map_to_local(grid_pos)
		entrance.z_index = -1
		add_child(entrance)
		entrances_placed += 1
		print("Placed entrance %d at %s in quadrant %d" % [entrances_placed, grid_pos, quadrant_index])


		# Remove the chosen location and any now-invalid (overlapping) locations from all quadrants
		var occupied_center: Vector2i = grid_pos
		for q_idx in range(4):
			var locations: Array = possible_locations_by_quadrant[q_idx]
			var new_locations: Array = []
			for loc in locations:
				# Check if the 3x3 area of 'loc' would overlap with the 3x3 area of 'occupied_center'
				if abs(loc.x - occupied_center.x) > 2 or abs(loc.y - occupied_center.y) > 2:
					new_locations.append(loc)
			possible_locations_by_quadrant[q_idx] = new_locations

	if entrances_placed < num_entrances:
		print("Could not place all entrances. Placed: %d/%d" % [entrances_placed, num_entrances])

func _generate_entrances(num_entrances: int = NUM_ENTRANCES) -> void:
	var lower_layer: TileMapLayer = get_node("../Lower")
	var upper_layer: TileMapLayer = get_node("../Upper")
	var lower_rect: Rect2i = lower_layer.get_used_rect()
	var upper_rect: Rect2i = upper_layer.get_used_rect()
	var used_rect: Rect2i = lower_rect.merge(upper_rect)
	
	# 1. Get all empty cells
	var empty_cells: Dictionary = get_empty_cells(used_rect)
	#print("Found %d empty cells" % empty_cells.size())

	# 2. Define quadrants
	var center: Vector2i = used_rect.position + used_rect.size / 2
	var quadrants: Array[Rect2i] = [
		Rect2i(used_rect.position, center - used_rect.position),
		Rect2i(Vector2i(center.x, used_rect.position.y), Vector2i(used_rect.end.x - center.x, center.y - used_rect.position.y)),
		Rect2i(Vector2i(used_rect.position.x, center.y), Vector2i(center.x - used_rect.position.x, used_rect.end.y - center.y)),
		Rect2i(center, used_rect.end - center)
	]

	# 3. Find all possible locations for a 3x3 entrance in each quadrant
	var possible_locations_by_quadrant: Dictionary = _get_possible_locations_in_quadrant(empty_cells, quadrants)

	# 4. Place entrances from the list of possible locations
	place_entrances(possible_locations_by_quadrant, num_entrances)
	

func _initialize_grids() -> void:
	get_parent().add_child.call_deferred(actor_grid)
	get_parent().add_child.call_deferred(event_grid)

func request_move(pawn: Pawn, direction: Vector2i) -> Vector2i:
	return actor_grid.request_move(pawn, direction)

func request_actor(pawn: Pawn, direction: Vector2i) -> void:
	actor_grid.request_event(pawn, direction)

func request_event(pawn: Pawn, direction: Vector2i) -> void:
	event_grid.request_event(pawn, direction)
