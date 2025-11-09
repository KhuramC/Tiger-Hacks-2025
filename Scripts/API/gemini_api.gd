extends Node

signal response_received(response: String)
signal error_occurred(error_msg: String)

const GEMINI_API_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

var api_key: String = ""
var http_request: HTTPRequest

func _ready() -> void:
	# Load API key from environment or config file
	# You'll need to set this before using the API
	load_api_key()

	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func load_api_key() -> void:
	# Try to load from a config file (not tracked in git)
	var config_path = "res://api_config.cfg"
	var config = ConfigFile.new()
	var err = config.load(config_path)

	if err == OK:
		api_key = config.get_value("gemini", "api_key", "")

	# If still empty, check environment variable
	if api_key.is_empty():
		api_key = OS.get_environment("GEMINI_API_KEY")

	if api_key.is_empty():
		push_warning("Gemini API key not found. Please set GEMINI_API_KEY environment variable or create api_config.cfg")

func generate_space_bar_pun(user_prompt: String) -> void:
	if api_key.is_empty():
		error_occurred.emit("API key not configured")
		return

	var system_instruction = """You are a witty barback working at a space-themed bar called 'The Cosmic Cantina'.
Your job is to respond to customers with clever space-themed and bar-related puns.
No matter what the customer says, always respond with a space or astronomy pun related to bars, drinks, or bartending.
Keep responses short (1-3 sentences) and always stay in character as a friendly space barback.
Examples:
- Customer: "I'm thirsty" → "Well, you've come to the right nebula! How about a Milky Way Martini to quench that cosmic thirst?"
- Customer: "What do you have?" → "We've got drinks that are out of this world! Our Supernova Shots will really launch you into orbit!"
- Customer: "Hello" → "Welcome to the Cosmic Cantina! I'm your barback, and I'm here to make sure your night is meteor than average!"
"""

	var prompt = system_instruction + "\n\nCustomer says: \"" + user_prompt + "\"\n\nBarback responds:"

	var request_body = {
		"contents": [{
			"parts": [{
				"text": prompt
			}]
		}]
	}

	var json_body = JSON.stringify(request_body)
	var headers = [
		"Content-Type: application/json"
	]

	var url = GEMINI_API_URL + "?key=" + api_key

	var error = http_request.request(url, headers, HTTPClient.METHOD_POST, json_body)

	if error != OK:
		error_occurred.emit("Failed to send request")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		error_occurred.emit("Request failed")
		return

	if response_code != 200:
		error_occurred.emit("API returned error: " + str(response_code))
		return

	var json = JSON.new()
	var parse_result = json.parse(body.get_string_from_utf8())

	if parse_result != OK:
		error_occurred.emit("Failed to parse response")
		return

	var response_data = json.data

	# Extract the text from Gemini's response
	if response_data.has("candidates") and response_data.candidates.size() > 0:
		var candidate = response_data.candidates[0]
		if candidate.has("content") and candidate.content.has("parts") and candidate.content.parts.size() > 0:
			var text = candidate.content.parts[0].text
			response_received.emit(text)
		else:
			error_occurred.emit("Unexpected response format")
	else:
		error_occurred.emit("No response from AI")
