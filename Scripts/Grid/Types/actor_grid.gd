class_name ActorGrid
extends PawnGrid

func _ready() -> void:
	initialize_cells("Tilemap", "coll_type")
	initialize_pawns(ACTOR)

func request_move(pawn: Node2D, direction: Vector2i) -> Vector2i:
	var cell: Dictionary = get_cell_data(pawn.position, direction)
	
	# Get type from pawn (works for both Pawn and CharacterBody2D with type property)
	var pawn_type: int = -1
	if pawn is Pawn:
		pawn_type = pawn.type
	else:
		var type_value = pawn.get("type")
		if type_value != null:
			pawn_type = type_value
	
	match cell.target_type:
		EMPTY:
			update_pawn_pos(pawn_type, cell.start, cell.target)
			return map_to_local(cell.target)
		_:
			return Vector2i.ZERO

func request_event(pawn: Node2D, direction: Vector2i) -> void:
	var cell: Dictionary = get_cell_data(pawn.position, direction)

	if cell.target_type == ACTOR:
		var event_pawn = get_cell_pawn(cell.target)
		if event_pawn and event_pawn.has_method("trigger_event"):
			event_pawn.trigger_event(direction)
