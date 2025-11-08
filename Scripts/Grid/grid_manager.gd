extends Node2D

enum { EMPTY = -1, ACTOR, OBSTACLE, EVENT, ENTRANCE }

var actor_grid: TileMapLayer = ActorGrid.new(self)
var event_grid: TileMapLayer = EventGrid.new(self)

const ENTRANCE_SCENE: PackedScene = preload("res://Scenes/Pawns/entrance.tscn")
const NUM_ENTRANCES: int = 5

func _ready() -> void:
	_initialize_grids()
	await actor_grid.ready
	_generate_entrances()

func _generate_entrances() -> void:
	var used_rect: Rect2i = actor_grid.get_used_rect()
	var possible_positions: Array[Vector2i] = []
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			possible_positions.append(Vector2i(x, y))
	possible_positions.shuffle()

	for i in range(min(NUM_ENTRANCES, possible_positions.size())):
		var grid_pos: Vector2i = possible_positions[i]
		var location_type: Globals.LOCATION_TYPES = Globals.LOCATION_TYPES.values()[randi() % Globals.LOCATION_TYPES.size()]
		
		var entrance: Node2D = ENTRANCE_SCENE.instantiate()
		entrance.location_type = location_type
		entrance.position = actor_grid.map_to_local(grid_pos)
		entrance.z_index = -1
		add_child(entrance)

func _initialize_grids() -> void:
	get_parent().add_child.call_deferred(actor_grid)
	get_parent().add_child.call_deferred(event_grid)

func request_move(pawn: Pawn, direction: Vector2i) -> Vector2i:
	return actor_grid.request_move(pawn, direction)

func request_actor(pawn: Pawn, direction: Vector2i) -> void:
	actor_grid.request_event(pawn, direction)

func request_event(pawn: Pawn, direction: Vector2i) -> void:
	event_grid.request_event(pawn, direction)
