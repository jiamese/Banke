extends Control

# Card counts for the tracker
var card_counts = {}
var column_offsets = [-2, -2.5, -3, -4.2, -5, -5.9, -6.9, -7.9, -8.9, -9.9, -10, -10.5, -11]
var column_values = [2, 3, 4, 5, 6, 7, 8, 9, 10, "J", "Q", "K", [1, 11]]  # Ace is [1, 11]
var cards_in_play: Dictionary = {}

# Constants for card textures
const SPRITE_SHEET_PATH = "res://Banke Assets/8BitDeckAssets.png"
const card_width = 36
const card_height = 47
const columns = 13  # Number of cards in each row of the sprite sheet

# Node references
@onready var tracker_container = $CardContainer  # Update path if needed
@onready var close_button = $CloseButton


func _ready():
	# Ensure card counts are initialized
	initialize_card_counts()
	
	if tracker_container:
		print("Tracker Container found:", tracker_container.name)
	else:
		print("Error: Tracker Container not found!")
	# Connect the close button signal
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
	else:
		print("Error: CloseButton not found!")

	# Populate the card tracker
	if tracker_container:
		initialize_card_tracker()
	else:
		print("Error: VBoxContainer (tracker_container) not found!")

# Initialize card counts (e.g., 2 decks with 52 unique cards)
func initialize_card_counts():
	for i in range(52):  # Assuming a standard 52-card deck
		card_counts[i] = 2  # Double deck: two of each card

# Populate the card tracker UI
func initialize_card_tracker():
	# Clear the existing tracker UI
	for child in tracker_container.get_children():
		child.queue_free()

	for card_index in card_counts.keys():
		var remaining_cards = card_counts[card_index] - cards_in_play.get(card_index, 0)

		# Create a container for the card and its count
		var card_hbox = HBoxContainer.new()

		# Display the card sprite
		var card_sprite = TextureRect.new()
		card_sprite.texture = get_card_texture(card_index)
		card_sprite.custom_minimum_size = Vector2(72, 94)
		card_sprite.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
		card_sprite.modulate = Color(0.5, 0.5, 0.5) if remaining_cards <= 0 else Color(1, 1, 1)

		# Display the count of remaining cards
		var card_count_label = Label.new()
		card_count_label.text = str(remaining_cards)

		# Add the sprite and count to the container
		card_hbox.add_child(card_sprite)
		card_hbox.add_child(card_count_label)
		tracker_container.add_child(card_hbox)



func get_offset_for_card_value(card_value) -> float:
	var index = column_values.find(card_value)
	if index == -1:
		print("Error: Card value not found in column_values:", card_value)
		return 0.0
	return column_offsets[index]

# Retrieve card texture based on card index
func get_card_texture(card_index: int) -> Texture:
	# Determine card value and corresponding offset
	var row = int(card_index / columns)  # No change needed for rows
	var column = card_index % columns  # Use all 13 columns for indexing
	var card_value = column_values[column]
	var offset = get_offset_for_card_value(card_value)

	# Skip the first column explicitly
	var region_rect = Rect2(
		(column + 1) * card_width + offset,  # +1 skips the first column
		row * card_height,
		card_width,
		card_height
	)

	# Create and return the texture
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload(SPRITE_SHEET_PATH)
	atlas_texture.region = region_rect
	return atlas_texture


# Handle closing the tracker screen
func _on_close_button_pressed():
	print("Closing tracker screen...")
	hide()
