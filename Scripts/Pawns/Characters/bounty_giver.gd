extends Character

# Bounty Giver NPC - Assigns bounties when interacted with

var bounty_manager: Node = null
var dialogue_ui: CanvasLayer = null
var hint_label: Label = null
var player: Node2D = null
var detection_range: int = 3  # Distance in tiles to show hint

func _ready() -> void:
	super._ready()
	
	# Create hint label
	_create_hint_label()
	
	# Find player
	_find_player()
	
	# Use call_deferred to avoid blocking during _ready()
	call_deferred("_setup_systems")

func _setup_systems() -> void:
	# Find or create the BountyManager
	bounty_manager = get_tree().root.get_node_or_null("BountyManager")
	if not bounty_manager:
		# Create bounty manager
		var manager_script = load("res://Scripts/Game/bounty_manager.gd")
		if manager_script:
			bounty_manager = Node.new()
			bounty_manager.set_script(manager_script)
			bounty_manager.name = "BountyManager"
			get_tree().root.add_child(bounty_manager)
			# Wait for bounty manager to be ready
			await get_tree().process_frame
	
	# Find or create the DialogueUI
	dialogue_ui = get_tree().root.get_node_or_null("DialogueUI")
	if not dialogue_ui:
		var dialogue_scene = load("res://Scenes/UI/dialogue_ui.tscn")
		if dialogue_scene:
			dialogue_ui = dialogue_scene.instantiate()
			get_tree().root.add_child(dialogue_ui)

func trigger_event(direction: Vector2i) -> void:
	if not is_moving:
		chara_skin.set_animation_direction(-direction)  # Face player
		# Hide hint when interacting
		if hint_label:
			hint_label.visible = false
		assign_bounty()

func assign_bounty() -> void:
	# Make sure bounty manager is set up
	if not bounty_manager:
		# Try to find it again
		bounty_manager = get_tree().root.get_node_or_null("BountyManager")
		if not bounty_manager:
			print("Bounty Giver: Bounty manager not found!")
			return
	
	# Make sure bounty manager has the assign_bounty method
	if not bounty_manager.has_method("assign_bounty"):
		print("Bounty Giver: Bounty manager not ready yet!")
		return
	
	# Check if there's already an active bounty
	var current_bounty = bounty_manager.get_current_bounty()
	if current_bounty and is_instance_valid(current_bounty):
		# There's already an active bounty - show message
		if dialogue_ui:
			var message = "You already have an active bounty! Eliminate " + current_bounty.name + " first before requesting a new one."
			dialogue_ui.show_message("Bounty Master", message, true, 3.0)
		return
	
	# Assign a new bounty (this will spawn enemies and assign bounty)
	bounty_manager.assign_bounty()
	
	# Wait a moment for bounty to be assigned
	await get_tree().create_timer(0.2).timeout
	var bounty_target = bounty_manager.get_current_bounty()
	
	# Show message with auto-close
	if dialogue_ui:
		if bounty_target:
			var message = "I've marked a target for you. Find and eliminate them to earn a point!\n\nTarget: " + bounty_target.name
			dialogue_ui.show_message("Bounty Master", message, true, 4.0)
		else:
			var message = "I'm preparing a new bounty for you. Come back in a moment!"
			dialogue_ui.show_message("Bounty Master", message, true, 3.0)
	else:
		print("Bounty Giver: New bounty assigned!")


func _create_hint_label() -> void:
	# Create a floating hint label above the NPC
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = "Press the accept button\nto request a bounty"
	hint_label.position = Vector2(-50, -40)  # Position above the NPC
	hint_label.size = Vector2(100, 35)
	hint_label.add_theme_color_override("font_color", Color(1, 1, 0.8, 1))  # Light yellow text
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	hint_label.add_theme_constant_override("outline_size", 4)
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.visible = false
	hint_label.z_index = 100  # Make sure it appears above other sprites
	
	# Create a background panel for better visibility
	var panel = Panel.new()
	panel.name = "HintPanel"
	panel.position = Vector2(-55, -45)
	panel.size = Vector2(110, 40)
	panel.modulate = Color(0, 0, 0, 0.8)  # Semi-transparent black background
	panel.z_index = 99
	
	add_child(panel)
	add_child(hint_label)

func _find_player() -> void:
	# Find the player in the scene
	if Grid:
		var pawns = Grid.get_children()
		for pawn in pawns:
			if pawn.name == "Player":
				player = pawn
				break
			# Check if it's a player by checking for type property
			var type_value = pawn.get("type")
			if type_value != null and type_value == CELL_TYPES.ACTOR and pawn != self:
				# Check if it's the player (CharacterBody2D with type ACTOR)
				if pawn is CharacterBody2D:
					player = pawn
					break

func _process(_delta) -> void:
	# Check player proximity and show/hide hint
	if not player:
		_find_player()
	
	if player and is_instance_valid(player) and hint_label:
		# Calculate distance to player
		var actor_grid = Grid.actor_grid
		if actor_grid:
			var npc_cell: Vector2i = actor_grid.local_to_map(position)
			var player_cell: Vector2i = actor_grid.local_to_map(player.position)
			var cell_diff: Vector2i = player_cell - npc_cell
			var tiles_to_player: int = max(abs(cell_diff.x), abs(cell_diff.y))  # Chebyshev distance
			
			# Show hint if player is within range
			if tiles_to_player <= detection_range:
				hint_label.visible = true
			else:
				hint_label.visible = false
		else:
			# Fallback: use direct distance
			var distance = position.distance_to(player.position)
			if distance <= detection_range * 32:  # Assuming 32 pixels per tile
				hint_label.visible = true
			else:
				hint_label.visible = false
	else:
		if hint_label:
			hint_label.visible = false
