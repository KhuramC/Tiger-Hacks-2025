extends Character

# Character properties
@export var attack_damage: int = 10 # Damage dealt per attack

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var sword_visual: Line2D # Visual sword that appears during attack
var attack_tween: Tween

func _ready():
	super._ready() # Call parent ready function
	
	# Player-specific ready logic
	if has_node("HealthBar"):
		health_bar = $HealthBar
	elif has_node("ProgressBar"):
		health_bar = $ProgressBar
	
	if health_bar:
		update_health_bar()
	
	_create_sword_visual()

func _physics_process(delta):
	# Get player input vector
	var input_direction = Vector2.ZERO
	if can_move():
		input_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Set velocity based on input
	velocity = input_direction * speed
	
	if not can_move():
		velocity = Vector2.ZERO
	
	move_and_slide()
	_update_animation()

	# Handle other inputs like attacking
	if Input.is_action_just_pressed("ui_select"):
		attack()

# Override the parent's animation update to use AnimatedSprite2D
func _update_animation():
	if not animated_sprite:
		return

	var anim_prefix = "idle"
	if velocity.length_squared() > 0:
		last_direction = velocity.normalized()
		anim_prefix = "walk"

	var direction_name = "down" # Default
	# Use dot product to find the dominant direction
	var max_dot = - INF
	var directions = {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT}
	for dir_name in directions:
		var dot_product = last_direction.dot(directions[dir_name])
		if dot_product > max_dot:
			max_dot = dot_product
			direction_name = dir_name
			
	animated_sprite.play(anim_prefix + "_" + direction_name)


func _create_sword_visual() -> void:
	# Create a Line2D to represent the sword
	sword_visual = Line2D.new()
	sword_visual.width = 3.0
	sword_visual.default_color = Color(0.8, 0.8, 0.9, 1.0) # Light gray/white sword color
	sword_visual.visible = false
	sword_visual.z_index = 10 # Make sure it appears above other sprites
	add_child(sword_visual)

func attack() -> void:
	# Show sword swing animation
	_show_sword_swing_animation()
	
	# The old grid-based attack logic is removed.
	# New logic using Area2D or RayCast2D would go here.
	print("Player attacks!")


func _show_sword_swing_animation() -> void:
	if attack_tween and attack_tween.is_running():
		return # Don't attack if already attacking
	
	var sword_length: float = 24.0
	var start_pos: Vector2 = Vector2(0, -8) # Offset from player center
	
	sword_visual.clear_points()
	sword_visual.add_point(start_pos)
	sword_visual.add_point(start_pos + Vector2(0, -sword_length)) # Sword points "up" relative to its own rotation
	
	var swing_arc: float = PI * 0.75 # 135-degree swing for better visual
	
	# The sword's base rotation should point in the direction the player is facing.
	# The angle() of a vector is its angle in radians from the positive X axis.
	# We add PI/2 because our sword visual points "up" (negative Y) by default.
	var base_rotation = last_direction.angle() + PI / 2
	
	var rotation_start = base_rotation - swing_arc / 2
	var rotation_end = base_rotation + swing_arc / 2

	sword_visual.rotation = rotation_start
	sword_visual.visible = true
	
	attack_tween = create_tween()
	attack_tween.tween_property(sword_visual, "rotation", rotation_end, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	attack_tween.tween_callback(func(): sword_visual.visible = false)
	attack_tween.start()
