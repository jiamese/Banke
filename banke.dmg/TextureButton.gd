extends Control

# Game variables
var player_lives = 3
var player_hand = []  # Array to store player cards
var selected_enemy_hand = []  # Array to store selected enemy cards
var selected_enemy = null  # To keep track of the selected enemy

# Called when the node is ready
func _ready():
	var grid_container = $GridContainer  # Assuming GridContainer holds all the SingleCard nodes

	# Check if GridContainer exists
	if grid_container == null:
		return
	else:
		print("GridContainer found, proceeding...")

	# Iterate over each SingleCard instance in the GridContainer and connect the CardButton's signal
	for single_card in grid_container.get_children():
		var card_button = single_card.get_node("CardButton")  # Get the CardButton from each SingleCard
		if card_button:
			# Connect the CardButton's pressed signal to _on_card_clicked function
			card_button.pressed.connect(self._on_card_clicked)
			print("Connected CardButton in: ", single_card.name)

# When a card is clicked
func _on_card_clicked():
	var button = get_tree().get_current_scene().get_focus_owner()  # Get the clicked button (CardButton)
	var card_value = button.get_meta("value")  # Get the card's value from metadata (if available)
	print("Card clicked with value:", card_value)

	# Set the clicked card as the selected enemy and store the value
	selected_enemy = button
	selected_enemy_hand = [{ "value": card_value }]
 
	# Example: Player's hand is randomly generated
	player_hand = [random_card(), random_card()]

	print("Player hand:", player_hand)

# Function to randomly generate a card
func random_card() -> Dictionary:
	var card_value = randi() % 13 + 1  # Random value between 1 (Ace) and 13 (King)
	return { "value": card_value }
