extends Node2D
var player: CharacterBody2D = null # Reference to the player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func update_player_position():
	print("In saturn, updating position!")
	player.global_position = Vector2(135,-65) + Vector2(-32,0)
