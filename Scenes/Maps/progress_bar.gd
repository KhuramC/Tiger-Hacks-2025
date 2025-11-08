extends ProgressBar


@export var show_text: bool = true  # Toggle showing "health/max" text
@export var low_health_color: Color = Color(1, 0.2, 0.2)  # red
@export var mid_health_color: Color = Color(1, 0.8, 0.2)  # yellow
@export var full_health_color: Color = Color(0.2, 1, 0.2) # green
@onready var label: Label = $Label

# Called once the bar and its children are ready
func _ready():
	value = max_value  # start full (e.g. 100)
	_update_color()

func set_health(current_health: int, max_health: int):
	value = current_health
	max_value = max_health
	_update_color()
	
	if show_text and is_instance_valid(label):
		label.text = str(current_health, " / ", max_health)
	elif is_instance_valid(label):
		label.text = ""

# Internal: change bar color based on percentage
func _update_color():
	var percent = value / float(max_value)
	var color: Color
	
	if percent > 0.6:
		color = full_health_color
	elif percent > 0.3:
		color = mid_health_color
	else:
		color = low_health_color
	
	# Apply color if using a StyleBoxFlat theme
	var style = get("theme_override_styles/fill")
	if style and style is StyleBoxFlat:
		style.bg_color = color
