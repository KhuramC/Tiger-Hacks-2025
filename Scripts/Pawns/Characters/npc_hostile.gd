extends Character

@export var move_pattern: Array[Vector2] = []
var target_position: Vector2
var is_moving_to_target: bool = false
var current_pattern_index: int = 0
@export var detection_range: float = 5 * Globals.TILE_SIZE # Detection range in pixels
@export var attack_range: float = 1 * Globals.TILE_SIZE # Attack range in pixels
@export var attack_damage: int = 10 # Damage dealt per attack

var is_stopped: bool = false
var player: CharacterBody2D = null # Reference to the player
var last_attack_time: float = 0.0
var attack_cooldown: float = 1.0 # Cooldown between attacks in seconds

func _ready():
	speed = 100
	add_to_group("enemies")
	
	super._ready()
	collision_layer = 2
	# Find the player node. Assumes the player is in the "Player" group.
	_find_player()
	
	if not move_pattern.is_empty():
		target_position = global_position + move_pattern[current_pattern_index]
		is_moving_to_target = true

func _find_player() -> void:
	# Find the player in the scene tree by group
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func _physics_process(delta):
	if is_stopped:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(player):
		_find_player() # Try to find player again if instance is lost
		velocity = Vector2.ZERO # Stop moving if no player
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)
	var current_time = Time.get_ticks_msec() / 1000.0

	# State: Attack
	if distance_to_player <= attack_range:
		velocity = Vector2.ZERO # Stop moving to attack
		if current_time - last_attack_time >= attack_cooldown:
			_attack_player()
			last_attack_time = current_time
	
	# State: Chase
	elif distance_to_player <= detection_range:
		_move_toward_player()
		is_moving_to_target = false # Stop patrolling when chasing
	
	# State: Patrol
	else:
		if not move_pattern.is_empty():
			if not is_moving_to_target:
				# Start moving to the next patrol point
				current_pattern_index = (current_pattern_index + 1) % move_pattern.size()
				target_position = global_position + move_pattern[current_pattern_index]
				is_moving_to_target = true

			if global_position.distance_to(target_position) > 5.0:
				var direction = (target_position - global_position).normalized()
				velocity = direction * speed
			else:
				# Arrived at patrol point, wait then move to next
				velocity = Vector2.ZERO
				is_moving_to_target = false
				wait_and_continue_patrol()
		else:
			velocity = Vector2.ZERO # No patrol pattern, so idle

	if not can_move():
		velocity = Vector2.ZERO
	
	move_and_slide()
	_update_animation()

func wait_and_continue_patrol():
	is_stopped = true
	get_tree().create_timer(1.0).timeout.connect(func(): is_stopped = false)
	# The logic in _physics_process will handle picking the next point

func _move_toward_player() -> void:
	if not is_instance_valid(player):
		return
	
	var direction_to_player = _get_direction_to_player()
	velocity = direction_to_player * speed

func _get_direction_to_player() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	
	return (player.global_position - global_position).normalized()

func _attack_player() -> void:
	if not is_instance_valid(player):
		return
	
	# Face the player
	var direction_to_player = _get_direction_to_player()
	if direction_to_player != Vector2.ZERO:
		# This will be handled by _update_animation in the base class
		pass

	# Attack the player
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
		print(name, " attacked ", player.name, " for ", attack_damage, " damage!")

func wait() -> void:
	is_stopped = true
	get_tree().create_timer(1.0).timeout.connect(func(): is_stopped = false)

func trigger_event(direction: Vector2) -> void:
	last_direction = - direction # Face player
	print("NPC Mobile triggered event")
