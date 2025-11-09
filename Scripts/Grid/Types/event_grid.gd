class_name EventGrid
extends PawnGrid

func _ready() -> void:
	initialize_pawns(EVENT)

func request_event(pawn: Node2D, direction: Vector2i) -> void:
	var cell: Dictionary = get_cell_data(pawn.position, direction)
	
	var event_pawn = get_cell_pawn(cell.target)
	if event_pawn and event_pawn.has_method("trigger_event"):
		event_pawn.trigger_event()
