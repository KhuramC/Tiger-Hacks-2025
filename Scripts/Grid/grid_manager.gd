extends Node2D

enum { EMPTY = -1, ACTOR, OBSTACLE, EVENT }

var actor_grid: TileMapLayer = ActorGrid.new(self)
var event_grid: TileMapLayer = EventGrid.new(self)

func _ready() -> void:
	# Add to group so bounty manager can find it
	add_to_group("Grid")
	_initialize_grids()

func _initialize_grids() -> void:
	get_parent().add_child.call_deferred(actor_grid)
	get_parent().add_child.call_deferred(event_grid)

func request_move(pawn: Node2D, direction: Vector2i) -> Vector2i:
	return actor_grid.request_move(pawn, direction)

func request_actor(pawn: Node2D, direction: Vector2i) -> void:
	actor_grid.request_event(pawn, direction)

func request_event(pawn: Node2D, direction: Vector2i) -> void:
	event_grid.request_event(pawn, direction)

func remove_pawn_from_grid(pawn: Node2D) -> void:
	# Remove pawn from both grids
	actor_grid.remove_pawn(pawn)
	event_grid.remove_pawn(pawn)
