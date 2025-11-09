extends Character

var dialogue_ui: CanvasLayer
var gemini_api: Node

func _ready() -> void:
	# Use call_deferred to add children after scene setup is complete
	call_deferred("_setup_systems")

func _setup_systems() -> void:
	# Find or create the DialogueUI
	dialogue_ui = get_tree().root.get_node_or_null("DialogueUI")
	if not dialogue_ui:
		# Load and instantiate the dialogue UI
		var dialogue_scene = load("res://Scenes/UI/dialogue_ui.tscn")
		if dialogue_scene:
			dialogue_ui = dialogue_scene.instantiate()
			get_tree().root.add_child(dialogue_ui)

	# Find or create the GeminiAPI
	gemini_api = get_tree().root.get_node_or_null("GeminiAPI")
	if not gemini_api:
		var api_script = load("res://Scripts/API/gemini_api.gd")
		if api_script:
			gemini_api = Node.new()
			gemini_api.set_script(api_script)
			gemini_api.name = "GeminiAPI"
			get_tree().root.add_child(gemini_api)

	# Connect signals
	if dialogue_ui:
		dialogue_ui.dialogue_closed.connect(_on_dialogue_closed)
		dialogue_ui.player_input_submitted.connect(_on_player_input)

	if gemini_api:
		gemini_api.response_received.connect(_on_gemini_response)
		gemini_api.error_occurred.connect(_on_gemini_error)

func trigger_event(direction: Vector2i) -> void:
	if not is_moving:
		chara_skin.set_animation_direction(-direction) # Face player
		start_dialogue()

func start_dialogue() -> void:
	set_talking(true)
	if dialogue_ui:
		dialogue_ui.show_dialogue("Space Barback")

func _on_dialogue_closed() -> void:
	set_talking(false)

func _on_player_input(text: String) -> void:
	if gemini_api:
		gemini_api.generate_space_bar_pun(text)

func _on_gemini_response(response: String) -> void:
	if dialogue_ui:
		dialogue_ui.display_response(response)

func _on_gemini_error(error_msg: String) -> void:
	if dialogue_ui:
		dialogue_ui.display_error(error_msg)
