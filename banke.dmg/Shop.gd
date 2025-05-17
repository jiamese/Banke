extends Control

@onready var currency_label = $VBoxContainer/CurrencyDisp
@onready var insight_button = $VBoxContainer/InsightBuy
@onready var joker_button = $VBoxContainer/JokerBuy
@onready var insurance_button = $VBoxContainer/InsuranceBuy
@onready var continue_button = $VBoxContainer/ContinueButton

# References to main game variables
var player_currency
var purchased_power_ups

func _ready():
	update_currency_display()
	update_buttons_state()

	insight_button.pressed.connect(_on_insight_purchased)
	joker_button.pressed.connect(_on_joker_purchased)
	insurance_button.pressed.connect(_on_insurance_purchased)
	continue_button.pressed.connect(_on_continue_pressed)

func _on_insight_purchased():
	if player_currency >= 10:  # Example cost
		player_currency -= 10
		purchased_power_ups["insight"] = true
		update_currency_display()
		update_buttons_state()
	else:
		print("Not enough gold for Insight!")

func _on_joker_purchased():
	if player_currency >= 15:  # Example cost
		player_currency -= 15
		purchased_power_ups["joker"] = true
		update_currency_display()
		update_buttons_state()
	else:
		print("Not enough gold for Joker!")

func _on_insurance_purchased():
	if player_currency >= 5:  # Example cost
		player_currency -= 5
		purchased_power_ups["insurance"] = true
		update_currency_display()
		update_buttons_state()
	else:
		print("Not enough gold for Insurance!")

func _on_continue_pressed():
	# Return to the game scene and pass back player data
	get_tree().change_scene_to_file("res://GameScene.tscn")  # Adjust path
	get_tree().root.get_child(0).set_player_data(player_currency, purchased_power_ups)

func update_currency_display():
	if currency_label:
		currency_label.text = "Gold: " + str(player_currency)
	else:
		print("Error: CurrencyLabel node not found or path is incorrect!")
		print(currency_label)
func update_buttons_state():
	insight_button.disabled = purchased_power_ups["insight"]
	joker_button.disabled = purchased_power_ups["joker"]
	insurance_button.disabled = purchased_power_ups["insurance"]

func set_player_data(currency, power_ups):
	player_currency = currency
	purchased_power_ups = power_ups
	update_currency_display()
	update_buttons_state()
