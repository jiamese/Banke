extends Control

# Node references
@onready var hit_button = $HitButton
@onready var stand_button = $StandButton

# Signal for communicating actions with the Control node
signal player_action(action_type)

func _ready():
	# Connect button signals
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)

# Function to handle Hit button press
func _on_hit_pressed():
	print("Hit button pressed.")
	emit_signal("player_action", "hit")  # Notify the Control node of the action

# Function to handle Stand button press
func _on_stand_pressed():
	print("Stand button pressed.")
	emit_signal("player_action", "stand")  # Notify the Control node of the action
