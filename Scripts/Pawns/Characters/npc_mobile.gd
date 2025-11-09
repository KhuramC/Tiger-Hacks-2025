extends Character

@export var move_pattern: Array[Vector2] = []
var target_position: Vector2
var is_moving_to_target: bool = false
var current_pattern_index: int = 0

@onready var move_max: int = move_pattern.size()

func _ready():
	speed = 150
	if not move_pattern.is_empty():
		target_position = global_position + move_pattern[current_pattern_index]
		is_moving_to_target = true

func _physics_process(delta):
	if not move_pattern.is_empty() and is_moving_to_target:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		if global_position.distance_to(target_position) < 5: # Close enough to target
			global_position = target_position # Snap to target to avoid overshooting
			is_moving_to_target = false
			velocity = Vector2.ZERO
			
			# Move to the next point in the pattern after a short delay
			await get_tree().create_timer(1.0).timeout # Wait for 1 second
			current_pattern_index = (current_pattern_index + 1) % move_pattern.size()
			target_position = global_position + move_pattern[current_pattern_index]
			is_moving_to_target = true
	else:
		velocity = Vector2.ZERO
