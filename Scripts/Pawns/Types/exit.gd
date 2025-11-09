class_name Exit
extends Area2D

func _ready() -> void:
	collision_mask = 2
	# Connect the body_entered signal to the _on_body_entered function
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: CharacterBody2D) -> void:
	print("A body entered the exit to space!")
	if body.is_in_group("player"):
		Globals.scene_manager.change_scene("res://Scenes/Maps/galaxy.tscn", 0)
	
