extends Control

signal restart_game

func _ready():
	hide()

func show_death_screen():
	size = get_viewport_rect().size
	position = Vector2.ZERO
	show()
	get_tree().paused = true
	

func _on_restart_button_pressed():
	get_tree().paused = false
	restart_game.emit()
	hide()
