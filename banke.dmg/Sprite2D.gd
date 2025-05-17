extends Sprite2D

var card_width = 33.052  # Width of a single card in the sprite sheet (in pixels)
var card_height = 44.686  # Height of a single card in the sprite sheet (in pixels)
var columns = 13  # Number of columns in the sprite sheet
var rows = 4  # Number of rows in the sprite sheet (assuming 52 cards)

# Function to set the card sprite based on an index
func set_card_sprite(card_index: int):
	# Calculate row and column based on card index
	var row = card_index / columns
	var column = card_index % columns
	
	# Set region rect to the correct position and size
	var region_position = Vector2(column * card_width, row * card_height)
	var region_size = Vector2(card_width, card_height)
	
	# Enable region and set the region rect
	region_enabled = true
	region_rect = Rect2(region_position, region_size)
