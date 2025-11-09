class_name Character
extends CharacterBody2D


@export var speed: float = 10

var max_health: int = 100
var health: int = max_health
@onready var health_bar: ProgressBar = $HealthBar

var move_tween: Tween
var is_moving: bool = false
var is_talking: bool = false

@onready var chara_skin: Sprite2D = $Skin

func _ready():
	update_health_bar()

func heal(amount: int) -> void:
	health += amount
	health = clamp(health, 0, max_health)
	update_health_bar()

func update_health_bar() -> void:
	if health_bar:
		# Use the custom function defined in progressbar.gd
		health_bar.set_health(health, max_health)

func die() -> void:
	print(name, "has died")
	queue_free() # You can replace this with respawn logic later

func can_move() -> bool:
	return not is_moving and not is_talking

func set_talking(talk_state: bool) -> void:
	is_talking = talk_state
