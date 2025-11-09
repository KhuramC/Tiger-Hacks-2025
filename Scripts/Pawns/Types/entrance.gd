class_name Entrance
extends Area2D


# Scene to load when this entrance is triggered
@export var target_map_scene: PackedScene
@export var location_type: Globals.LOCATION_TYPES = Globals.LOCATION_TYPES.HEADQUARTERS
const TILE_SIZE: int = Globals.TILE_SIZE
const location_names = Globals.location_names
const NUM_TILES: int = 5

func _ready() -> void:
	collision_mask = 2
	# Connect the body_entered signal to the _on_body_entered function
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	# Entrances are its own type
	

	var sprite = get_node("Sprite2D")
	# match sprite based on location type
	match location_type:
		Globals.LOCATION_TYPES.HEADQUARTERS:
			sprite.texture = load("res://Graphics/Pawns/hq.png")
		Globals.LOCATION_TYPES.SPACE_BAR:
			sprite.texture = load("res://Graphics/Pawns/bar.png")
		Globals.LOCATION_TYPES.SATURN_LIKE:
			sprite.texture = load("res://Graphics/Pawns/saturn_like.png")


# Called when an actor interacts with this entrance
func _on_body_entered(body: CharacterBody2D) -> void:
	# --- THIS IS THE CRITICAL DEBUG LINE ---
	print("DEBUG: A body named '", body.name, "' just entered the ", location_names[location_type], ".")
	
	if body.is_in_group("player"):
		print("SUCCESS: The body was in the 'player' group!")
		
		match location_type:
			Globals.LOCATION_TYPES.HEADQUARTERS:
				print("Taking player to HQ!")
			Globals.LOCATION_TYPES.SPACE_BAR:
				print("Taking player to the bar!")
				get_tree().change_scene_to_file("res://Scenes/Interactables/bar_interior.tscn")
			Globals.LOCATION_TYPES.SATURN_LIKE:
				print("Taking player to a saturn like planet!")
	else:
		print("FAILURE: The body was NOT in the 'player' group.")
