extends Node2D

enum { EMPTY = -1, ACTOR, OBSTACLE, EVENT }

var actor_grid: TileMapLayer = ActorGrid.new(self)
var event_grid: TileMapLayer = EventGrid.new(self)

func _ready() -> void:
	_initialize_grids()

func _initialize_grids() -> void:
	get_parent().add_child.call_deferred(actor_grid)
	get_parent().add_child.call_deferred(event_grid)

func request_move(pawn: Pawn, direction: Vector2i) -> Vector2i:
	return actor_grid.request_move(pawn, direction)

func request_actor(pawn: Pawn, direction: Vector2i) -> void:
	actor_grid.request_event(pawn, direction)
func request_damage(attacker: Character, direction: Vector2i, damage_amount: int) -> bool:
	"""
	Delegates the damage request to the actor_grid (which manages all characters).
	The actor_grid will check the target cell and apply damage if an NPC is found.
	"""
	return actor_grid.request_damage(attacker, direction, damage_amount)

func request_event(pawn: Pawn, direction: Vector2i) -> void:
	event_grid.request_event(pawn, direction)
