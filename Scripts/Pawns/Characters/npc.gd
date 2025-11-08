extends Character

func _ready():
	# Calls the Character class's _ready() function, 
	# which initializes the health bar using the update_health_bar() method.
	super._ready() 

func trigger_event(direction: Vector2i) -> void:
	if not is_moving:
		chara_skin.set_animation_direction(-direction) # Face player
		print("NPC")
