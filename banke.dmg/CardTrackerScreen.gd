extends Control

# Card counts for the tracker
var card_counts = {}

# Constants for card textures
const SPRITE_SHEET_PATH = "res://Banke Assets/8BitDeckAssets.png"
var card_width = 36
var card_height = 47
var columns = 13

@onready var tracker_container = $Panel/VBoxContainer
@onready var close_button = $Panel/CloseButton

# Initialize the card tracker
func _ready():
	initialize_card_counts()  # Initialize counts if not passed from the main game
	close_button.pressed.connect(_on_close_button_pressed)
	initialize_card_tracker()

# Populate card counts
func initialize_card_counts():
	for i in range(52):  # Assuming 52 unique cards in a deck
		card_counts[i] = 2  # Double deck (2 of each card)

# Populate the card tracker UI
func initialize_card_tracker():
	tracker_container.clear_children()  # Clear any existing children

	for card_index in card_counts.keys():
		var card_hbox = HBoxContainer.new()

		# Card sprite
		var card_sprite = TextureRect.new()
		card_sprite.texture = get_card_texture(card_index)
		card_sprite.custom_minimum_size = Vector2(72, 94)
		card_sprite.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

		# Card count label
		var card_count_label = Label.new()
		card_count_label.text = str(card_counts[card_index])

		# Add to HBoxContainer
		card_hbox.add_child(card_sprite)
		card_hbox.add_child(card_count_label)

		# Add to VBoxContainer
		tracker_container.add_child(card_hbox)

# Retrieve card texture
func get_card_texture(card_index: int) -> Texture:
	var row = int(card_index / columns)
	var column = card_index % columns
	var region_rect = Rect2(column * card_width, row * card_height, card_width, card_height)

	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload(SPRITE_SHEET_PATH)
	atlas_texture.region = region_rect
	return atlas_texture

# Handle closing the tracker screen
func _on_close_button_pressed():
	hide()
