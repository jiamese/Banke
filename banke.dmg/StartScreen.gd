extends Control

@onready var start_button = $StartButton
@onready var quit_button = $QuitButton

func _ready():
	# Connect button signals (if not auto-connected)
	start_button.pressed.connect(_on_start_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)

func _on_start_button_pressed():
	print("Start button pressed!")
	get_tree().change_scene_to_file("res://control.tscn")  # Replace with your main game scene path

func _on_quit_button_pressed():
	print("Quit button pressed!")
	get_tree().quit()



func _on_button_pressed():
	get_tree().change_scene_to_file("res://tutorial_scene.tscn")  # Replace with your main game scene path
	pass # Replace with function body.
