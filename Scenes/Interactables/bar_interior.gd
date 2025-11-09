extends Node2D

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
