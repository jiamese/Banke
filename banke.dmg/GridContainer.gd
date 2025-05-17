extends GridContainer

# Declare a signal to request a card
signal request_card

# Store the currently active card
var active_card = null

@onready var control = get_parent()

signal battle_started(card_node, total_value)

func _ready():
	

	
	initialize_cards()
	control.connect("battle_ended",Callable(self, "_on_battle_ended"))
	

func initialize_cards():
	print("Initializing cards...")

	for button in get_children():
		if button.has_node("SingleCard"):
			var single_card = button.get_node("SingleCard")


			# Connect SingleCard signals
			single_card.connect("card_clicked", Callable(self, "_on_single_card_clicked"))


# Lock all cards except the currently active one
# Lock all cards except the currently active one
func lock_cards(except_card = null):
	print("Locking cards...")
	for card_node in get_children():
		# Access the SingleCard node
		var single_card = card_node.get_node_or_null("SingleCard")
		if single_card:
			# Access the FaceDownExtraCard node within SingleCard
			var face_down_extra_card = single_card.get_node_or_null("FaceDownExtraCard")
			if face_down_extra_card:
				# Lock all cards unless an exception is provided
				if except_card:
					face_down_extra_card.disabled = (single_card != except_card)
					print("%s FaceDownExtraCard is %s." % [
						card_node.name,
						"locked" if face_down_extra_card.disabled else "unlocked"
					])
				else:
					face_down_extra_card.disabled = true  # Lock all cards
			else:
				print("Error: FaceDownExtraCard not found in:", card_node.name)
		else:
			print("Error: SingleCard not found for:", card_node.name)



func unlock_cards(grid):
	print("Unlocking cards...")
	for card_name in grid.keys():
		var card_info = grid[card_name]
		var single_card = card_info["node"]

		# Access FaceDownExtraCard
		var face_down_extra_card = single_card.get_node_or_null("FaceDownExtraCard")
		if not face_down_extra_card:
			print("Error: FaceDownExtraCard not found in:", card_name)
			continue

		# Skip destroyed cards
		if card_info["destroyed"]:
			face_down_extra_card.disabled = true
			print("%s remains locked (destroyed)." % card_name)
			continue

		# Use adjacency logic to determine if the card is interactable
		var is_interactable = is_card_interactable(card_name, grid)

		# Enable or disable the FaceDownExtraCard
		face_down_extra_card.disabled = not is_interactable
		print("%s is %s." % [card_name, "unlocked" if is_interactable else "locked"])


		# Optional: Add visual feedback
		single_card.modulate = Color(1, 1, 1) if is_interactable else Color(0.5, 0.5, 0.5)




func is_card_interactable(card_name: String, grid: Dictionary) -> bool:
	# Parse column and row numbers

	var col_str = card_name.split("_")[0].substr(1)  # Extract column number
	var row_str = card_name.split("_")[1].substr(1)           # Extract row number
	var col = col_str.to_int()
	var row = row_str.to_int()

	if row == 1:
		return true

	var adjacent_positions = [
		"C%d_R%d" % [col, row - 1],  # Above
		"C%d_R%d" % [col, row + 1],  # Below
		"C%d_R%d" % [col - 1, row],  # Left
		"C%d_R%d" % [col + 1, row]   # Right
	]

	for pos in adjacent_positions:
		if grid.has(pos) and grid[pos]["destroyed"]:
			return true  # Card is interactable if any neighbor is destroyed

	return false  # Card is blocked if no neighbors are destroyed


# Handle when a SingleCard is clicked
func _on_single_card_clicked(face_down_card, total_value: int):


	if control.battle_active:
		print("Battle already in progress. Ignoring click.")
		return



	# Set the clicked card as active and lock others
	active_card = face_down_card
	lock_cards(face_down_card)

	# Notify the game (Control.gd) to start the battle
	control.battle_active = true
	emit_signal("battle_started", face_down_card, total_value)


	emit_signal("card_clicked", face_down_card, total_value)
	# Set the clicked card as active and lock others

# Request a new card for the player
func request_player_hit():
	emit_signal("request_card")  # Ask Control.gd for a card

# Receive a card from Control.gd
func receive_card(new_card: int):
	print("Received new card:", new_card)
	# Assume the player node has a method to add a card
	$Player.add_card(new_card)

func _on_battle_ended():
	print("GridContainer: Battle ended. Resetting state.")
	unlock_cards(control.grid) 

