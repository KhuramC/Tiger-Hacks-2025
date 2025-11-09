extends Character

# Character properties
@export var attack_damage: int = 10 # Damage dealt per attack

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var sword_visual: Line2D # Visual sword that appears during attack
var attack_tween: Tween
var attack_shape_node = CollisionShape2D.new()

var attack_area: Area2D
var attack_timer: Timer
var hit_enemies_in_swing: Array = []


func _ready():
	super._ready() # Call parent ready function
	speed = 200
	
	# Player-specific ready logic
	if has_node("HealthBar"):
		health_bar = $HealthBar
	elif has_node("ProgressBar"):
		health_bar = $ProgressBar
	
	if health_bar:
		update_health_bar()
	
	_create_sword_visual()
	_create_attack_area_and_timer()

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

func _create_sword_visual() -> void:
	# Create a Line2D to represent the sword
	sword_visual = Line2D.new()
	sword_visual.width = 3.0
	sword_visual.default_color = Color(0.8, 0.8, 0.9, 1.0) # Light gray/white sword color
	sword_visual.visible = false
	sword_visual.z_index = 10 # Make sure it appears above other sprites
	add_child(sword_visual)


func _create_attack_area_and_timer():
	attack_area = Area2D.new()
	attack_area.name = "AttackArea"
	attack_area.collision_layer = 0 # Player's attack layer
	attack_area.collision_mask = 2 # Enemy's body layer
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	add_child(attack_area)

	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 48) # Hitbox for the attack
	attack_shape_node.shape = shape
	attack_shape_node.position = Vector2(32, 0) # Position in front of the player
	attack_area.add_child(attack_shape_node)
	
	attack_timer = Timer.new()
	attack_timer.name = "AttackTimer"
	attack_timer.wait_time = 0.3
	attack_timer.one_shot = true
	attack_timer.timeout.connect(func():
		var shape_node = attack_shape_node
		if shape_node:
			shape_node.disabled = true
	)
	add_child(attack_timer)

	attack_shape_node.disabled = true


func attack() -> void:
	if not attack_timer.is_stopped():
		return # Already attacking

	hit_enemies_in_swing.clear()
	_show_sword_swing_animation()

	attack_area.rotation = last_direction.angle()

	if attack_shape_node:
		attack_shape_node.disabled = false
	

	attack_timer.start()

	# Use a short timer to wait for the physics engine to update.
	# This ensures get_overlapping_bodies() is accurate.
	get_tree().create_timer(0.05).timeout.connect(func():
		var bodies = attack_area.get_overlapping_bodies()
		print("Overlapping bodies:", bodies)
		for body in bodies:
			_on_attack_area_body_entered(body)
	)
	

func _on_attack_area_body_entered(body):
	if(body.name == "Player"):
		# don't hurt player
		return
	print("--- Attack area entered by a body! ---")
	print("Body name: ", body.name)
	print("Body type: ", body.get_class())
	print("Body collision layer: ", body.collision_layer)
	print("Body collision mask: ", body.collision_mask)
	
	if body.has_method("take_damage"):
		print("Body has 'take_damage' method.")
		if not body in hit_enemies_in_swing:
			print("Hit: ", body.name)
			hit_enemies_in_swing.append(body)
			body.take_damage(attack_damage)
		else:
			print("Body already hit in this swing.")
	else:
		print("Body does NOT have 'take_damage' method.")
	print("------------------------------------")

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
