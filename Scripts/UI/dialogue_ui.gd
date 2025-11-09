extends CanvasLayer

signal dialogue_closed
signal player_input_submitted(text: String)

@onready var dialogue_panel: Panel = $DialoguePanel
@onready var npc_label: Label = $DialoguePanel/VBoxContainer/NPCLabel
@onready var player_input: LineEdit = $DialoguePanel/VBoxContainer/PlayerInput
@onready var response_label: RichTextLabel = $DialoguePanel/VBoxContainer/ResponseLabel
@onready var close_button: Button = $DialoguePanel/VBoxContainer/CloseButton

var is_waiting_for_response: bool = false

func _ready() -> void:
	hide_dialogue()
	close_button.pressed.connect(_on_close_pressed)
	player_input.text_submitted.connect(_on_text_submitted)

func show_dialogue(npc_name: String) -> void:
	dialogue_panel.show()
	npc_label.text = npc_name
	response_label.text = "What can I get you?"
	player_input.text = ""
	player_input.editable = true
	player_input.grab_focus()
	is_waiting_for_response = false

func hide_dialogue() -> void:
	dialogue_panel.hide()
	dialogue_closed.emit()

func _on_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty() or is_waiting_for_response:
		return

	is_waiting_for_response = true
	player_input.editable = false
	response_label.text = "The barback looks at you with a smirk..."
	player_input_submitted.emit(text)

func display_response(response: String) -> void:
	response_label.text = response
	player_input.text = ""
	player_input.editable = true
	player_input.grab_focus()
	is_waiting_for_response = false

func display_error(error_msg: String) -> void:
	response_label.text = "[color=red]Error: " + error_msg + "[/color]"
	player_input.editable = true
	player_input.grab_focus()
	is_waiting_for_response = false

func _on_close_pressed() -> void:
	hide_dialogue()
