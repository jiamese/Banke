extends Control

# Game variables
var player_lives = 3
var deck = []
var is_player_standing = false  # Tracks if the player has stood
var battle_active = false  # Tracks if a battle is ongoing
var active_enemy_card = null
var player_turn_active = true
var cards_in_play = {}  # Tracks how many of each card are visible
var tag_out_used = false  # Tracks if the "Tag Out" power-up has been used
var grid = {}  # Tracks all cards and their states
var insight_used = false  # Tracks if the power-up has been used in the current battle
var insurance_active = false  # Tracks if Insurance is activated
var player_currency = 0  # Start with 0 gold
var purchased_power_ups = {
	"insight": false,
	"joker": false,
	"insurance": false
}

signal enemy_destroyed(position)

# Node references
@onready var grid_container = $GridContainer
@onready var player = $Player  # Player node reference
@onready var hit_button = $UI/HitButton
@onready var stand_button = $UI/StandButton
@onready var insight_button = $UI/InsightButton
@onready var insurance_button = $UI/InsuranceButton
@onready var joker_button = $UI/JokerButton
@onready var card_tracker_button = $UI/CardTrackerButton
@onready var card_tracker_screen = $CardTrackerScreen
@onready var tag_out_button = $UI/TagOutButton  # Reference to the Tag Out button
@onready var lives_label = $UI/Lives  # Adjust the path if necessary

# Called when the node is ready
func _ready():
	# Reset the player's hand and prepare for a new game
	player.reset_hand()
	card_tracker_screen.hide()

	if grid_container == null:
		return
	hit_button.disabled = true
	stand_button.disabled = true

	# Initialize the deck and assign cards to grid buttons
	initialize_deck()
	initialize_cards()
	initialize_grid()
	update_lives_display()

	#debug_single_cards()
	#debug_grid()
	# Connect Player and Button signals
	# Connect card_destroyed signal for each SingleCard
	card_tracker_button.pressed.connect(_on_card_tracker_button_pressed)
	player.player_stands.connect(_on_player_stands)
	hit_button.pressed.connect(_on_hit_pressed)
	stand_button.pressed.connect(_on_stand_pressed)
	grid_container.connect("card_clicked", Callable(self, "_on_card_clicked"))
	grid_container.connect("battle_started", Callable(self, "_on_battle_started"))
	insight_button.pressed.connect(_on_insight_button_pressed)
	insight_button.disabled = true  # Disable the button initially
	insurance_button.pressed.connect(_on_insurance_button_pressed)
	joker_button.pressed.connect(_on_joker_button_pressed)
	grid_container.connect("request_card", Callable(self, "_on_request_card"))
	card_tracker_button.pressed.connect(_on_card_tracker_button_pressed)
	card_tracker_screen.cards_in_play = cards_in_play  # Pass the reference
	tag_out_button.pressed.connect(_on_tag_out_button_pressed)

	# Start the game by giving the player their first card
	_on_hit_pressed()


# Function to initialize a full deck with unique card indices
func initialize_deck():
	deck.clear()

	# Add two copies of each card (1 to 52) for a double deck
	for i in range(1, 51):  # Indices 1 to 52
		deck.append(i)
		deck.append(i)
	# Shuffle the deck for randomness
	deck.shuffle()

	# Debug: Check card frequencies
	var card_count = {}
	for card in deck:
		if card in card_count:
			card_count[card] += 1
		else:
			card_count[card] = 1

	print("Deck initialized. Total cards:", deck.size())
	print("Card frequencies:", card_count)



# Function to assign cards across GridContainer based on the deck
func initialize_cards():
	var card_index = 0
	for card_instance in grid_container.get_children():
		if card_instance.has_node("SingleCard"):
			var single_card = card_instance.get_node("SingleCard")
			var row = String(card_instance.name).split("_")[1].to_int()
			if card_index < deck.size() - 1:


				single_card.update_card(deck[card_index], deck[card_index + 3])
				print("Assigned FaceUp:", deck[card_index], "FaceDown:", deck[card_index + 1], "to", card_instance.name)

				# Connect relevant signals
				single_card.connect("total_calculated", self._on_total_calculated)
				single_card.connect("card_clicked", self._on_grid_card_clicked)
			else:
				print("Warning: Not enough cards in the deck for full grid setup.")
				break

			card_index += 2  # Move to the next pair of cards# Move to the next pair of cards



func initialize_grid():
	for col in range(1, 6):  # Columns 1 to 5
		for row in range(1, 6):  # Rows 1 to 5
			var card_name = "C%d_R%d" % [col, row]
			var texture_button = grid_container.get_node(card_name)
			if texture_button:
				# Look for the SingleCard child
				var single_card = texture_button.get_node_or_null("SingleCard")
				if single_card:
						single_card.connect("card_destroyed", Callable(self, "_on_card_destroyed"))
						grid[card_name] = {
							"node": single_card,
							"destroyed": false
						}
						var bust_label = Label.new()

	grid_container.lock_cards()
	grid_container.unlock_cards(grid)


#func debug_single_cards():
#	for card_node in grid_container.get_children():
#		var single_card = card_node.get_node_or_null("SingleCard")
#		if single_card:
#			print("SingleCard found in:", card_node.name)
#		else:
#			print("SingleCard missing in:", card_node.name)

#func debug_grid():
#	print("Grid contents:")
#	for card_name in grid.keys():
#		print("  -", card_name, "->", grid[card_name])

func _on_card_tracker_button_pressed():
	# Toggle visibility of the card tracker screen
	if card_tracker_screen.visible:
		card_tracker_screen.hide()
	else:
		card_tracker_screen.show()

func _on_card_clicked(face_down_card, total_value: int):
	if face_down_card.disabled:
		$UI/FeedbackLabel.text = "This card is blocked and cannot be interacted with!"
		return



	# Disable all cards during the battle
	for button in $GridContainer.get_children():
		button.disabled = true

	start_battle(face_down_card, total_value)


# Function to handle grid card clicks
func _on_grid_card_clicked(enemy_total: int):
	print("Battle initiated with card total:", enemy_total)

	# Compare player and enemy totals
	if player.total_value > enemy_total:
		print("Player wins!")
		end_battle("win")
	elif player.total_value < enemy_total:
		print("Player loses!")
		end_battle("lose")
	else:
		end_battle("tie")

# Function to start a battle
func start_battle(card_node, enemy_total: int):
	battle_active = true


	insight_used = false  # Reset power-up usage for the new battle
	# Get the parent node's name
	var parent_name = card_node.get_parent().name if card_node.get_parent() else "Unknown"

	insight_button.disabled = false


	print("Starting battle with card:", parent_name)

	# Lock other cards except the current one
	grid_container.lock_cards(card_node.get_parent())

	# Player gets an extra card at the start of the battle
	var player_card = draw_card_from_deck()
	player.add_card(player_card)

	# Enable Hit and Stand buttons
	hit_button.disabled = false
	stand_button.disabled = false
	
func show_bust_label(enemy_card: Control):
	if not enemy_card or not enemy_card is TextureButton:
		print("Error: Invalid enemy_card passed to show_bust_label")
		return

	var bust_label = $BustLabel  # Reference the single BUST label
	bust_label.visible = true    # Show the label
	bust_label.text = "BUST"     # Ensure correct text

	# Calculate position above the enemy card
	bust_label.rect_position = enemy_card.rect_global_position + Vector2(
		enemy_card.rect_size.x / 2 - bust_label.rect_size.x / 2, 
		-bust_label.rect_size.y - 10
	)  # Center above the card with an offset


func _on_battle_started(card_node, total_value:int):

	start_battle(card_node, total_value)
	active_enemy_card = card_node
	print("Card node", card_node)
	player_turn_active = true
	print("Card node type:", card_node)



	hit_button.disabled = false
	stand_button.disabled = false

# Function to handle the Hit button during a battle
func _on_hit_pressed():
	print(player.total_value)
	if player.total_value < 21:
		var card_index = draw_card_from_deck()
		player.add_card(card_index)
		add_card_to_play(card_index)  # Track the card as in play

		print ("player total value: ", 	player.total_value)
		if player.total_value > 21:
			print("Player Busts!")
				# Check if insurance is active
			if insurance_active:
				print("Insurance active! No health deducted.")
				end_battle("lose")
			else:
				print("No insurance! Health will be deducted.")
				end_battle("lose")
	else:
		print("Cannot hit. Player's total is already 21 or more.")

# Function to handle the Stand button
func _on_stand_pressed():
	if not player_turn_active:
		print("Player has already stood or no active battle.")
		return

	print("Player stands with total:", player.total_value)
	player_turn_active = false
	hit_button.disabled = true
	stand_button.disabled = true
	
	if active_enemy_card:
		active_enemy_card.reveal_face_up_card()

	
	if is_player_standing:
		print("Player has already stood. Cannot stand again.")
		return

	print("Player chose to stand.")
	player.stand()  # Notify the player to stand
	is_player_standing = true  # Mark the player as standing


func enemy_turn():
	print("Enemy's turn begins.")
	var hand = []
	if active_enemy_card == null:
		print("Error: active_enemy_card is null! Enemy turn aborted.")
		return
	# Reveal the FaceUpCard
	await get_tree().create_timer(2.0).timeout
	if active_enemy_card:
		active_enemy_card.reveal_face_up_card()


	if active_enemy_card == null:
		print("Warning: active_enemy_card is null. Skipping this operation.")
		return hand  # Return an empty hand to proceed safely

	# Check if the required properties exist
	

	hand.append({"value": active_enemy_card.face_up_card_value})  # Get face-up card value
	hand.append({"value": active_enemy_card.face_down_card_value})  # Get face-down card value

	# Calculate the enemy's total
	var enemy_total = active_enemy_card.calculate_total_value(hand)
	print("enemy total: ", enemy_total)
	$UI/EnemyTotalLabel.text = "Enemy Total: %d" % enemy_total

	while enemy_total < 17:
		await get_tree().create_timer(1.0).timeout  # Add delay for visual representation

		# Draw a card from the deck
		var new_card_index = draw_card_from_deck()

		# Call enemy_hit to visually add the card
		active_enemy_card.enemy_hit(new_card_index)

		# Update enemy's total score
		enemy_total += player.get_card_value(new_card_index)
		print("Enemy hits. New total:", enemy_total)
		
				# Update EnemyTotalLabel dynamically
		$UI/EnemyTotalLabel.text = "Enemy Total: %d" % enemy_total
		# Check if the enemy busts
		if enemy_total > 21:
			print("Enemy busts! Player wins.")
			show_bust_label(active_enemy_card)
			# Show BUST label for this enemy
			var bust_label = active_enemy_card.get_node("BustLabel")
			if bust_label:
				bust_label.visible = true
			
			end_battle("win")
			return


	print("Enemy stands with total:", enemy_total)

	# Compare totals
	compare_totals(enemy_total)

func highlight_interactable_cards():
	for card_name in grid.keys():
		var card = grid[card_name]
		if not card["node"].disabled:
			card["node"].modulate = Color(0.5, 1, 0.5)  # Green for interactable
		else:
			card["node"].modulate = Color(1, 1, 1)  # Reset for blocked cards


func update_interactable_cards():
	for card_name in grid.keys():
		var card = grid[card_name]
		var col = int(card_name.split("_")[0].substr(1))  # Column number
		var row = int(card_name.split("_")[1].substr(1))  # Row number

		if row == 1:
			# First row cards are always interactable
			card["node"].disabled = false
			print(card_name, "is interactable (Row 1).")
			continue

		# Check if the card is adjacent to a destroyed card
		var below_card_name = "C%d_R%d" % [col, row - 1]
		var left_card_name = "C%d_R%d" % [col - 1, row]
		var right_card_name = "C%d_R%d" % [col + 1, row]

		var can_interact = false
		if grid.has(below_card_name) and grid[below_card_name]["destroyed"]:
			can_interact = true
		if grid.has(left_card_name) and grid[left_card_name]["destroyed"]:
			can_interact = true
		if grid.has(right_card_name) and grid[right_card_name]["destroyed"]:
			can_interact = true

		# Update the disabled state
		card["node"].disabled = not can_interact
		if can_interact:
			print(card_name, "is interactable (open from adjacent side).")
		else:
			print(card_name, "is blocked.")


# Tracking cards in play


# Add a card to the cards_in_play dictionary
func add_card_to_play(card_index: int):
	if cards_in_play.has(card_index):
		cards_in_play[card_index] += 1
	else:
		cards_in_play[card_index] = 1
	card_tracker_screen.initialize_card_tracker()  # Update the tracker UI dynamically


# Remove a card from the cards_in_play dictionary
func remove_card_from_play(card_index: int):
	if cards_in_play.has(card_index):
		cards_in_play[card_index] -= 1
		if cards_in_play[card_index] <= 0:
			cards_in_play.erase(card_index)
	card_tracker_screen.initialize_card_tracker()  # Update the tracker UI dynamically


func _on_card_destroyed(card_name):
	
	print("Signal received: Card destroyed:", card_name)
	if grid.has(card_name):
		grid[card_name]["destroyed"] = true
		print("Updated grid state for:", card_name)
		
		var reward = 1  # Base reward
		player_currency += reward
		print("Player awarded", reward, "gold. Total gold:", player_currency)

		# Update the game UI with the new currency total

	else:
		print("Error: Card name not found in grid:", card_name)

	var row = String(card_name).split("_")[1].lstrip("R").to_int()  # Extract the row number
	if row == 5:
		print("Player wins! Card in the 5th row destroyed.")
		on_player_wins()
	grid_container.unlock_cards(grid)



func compare_totals(enemy_total: int):
	print("Comparing totals: Player:", player.total_value, "Enemy:", enemy_total)

	if player.total_value > enemy_total:
		print("Player wins!")
		end_battle("win")
	elif player.total_value < enemy_total:
		print("Enemy wins!")
		end_battle("lose")
	else:
		print("It's a tie!")
		end_battle("tie")

# Function to handle when the player stands
func _on_player_stands():
	print("Player stands. Waiting for the enemy's turn.")
	is_player_standing = true
	enemy_turn()
	
# Function to draw a card from the deck
func draw_card_from_deck() -> int:
	if deck.size() > 0:
		var card_index = deck.pop_front()
		add_card_to_play(card_index)  # Track the card as in play
		return card_index

	else:
		print("Deck is empty! Reshuffling...")
		initialize_deck()
		return draw_card_from_deck()  # Retry after reshuffling

# Function to handle the total calculated by SingleCard
func _on_total_calculated(total_value: int):
	print("Total calculated for a card set:", total_value)

func _on_insight_button_pressed():
	if battle_active and not insight_used:
		# Reveal the enemy's face-down extra card
		if active_enemy_card and active_enemy_card.has_node("FaceDownExtraCard"):
			var face_down_extra_card = active_enemy_card.get_node("FaceDownExtraCard")
			face_down_extra_card.visible = false  # Hide the face-down extra card
			var face_up_card = active_enemy_card.get_node("FaceUpCard")
			face_up_card.visible = true  # Show the face-up card

			insight_used = true  # Mark the power-up as used
			insight_button.disabled = true  # Disable the button
			print("Insight activated! Enemy's face-down extra card revealed.")
		else:
			print("Error: No active enemy card or extra card to reveal!")
	else:
		print("Insight power-up unavailable or no battle active!")


func _on_joker_button_pressed():
	print("Joker power-up used!")

	var replaced_count = 0
	for card_name in grid.keys():
		var card_info = grid[card_name]
		if not card_info["destroyed"]:
			var single_card = card_info["node"]

			# Construct the hand for this enemy
			var hand = [
				{"value": single_card.face_up_card_value},
				{"value": single_card.face_down_card_value}
			]
			var enemy_total = single_card.calculate_total_value(hand)

			# Replace cards with a total of 21
			if enemy_total == 21:
				replace_face_up_card(single_card)
				replaced_count += 1

	if replaced_count > 0:
		print(replaced_count, "cards replaced with Joker!")
	else:
		print("No enemy cards with a total of 21 found.")

	# Disable Joker after use
	joker_button.queue_free()

func _on_insurance_button_pressed():
	if not insurance_active:
		insurance_active = true
		print("Insurance activated!")
		$UI/FeedbackLabel.text = "Insurance Activated!"
		insurance_button.disabled = true  # Disable the button after use
	else:
		print("Insurance is already active!")

func _on_tag_out_button_pressed():
	if not tag_out_used:
		print("Tag Out power-up activated!")
		
		# Remove the last card from the player's hand
		player.remove_last_card()

		# Draw a new card
		var new_card = draw_card_from_deck()
		player.add_card(new_card)
		print("Player's card replaced with card index:", new_card)

		# Disable the button after use
		tag_out_button.disabled = true
		tag_out_used = true
	else:
		print("Tag Out power-up already used!")


func reset_power_up_buttons():
	insight_button.disabled = false
	joker_button.disabled = false
	insurance_button.disabled = false
	insight_used = false


func replace_face_up_card(single_card):
	# Draw a new card with a value between 2 and 9
	var new_card_index = draw_card_from_deck_with_restriction()
	
	# Update the FaceUpCard with the new card's texture and value
	if single_card.has_node("FaceUpCard"):
		var face_up_card = single_card.get_node("FaceUpCard")
		face_up_card.texture_normal = single_card.get_card_texture(new_card_index)
		single_card.face_up_card_value = player.get_card_value(new_card_index)
		
		print("Replaced FaceUpCard with a card of value %d." % single_card.face_up_card_value)
	else:
		print("Error: FaceUpCard node not found in SingleCard!")

func draw_card_from_deck_with_restriction() -> int:
	while deck.size() > 0:
		var card_index = draw_card_from_deck()
		var card_value = player.get_card_value(card_index)
		if card_value >= 2 and card_value <= 9:
			return card_index
	
	print("No valid cards available in the deck!")
	return -1  # Return an invalid card index if no valid card is found

func end_battle(result: String):
	print("Battle ended with result:", result)
	print("Remaining lives:", player_lives)
	# Reset battle state
	battle_active = false
	player_turn_active = false
	grid_container.unlock_cards(grid)

	if result == "lose":
		print("Player loses the round. Resetting hand...")
		is_player_standing = false 
		player.total_value = 0
		player.reset_hand()
		
		player.is_standing = false
		
		#Payer gets new hand
		var card_index = draw_card_from_deck()
		print("card index", card_index)
		player.add_card(card_index)
		if not insurance_active:
			player_lives -= 1
			update_lives_display()  # Update the label

			print("Remaining lives:", player_lives)
		else:
			print("Insurance prevented health loss!")
			insurance_active = false  # Disable insurance after use

		
		if player_lives <= 0:
			print("Game over!")
			
		if active_enemy_card:
			await get_tree().create_timer(1.0).timeout  # Add 1-second delay
			active_enemy_card.destroy()
		
	elif result == "win":
		print("Player wins the round!")
		# Destroy the defeated enemy
		is_player_standing = false 
		player.remove_hit_cards()
		
		player.is_standing = false
		$Player.keep_initial_card()



		if active_enemy_card:
			await get_tree().create_timer(1.0).timeout  # Add 1-second delay
			active_enemy_card.destroy()
		
	elif result == "tie":
		# Destroy the defeated enemy
		print("It's a tie!")
		is_player_standing = false 
		player.total_value = 0
		player.reset_hand()
		player.is_standing = false
		
		var card_index = draw_card_from_deck()
		player.add_card(card_index)
		
		if active_enemy_card:
			await get_tree().create_timer(1.0).timeout  # Add 1-second delay
			active_enemy_card.destroy()
	# Disable action buttons
	hit_button.disabled = true
	stand_button.disabled = true
	insight_button.disabled = true
	insight_used = false
	
	# Clear active enemy card
	active_enemy_card = null
	
func on_player_wins():
	# Stop further interactions
	battle_active = false
	print("Player reached the end of the grid!")
#   reset_game()

	# Optionally, disable all cards
	grid_container.lock_cards()

	# Transition to a victory scene or display a win screen

func reset_game():
	print("Resetting game...")

	# Reset player variables
	player.reset_hand()
	player_lives = 3
	player_currency = 0  # Optional: Reset currency if it's part of the game
	battle_active = false
	insight_used = false
	insurance_active = false
	is_player_standing = false
	tag_out_button.disabled = false
	tag_out_used = false
	# Clear grid and reinitialize
	for card_name in grid.keys():
		var card = grid[card_name]["node"]
		if card:
			card.reset()  # Assuming SingleCard has a reset method
	initialize_deck()
	initialize_grid()

	# Reset power-up buttons
	reset_power_up_buttons()

	# Update the UI (e.g., lives, currency)

	# Start a new game
	_on_hit_pressed()

func update_lives_display():
	if lives_label:
		lives_label.text = "Lives: " + str(player_lives)
	else:
		print("Error: LivesLabel node not found!")



