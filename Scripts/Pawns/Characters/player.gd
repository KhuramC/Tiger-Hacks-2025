extends CharacterBody2D

# This is the player's speed in pixels per second.
# You can change this number to make the player faster or slower.
const SPEED = 300.0

# This function is called by Godot every physics frame.
# It's the standard place to put all movement and physics code.
func _physics_process(delta):
	# 1. Get input from the player (arrow keys or WASD)
	# This creates a vector like (1, 0) for right, (-1, 0) for left, etc.
	var input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# 2. Set the player's velocity
	# We multiply the direction by the speed.
	velocity = input_direction * SPEED

	# 3. Move the player!
	# This is the magic built-in function.
	# It moves the player based on 'velocity',
	# and it will *automatically* collide and stop
	# against your TileMap walls (or any other physics body).
	move_and_slide()
