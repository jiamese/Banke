extends Control

# Variables
var player_cards = []
var enemy_cards = []
var player_total = 0
var enemy_total = 0
var deck = []
var battle_active = false  # Tracks if a battle is ongoing
var player_turn_active = true
var column_values = [2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10, [1, 11]]

# Called when the node enters the scene tree
func _ready():
	initialize_deck()
	deal_initial_cards()
	update_player_ui()
	update_enemy_ui()
	setup_bottom_ui()
# Initialize the deck
	var face_down_card_button = $CenterContainer/CardContainer/FaceDownCard
	if face_down_card_button:
		face_down_card_button.connect("pressed", Callable(self, "_on_FaceDownCard_pressed"))
	else:
		print("Error: FaceDownCard node not found!")


func initialize_deck():
	deck.clear()
	for i in range(1, 53):  # Add 52 cards to the deck
		deck.append(i)
	deck.shuffle()

# Deal initial cards to player and enemy
func deal_initial_cards():
	# Player starts with one card
	add_card_to_player(draw_card())

	# Enemy starts with one face-down and one face-up card
	add_card_to_enemy(draw_card(), false)  # Face-down card
	add_card_to_enemy(draw_card(), true)   # Face-up card

	print("Enemy cards:", enemy_cards)  # This should print two cards

# Draw a card from the deck
func draw_card() -> int:
	if deck.size() > 0:
		return deck.pop_front()
	else:
		print("Deck is empty!")
		return -1

# Add a card to the player's hand
func add_card_to_player(card_index: int):
	player_cards.append(card_index)
	player_total += get_card_value(card_index)

	# Create a new card button
	var card_button = TextureButton.new()
	set_card_texture(card_button, card_index)
	card_button.custom_minimum_size = Vector2(107.5, 141)  # Example size
	card_button.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

	# Add the card to the player's card container
	$VBoxContainer/PlayerCardContainer.add_child(card_button)
	update_player_ui()

# Add a card to the enemy's hand
func add_card_to_enemy(card_index: int, is_face_up: bool):
	enemy_cards.append({"index": card_index, "face_up": is_face_up})
	if is_face_up:
		enemy_total += get_card_value(card_index)

	# Create a new card button
	var card_button = TextureButton.new()
	if is_face_up:
		set_card_texture(card_button, card_index)
	else:
		set_card_back_texture(card_button)
	card_button.custom_minimum_size = Vector2(107.5, 141)  # Example size
	card_button.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

	# Add the card to the enemy's card container
	$CenterContainer/EnemyCardContainer.add_child(card_button)
	update_enemy_ui()

# Get the value of a card
func get_card_value(card_index: int) -> int:
	var column = (card_index - 1) % 13
	var value = column_values[column]
	if typeof(value) == TYPE_ARRAY:
		return value[1] if player_total <= 10 else value[0]
	return value


func _on_FaceDownCard_pressed():
	if battle_active:
		return  # Prevent starting a new battle during an ongoing one
	print("battle works")
	battle_active = true
	player_turn_active = true
	$VBoxContainer/HBoxContainer/HitButton.disabled = false
	$VBoxContainer/HBoxContainer/StandButton.disabled = false
	$VBoxContainer/Label.text = "Battle started! Your turn: Hit or Stand."
	print("Battle started!")

# Update the player's UI
func update_player_ui():
	var player_card_button = $VBoxContainer/PlayerCardContainer/PlayerCard
	set_card_texture(player_card_button, player_cards[-1])
	$VBoxContainer/Label.text = "Player Total: %d" % player_total

# Update the enemy's UI
func update_enemy_ui():
	var enemy_card_container = $CenterContainer/EnemyCardContainer

	# Update the face-down card
	var face_down_card_button = enemy_card_container.get_node_or_null("FaceDownCard")
	if face_down_card_button:
		if enemy_cards.size() > 0 and enemy_cards[0]["face_up"]:
			set_card_texture(face_down_card_button, enemy_cards[0]["index"])  # Reveal the card
		else:
			set_card_back_texture(face_down_card_button)  # Keep it face-down
	else:
		print("Error: FaceDownCard node not found!")

	# Update the face-up card
	var enemy_card_button = enemy_card_container.get_node_or_null("EnemyCard")
	if enemy_card_button:
		if enemy_cards.size() > 1:
			set_card_texture(enemy_card_button, enemy_cards[1]["index"])  # Show face-up card
		else:
			print("Error: No face-up card available in enemy_cards array!")
	else:
		print("Error: EnemyCard node not found!")

	if enemy_cards.size() > 1:
		if enemy_card_button:
			set_card_texture(enemy_card_button, enemy_cards[1]["index"])  # Show the face-up card
		else:
			print("Error: EnemyCard node not found!")
	else:
		print("Error: No face-up card for enemy.")

# Set card texture
func set_card_texture(card_button: TextureButton, card_index: int):
	# Define the sprite sheet layout
	var card_width = 36
	var card_height = 47
	var columns = 13  # Number of usable columns (Ace to King)
	var column_offsets = [-2, -2.5, -3, -4.2, -5, -5.9, -6.9, -7.9, -8.9, -9.9, -10, -10.5, -11]

	# Determine the card's position in the sprite sheet
	var row = int((card_index - 1) / columns)  # Get the row (0 to 3 for suits)
	var column = (card_index - 1) % columns   # Get the column (0-based index)

	# Apply the column offset
	var x_offset = column_offsets[column] if column < column_offsets.size() else 0

	# Define the texture region using the calculated offsets
	var region_rect = Rect2(
		(column * card_width) + x_offset,  # X-coordinate with offset
		row * card_height,                 # Y-coordinate
		card_width,                        # Width of the card
		card_height                        # Height of the card
	)

	# Create an AtlasTexture and assign it to the card button
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://Banke Assets/8BitDeckAssets.png")  # Replace with your sprite sheet path
	atlas_texture.region = region_rect
	card_button.texture_normal = atlas_texture
	card_button.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

# Set card back texture
func set_card_back_texture(card_button: TextureButton):
	# Define the sprite sheet layout
	var card_width = 36
	var card_height = 47
	var column_offsets = [-2, -2.5, -3, -4.2, -5, -5.9, -6.9, -7.9, -8.9, -9.9, -10, -10.5, -11]

	# Use the first column (card back) and its offset
	var x_offset = column_offsets[0]  # Offset for the first column

	# Define the texture region for the card back
	var region_rect = Rect2(
		x_offset,     # X-coordinate with offset
		0,            # Y-coordinate (first row for suits)
		card_width,   # Width of the card
		card_height   # Height of the card
	)

	# Create an AtlasTexture and assign it to the card button
	var atlas_texture = AtlasTexture.new()
	atlas_texture.atlas = preload("res://Banke Assets/8BitDeckAssets.png")  # Replace with your sprite sheet path
	atlas_texture.region = region_rect
	card_button.texture_normal = atlas_texture
	card_button.stretch_mode = TextureButton.StretchMode.STRETCH_KEEP_ASPECT_CENTERED

func reveal_enemy_cards():
	for card in enemy_cards:
		if not card["face_up"]:
			card["face_up"] = true
			enemy_total += get_card_value(card["index"])
	update_enemy_ui()




# Enemy's turn logic
func enemy_turn():
	reveal_enemy_cards()
	while enemy_total < 17:
		add_card_to_enemy(draw_card(), true)  # Enemy draws a card face-up
		await get_tree().create_timer(1.0).timeout

		if enemy_total > 21:
			$VBoxContainer/Label.text = "Enemy busted! You win!"
			battle_active = false
			return

	compare_totals()


# Compare totals
func compare_totals():
	if player_total > enemy_total:
		$VBoxContainer/Label.text = "You win! Your total: %d. Enemy total: %d." % [player_total, enemy_total]
	elif player_total < enemy_total:
		$VBoxContainer/Label.text = "You lose! Your total: %d. Enemy total: %d." % [player_total, enemy_total]
	else:
		$VBoxContainer/Label.text = "It's a tie! Your total: %d. Enemy total: %d." % [player_total, enemy_total]
	disable_buttons()

# Disable buttons
func disable_buttons():
	$VBoxContainer/HBoxContainer/HitButton.disabled = true
	$VBoxContainer/HBoxContainer/StandButton.disabled = true

func setup_bottom_ui():
	var vbox = $VBoxContainer

	# Set anchors to bottom-center
	vbox.anchor_left = 0.5
	vbox.anchor_top = 1.0
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 1.0

	# Get the size of the VBoxContainer
	var size = vbox.get_rect().size

	# Adjust offsets to center it horizontally and position above the bottom
	vbox.offset_left = -size.x / 2
	vbox.offset_top = -size.y
	vbox.offset_right = size.x / 2
	vbox.offset_bottom = 0


func _on_hit_button_pressed():
	print("Hit button pressed!")
	if player_turn_active:
		add_card_to_player(draw_card())

		# Check if the player busts
		if player_total > 21:
			$VBoxContainer/Label.text = "You busted! Total: %d. Try again!" % player_total
			disable_buttons()
			battle_active = false

func _on_Stand_pressed():
	print("Stand button pressed!")
	if player_turn_active:
		player_turn_active = false  # End the player's turn
		$VBoxContainer/HBoxContainer/HitButton.disabled = true
		$VBoxContainer/HBoxContainer/StandButton.disabled = true

		# Reveal the enemy's face-down card
		reveal_face_down_card()

		# Start the enemy's turn
		$VBoxContainer/Label.text = "You stood with a total of %d. Enemy's turn!" % player_total
		enemy_turn()


func reveal_face_down_card():
	var face_down_card_button = $CenterContainer/EnemyCardContainer/FaceDownCard
	if face_down_card_button:
		# Set the face-up texture for the face-down card
		set_card_texture(face_down_card_button, enemy_cards[0]["index"])
		enemy_cards[0]["face_up"] = true  # Mark the card as face-up

		# Add the face-down card's value to the enemy's total
		enemy_total += get_card_value(enemy_cards[0]["index"])
		update_enemy_ui()
		print("Enemy's face-down card revealed. Total:", enemy_total)
	else:
		print("Error: FaceDownCard node not found!")
