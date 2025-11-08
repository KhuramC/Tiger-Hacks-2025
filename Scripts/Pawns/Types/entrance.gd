class_name Entrance
extends Pawn


# Scene to load when this entrance is triggered
@export var target_map_scene: PackedScene
@export var location_type: Globals.LOCATION_TYPES = Globals.LOCATION_TYPES.HEADQUARTERS
const TILE_SIZE: int = Globals.TILE_SIZE

func _ready() -> void:
	# Entrances are its own type
	type = CELL_TYPES.ENTRANCE
	

	var sprite = get_node("Sprite2D")
	# match sprite based on location type
	match location_type:
		Globals.LOCATION_TYPES.HEADQUARTERS:
			sprite.region_rect = Rect2(144, 144, 3 * TILE_SIZE, 3 * TILE_SIZE)
		Globals.LOCATION_TYPES.SPACE_BAR:
			sprite.region_rect = Rect2(240, 144, 3 * TILE_SIZE, 3 * TILE_SIZE)
		Globals.LOCATION_TYPES.GAS_GIANT:
			sprite.region_rect = Rect2(144, 192, 3 * TILE_SIZE, 3 * TILE_SIZE)
		Globals.LOCATION_TYPES.HOT_PLANET:
			sprite.region_rect = Rect2(192, 192, 3 * TILE_SIZE, 3 * TILE_SIZE)
		Globals.LOCATION_TYPES.SATURN_LIKE:
			sprite.region_rect = Rect2(192, 192, 3 * TILE_SIZE, 3 * TILE_SIZE)


# Called when an actor interacts with this entrance
func trigger_event(direction: Vector2i) -> void:
	print("Entrance triggered! Target map is: ", target_map_scene)
	if target_map_scene:
		# To enable scene transition, uncomment the line below
		# get_tree().change_scene_to_packed(target_map_scene)
		pass
