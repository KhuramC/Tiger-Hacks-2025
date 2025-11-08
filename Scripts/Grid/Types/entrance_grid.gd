class_name EntranceGrid
extends PawnGrid

func _ready() -> void:
	initialize_pawns(ENTRANCE)

func request_entrance(pawn: Pawn, direction: Vector2i) -> void:
	var cell: Dictionary = get_cell_data(pawn.position, direction)
	
	var entrance_pawn: Pawn = get_cell_pawn(cell.target)
	if entrance_pawn:
		# TODO: Add logic to handle entering the new grid/space
		print("Entrance triggered at: ", cell.target)
