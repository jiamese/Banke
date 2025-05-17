extends Control

# Constants for sprite sheet layout
var card_width = 36
var card_height = 47
var columns = 13  # Number of usable columns (columns 2 to 14)
var rows = 4  # Number of rows for suits
const SPRITE_SHEET_PATH = "res://Banke Assets/8BitDeckAssets.png"
var hit_cards = []
# Column-specific offsets for precise alignment
var column_offsets = [-2, -2.5, -3, -4.2, -5, -5.9, -6.9, -7.9, -8.9, -9.9, -10, -10.5, -11]
var column_values = [2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, [1, 11]]  # Ace as [1, 11]

# Signals
signal player_stands()  # Emitted when the player chooses to stand

# Player variables
var cards = []  # Stores card indices for the player's hand
var extra_card_values = []  # Stores values of extra cards added dynamically
var total_value = 0  # Total value of the player's hand
var is_standing = false  # Tracks if the player has stood
func reset_hand_with_new_card(new_card_index: int):
	# Remove hit cards but keep the initial card
	remove_hit_cards()

	# Visually keep the initial card but exclude it from the total
	if cards.size() > 0:
		print("Retaining initial card with value:", get_card_value(cards[0]))
	else:
		print("No initial card found!")

	# Clear the total value and reset it to only include the new card
	total_value = 0  # Reset the total to start fresh
	cards.clear()  # Remove all cards from the logical hand

	# Add the new card to the player's hand
	add_card(new_card_index)

	# Update the UI
	$"/root/Control/UI/PlayerTotalLabel".text = "Player Total: %d" % total_value

	print("Hand reset with only the new card. Total value is now:", total_value)

func keep_initial_card():
	# Check if there is an initial card
	if cards.size() > 0:
		print("Retaining initial card with value:", get_card_value(cards[0]))
		# Keep only the initial card in the logical hand
		cards = [cards[0]]

		# Update the player's total to reflect only the initial card
		total_value = get_card_value(cards[0])
	else:
		print("No initial card to retain!")

	# Remove all hit cards visually
	remove_hit_cards()

	# Update the PlayerTotalLabel
	$"/root/Control/UI/PlayerTotalLabel".text = "Player Total: %d" % total_value

	print("Player's hand retained. Total is:", total_value)


func add_card(card_index: int):
	print("Adding card to player's hand:", card_index)

	if is_standing:
		print("Cannot hit. The player has already stood.")
		return

	# Create a new TextureButton for the card
	var card_button = TextureButton.new()
	card_button.texture_normal = get_card_texture(card_index)

	# Increase the card size for visibility
	card_button.custom_minimum_size = Vector2(107.5, 141)  # Adjust size as needed
	card_button.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

	# Add the card to the player's container
	$HBoxContainer.add_child(card_button)

	if cards.size() > 0:  # The initial card is already in the hand
		hit_cards.append(card_button)
	# Add the card to the player's hand
	print("card_index", card_index)
	cards.append(card_index)

	# Update the player's total value
	total_value += get_card_value(card_index)
	print("Player's total value:", total_value)
	
	$"/root/Control/UI/PlayerTotalLabel".text = "Player Total: %d" % total_value

	# Automatically stand if total equals or exceeds 21
	if total_value >= 21:
		print("Player total equals or exceeds 21. Automatically standing.")
		stand()


func remove_hit_cards():
	for card_button in hit_cards:
		if card_button in $HBoxContainer.get_children():
			card_button.queue_free()  # Remove hit cards visually
	hit_cards.clear()  # Clear the list of hit cards

# Function to reset the player's hand
func reset_hand():
	# Clear all cards from the player's hand
	for child in $HBoxContainer.get_children():
		child.queue_free()
	cards.clear()
	total_value = 0
	print("Player's hand reset.")

# Function to handle standing
func stand():
	if is_standing:
		print("Player has already stood. Cannot stand again.")
		return

	print("Player stands with total value:", total_value)
	is_standing = true

	# Emit a signal to notify other systems
	emit_signal("player_stands")


# Function to get the texture of a card using sprite sheet offsets
func get_card_texture(card_index: int) -> Texture:
	var row = int(card_index / columns)  # Determine the row (0 to 3 for suits)
	var column = card_index % columns  # Determine the column (0-based index)

	# Apply column-specific offset
	var x_offset = column_offsets[column] if column < column_offsets.size() else 0

	# Define the region rectangle for the sprite sheet
	var region_rect = Rect2(
		(column * card_width) + x_offset,
		row * card_height,
		card_width,
		card_height
	)

	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload(SPRITE_SHEET_PATH)
	atlas_texture.region = region_rect
	return atlas_texture

# Function to calculate the value of a card
func get_card_value(card_index: int) -> int:
	var column = card_index % columns  # Determine the column (0-based index for card)
	print("column", column)
	var value = column_values[column-1] if column < column_values.size() else 0
	print("column_values", column_values[column])
	# Handle Ace (represented as [1, 11])
	if typeof(value) == TYPE_ARRAY:
		return value[1] if total_value <= 10 else value[0]
	return value

func remove_last_card():
	if cards.size() > 0:
		var removed_card = cards.pop_back()  # Remove the last card
		total_value -= get_card_value(removed_card)
		total_value = max(0, total_value)  # Ensure total value doesn't go negative
		print("Removed card:", removed_card, "New total value:", total_value)

		# Remove the card visually
		$HBoxContainer.get_child($HBoxContainer.get_child_count() - 1).queue_free()



