extends Node2D
var player: CharacterBody2D = null # Reference to the player

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
	pass # Replace with function body.

func _on_body_entered(body: Node2D) -> void:
	
	# --- THIS IS THE CRITICAL DEBUG LINE ---
	print("DEBUG: A body named '", body.name, "' just entered the Bar.")
	if body.is_in_group("player"):
		print("SUCCESS: The body was in the 'player' group!")
	else:
		print("FAILURE: The body was NOT in the 'player' group.")
		
		# --- THIS IS THE NEXT STEP ---
		# When you are ready and have a "bar_interior.tscn" scene,
		# you will uncomment the line below to change scenes.
		# get_tree().change_scene_to_file("res://scenes/levels/bar_interior.tscn")

func update_player_position():
	print("In HQ, updating position!")
	player.global_position = Vector2(135,-65) + Vector2(-32,0)
