class_name Globals

const TILE_SIZE = 16

enum LOCATION_TYPES {
	HEADQUARTERS,
	SPACE_BAR,
	SATURN_LIKE
}

const location_names = {
	LOCATION_TYPES.HEADQUARTERS: "headquarters",
	LOCATION_TYPES.SPACE_BAR: "space_bar",
	LOCATION_TYPES.SATURN_LIKE: "saturn_like"
}

static var player_last_galaxy_position: Vector2 = Vector2.ZERO
