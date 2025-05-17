extends Control

# Signals
signal face_down_extra_pressed()  # Emitted when FaceDownExtraCard is pressed
signal total_calculated(total_value)  # Sends the combined total value of the face-up and face-down cards
signal card_clicked(face_down_card, total_value)
signal card_revealed(total_value)
signal card_destroyed(card_name)
# Constants for the card sprite sheet layout
var card_width = 36
var card_height = 47
var columns = 13  # Number of usable columns (columns 2 to 14)
var rows = 4
const SPRITE_SHEET_PATH = "res://Banke Assets/8BitDeckAssets.png"
var desired_size = Vector2(107.5, 141)  # Example size, adjust as needed

# Offset array for individual column adjustments
var column_offsets = [-2, -2.5, -3, -4.2, -5, -5.9, -6.9, -7.9, -8.9, -9.9, -10, -10.5, -11]
var column_values = [2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, [1, 11]]  # Ace represented as [1, 11]

# Store the specific indices and values of the cards
var face_up_card_index: int = -1
var face_down_card_index: int = -1
var face_up_card_value = 0
var face_down_card_value = 0
var extra_card_value = 0  # Value for the extra card

# Function to set the sprite and value of a card based on its index
func set_card_sprite(card_instance: TextureButton, card_index: int) -> int:
	var row = int(card_index / columns)
	var column = (card_index % columns) + 1
	var x_offset = column_offsets[column - 1] if column - 1 < column_offsets.size() else 0.0

	var region_rect = Rect2(column * card_width + x_offset, row * card_height, card_width, card_height)
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload(SPRITE_SHEET_PATH)
	atlas_texture.region = region_rect
	card_instance.texture_normal = atlas_texture
	card_instance.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED  # Godot 4 enum

	var value = column_values[column - 1] if column - 1 < column_values.size() else 0
	return value[0] if typeof(value) == TYPE_ARRAY else value

# Function to set the sprite of FaceDownExtraCard as the back of the card (column 0, row 0)
func set_face_down_extra_sprite(card_instance: TextureButton):
	var region_rect = Rect2(0, 0, card_width, card_height)  # First column, first row
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload(SPRITE_SHEET_PATH)
	atlas_texture.region = region_rect
	card_instance.texture_normal = atlas_texture
	card_instance.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED  # Godot 4 enum

# Function to initialize both the face-up, face-down, and extra face-down cards
func update_card(face_up_index: int, extra_card_index: int):
	face_up_card_index = face_up_index
	face_down_card_index = face_up_index + 1  # The next card in sequence for the face-down card
	extra_card_value = extra_card_index

	var face_up_card = $FaceUpCard
	var face_down_card = $FaceDownCard
	var face_down_extra_card = $FaceDownExtraCard

	if face_up_card == null or face_down_card == null or face_down_extra_card == null:
		print("Error: One of the card nodes (FaceUpCard, FaceDownCard, FaceDownExtraCard) not found in SingleCard!")
		return

	face_up_card_value = set_card_sprite(face_up_card, face_up_card_index)
	face_down_card_value = set_card_sprite(face_down_card, face_down_card_index)
	set_face_down_extra_sprite(face_down_extra_card)  # Set FaceDownExtraCard to back of card

	face_up_card.visible = false  # Hide face-up initially
	face_down_card.visible = true  # Show face-down initially
	face_down_card.disabled = true  # Make FaceDownCard unclickable
	face_down_extra_card.visible = true  # Show extra face-down initially

	# Connect the pressed signal of FaceDownExtraCard to handle flipping
	face_down_extra_card.pressed.connect(self._on_face_down_extra_card_pressed)

# Called when the node is ready
func _ready():
	
	if $FaceDownExtraCard:
		$FaceDownExtraCard.connect("pressed", Callable(self, "_on_face_down_extra_card_pressed"))

	else:
		print("Error: FaceDownExtraCard not found!")
	# Set the desired size for the buttons

	
	# Ensure initial visibility of both cards and position adjustments
	var face_up_card = $FaceUpCard
	var face_down_card = $FaceDownCard
	var face_down_extra_card = $FaceDownExtraCard

	if face_up_card:
		face_up_card.set_size(desired_size)  # Godot 4 uses set_size()
		face_up_card.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
		face_up_card.visible = false

	if face_down_card:
		face_down_card.set_size(desired_size)  # Adjust size in Godot 4
		face_down_card.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
		face_down_card.visible = true
		face_down_card.position.x += 100  # Move the face-down card 100 pixels to the right
		face_down_card.disabled = true  # Make sure FaceDownCard is unclickable
	else:
		print("Error: FaceDownCard node not found in SingleCard!")

	if face_down_extra_card:
		face_down_extra_card.set_size(desired_size)  # Adjust size in Godot 4
		face_down_extra_card.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED
		face_down_extra_card.visible = true
		face_down_extra_card.position.x += 50  # Move the extra face-down card 50 pixels to the right
	else:
		print("Error: FaceDownExtraCard node not found in SingleCard!")

	if $FaceDownExtraCard:
		$FaceDownExtraCard.connect("pressed", Callable(self, "_on_face_down_extra_card_pressed"))
	else:
		print("Error: FaceDownExtraCard not found in SingleCard!")
# Function to handle revealing the face-down extra card and calculating the total
func _on_face_down_extra_card_pressed():
	print("FaceDownExtraCard clicked. Disabling it.")
	
	# Disable this card to prevent further interaction
	$FaceDownExtraCard.disabled = true

	# Collect the card values (replace these with actual retrieval logic)
	var hand = []
	hand.append({"value": face_down_card_value})  # Example: Add the face-down card value
	hand.append({"value": extra_card_value})     # Example: Add the extra card value

	# Calculate the total value
	var total_value = calculate_total_value(hand)

	# Emit a signal with the total value of this card
	emit_signal("card_clicked", self, total_value)

	print("FaceDownExtraCard total value:", total_value)


func destroy():
	
	if get_parent():
		var parent_name = get_parent().name
		print("Destroying enemy cards for:", parent_name)
		print("Destroying enemy cards for:", name)

	# Hide the FaceDownExtraCard and FaceDownCard
		$FaceDownExtraCard.visible = false
		$FaceDownCard.visible = false
		$FaceUpCard.visible = false
	
	# Notify the parent (Control) to update interactable cards
		emit_signal("card_destroyed", parent_name)
		print("Signal emitted for:", parent_name)


		$"/root/Control/UI/EnemyTotalLabel".text = "Enemy Total: 0"  # Reset the label

	else:
		print("Error: SingleCard has no parent.")
	var hbox = get_node_or_null("HBoxContainer")
	if hbox:
		for child in hbox.get_children():
			child.queue_free()
		print("All dynamically added cards removed from HBoxContainer.")
	else:
		print("Error: HBoxContainer not found in SingleCard!")
# Reveal the FaceUpCard after the player stands
func reveal_face_up_card():
	print("Revealing FaceUpCard for:", name)
	$FaceDownExtraCard.visible = false  # Hide the FaceDownExtraCard
	$FaceUpCard.visible = true         # Show the FaceUpCard

	var control = get_parent().get_parent()  # Reference Control node

	# Collect the card values (replace these with actual retrieval logic)
	var hand = []
	hand.append({"value": face_up_card_value})  # Example: Add the face-up card value
	hand.append({"value": face_down_card_value})  # Example: Add the face-down card value

	# Calculate and emit the total value of the revealed card
	var total_value = calculate_total_value(hand)
	emit_signal("card_revealed", total_value)

	print("Revealed card with total value:", total_value)

func get_card_texture(card_index: int) -> Texture:
	# Determine the row and column for the card in the sprite sheet
	var row = int(card_index / columns)  # Determine the row (0 to 3 for suits)
	var column = card_index % columns  # Determine the column (0-based index)

	# Apply column-specific offset (if necessary)
	var x_offset = column_offsets[column] if column < column_offsets.size() else 0

	# Define the region rectangle for the sprite sheet
	var region_rect = Rect2(
		(column * card_width) + x_offset,
		row * card_height,
		card_width,
		card_height
	)

	# Create and return the AtlasTexture
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload(SPRITE_SHEET_PATH)  # Ensure SPRITE_SHEET_PATH is set correctly
	atlas_texture.region = region_rect
	return atlas_texture


func enemy_hit(card_index: int):
	# Create a new TextureButton to represent the new card
	var new_card = TextureButton.new()
	new_card.texture_normal = get_card_texture(card_index)  # Get the texture for the drawn card
	new_card.custom_minimum_size = desired_size # Adjust card size as needed
	new_card.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

	# Add the new card to the enemy's container
	$HBoxContainer.add_child(new_card)

	var control = get_parent().get_parent()  # Reference Control node

	# Optional: Add a delay to simulate animation
	await get_tree().create_timer(0.5).timeout

	print("Enemy hits and visually adds card with index:", card_index)


func calculate_total_value(hand: Array) -> int:
	var total = 0
	var ace_count = 0

	# Sum all non-Ace cards and count Aces
	for card in hand:
		if card["value"] == 1:  # Ace
			ace_count += 1
			total += 11  # Start by treating Ace as 11
		elif card["value"] > 10:  # Face cards (King, Queen, Jack)
			total += 10
		else:
			total += card["value"]

	# Adjust Aces if total exceeds 21
	while total > 21 and ace_count > 0:
		total -= 10  # Convert one Ace from 11 to 1
		ace_count -= 1

	return total
	
func reset():
	# Reset visibility of the cards
	$FaceUpCard.visible = false
	$FaceDownCard.visible = true
	$FaceDownExtraCard.visible = true

	# Reset any values associated with the card
	face_up_card_index = -1
	face_down_card_index = -1
	face_up_card_value = 0
	face_down_card_value = 0
	extra_card_value = 0

	# Re-enable interaction
	$FaceDownExtraCard.disabled = false
	$FaceDownCard.disabled = true  # Default to FaceDownCard being disabled
	print("Card reset:", name)



