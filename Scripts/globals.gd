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

static var scene_manager = null

static func initialize_scene_manager(root_node, initial_scene, num_scenes):
	if scene_manager == null:
		scene_manager = SceneManager.new()
		root_node.add_child(scene_manager)
		scene_manager.current_scene = initial_scene
		scene_manager.loaded_scenes.resize(num_scenes+1)
		
