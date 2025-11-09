class_name SceneManager
extends Node

var loaded_scenes = []
var current_scene = null

func change_scene(scene_path, location_id: int):
	if current_scene != null:
		print("Hiding and disabling previous scene:", current_scene)
		current_scene.hide()
		current_scene.process_mode = Node.PROCESS_MODE_DISABLED
		if current_scene.get_parent():
			current_scene.get_parent().remove_child(current_scene)
		
		# If the previous scene is NOT the galaxy scene (which is at index 0)
		# and the target scene is NOT the previous scene (meaning we are not just re-showing the same scene)
		# then queue_free the previous scene and clear its reference in loaded_scenes.
		# This assumes galaxy is always at index 0.
		if current_scene != loaded_scenes[0] and current_scene != loaded_scenes[location_id]:
			print("Queue freeing previous scene:", current_scene)
			# Find the index of the current_scene in loaded_scenes to null it out
			var index_to_null = -1
			for i in range(loaded_scenes.size()):
				if loaded_scenes[i] == current_scene:
					index_to_null = i
					break
			
			current_scene.queue_free()
			if index_to_null != -1:
				loaded_scenes[index_to_null] = null


	if loaded_scenes[location_id] == null:
		loaded_scenes[location_id] = load(scene_path).instantiate()
	current_scene = loaded_scenes[location_id]
	print("New current_scene:", current_scene)

	Engine.get_main_loop().root.add_child(current_scene)
	current_scene.show()
	current_scene.process_mode = Node.PROCESS_MODE_INHERIT
	

	if current_scene.has_method("update_player_position"):
		print("Updating player position!")
		current_scene.update_player_position()
