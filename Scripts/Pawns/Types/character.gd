class_name Character
extends Pawn

@export var speed: float = 1.0
@export var move_duration: float = 0.2  # Duration in seconds to move one tile

var max_health: int = 100
var health: int = max_health
var health_bar: ProgressBar  # Health bar node (can be named "HealthBar" or "ProgressBar")

func _ready():
	# Try to find health bar with either name
	if has_node("HealthBar"):
		health_bar = $HealthBar
	elif has_node("ProgressBar"):
		health_bar = $ProgressBar
	update_health_bar()

var move_tween: Tween
var is_moving: bool = false
var is_talking: bool = false

@onready var chara_skin: Sprite2D = $Skin
@onready var Grid: Node2D = get_parent()

func heal(amount: int) -> void:
	health += amount
	health = clamp(health, 0, max_health)
	update_health_bar()

func take_damage(amount: int) -> void:
	health -= amount
	health = clamp(health, 0, max_health)
	update_health_bar()
	
	if health <= 0:
		die()

func update_health_bar() -> void:
	if health_bar:
		# Use the custom function defined in progressbar.gd
		health_bar.set_health(health, max_health)

func die() -> void:
	print(name, "has died")
	
	# Notify bounty manager if this is an enemy
	_notify_bounty_manager()
	
	# Remove from grid system before freeing
	if Grid and Grid.has_method("remove_pawn_from_grid"):
		Grid.remove_pawn_from_grid(self)
	
	queue_free()  # You can replace this with respawn logic later

func _notify_bounty_manager() -> void:
	# Notify bounty manager that this enemy has died
	var bounty_manager = get_tree().root.get_node_or_null("BountyManager")
	if bounty_manager and bounty_manager.has_method("on_enemy_killed"):
		bounty_manager.on_enemy_killed(self)

func can_move() -> bool:
	return not is_moving and not is_talking

func move_to(target_position: Vector2) -> void:
	# Use a reasonable fixed animation speed (lower = slower animation)
	chara_skin.set_animation_speed(0.5)  # Slower animation speed to prevent fast cycling
	chara_skin.play_walk_animation()
	
	move_tween = create_tween()
	move_tween.connect("finished", _move_tween_done)
	move_tween.tween_property(self, "position", target_position, move_duration)
	is_moving = true

func _move_tween_done() -> void:
	move_tween.kill()
	chara_skin.toggle_walk_side()
	chara_skin.play_idle_animation()
	chara_skin.set_animation_speed(1.0)  # Reset animation speed to normal
	is_moving = false

func set_talking(talk_state: bool) -> void:
	is_talking = talk_state
	
