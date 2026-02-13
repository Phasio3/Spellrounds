extends Node2D

@onready var spell_bar_manager = $CanvasLayer

func _ready():
	var texture: Texture2D = load("res://assets/icon.svg")
	var spn: String = "Fireball"
	test_set_spell(spn, texture)

func test_set_spell(spn: String, texture: Texture2D):
	if spell_bar_manager:
		var cooldown = 5.0
		var index = 0
		spell_bar_manager.set_spell(spn, index, texture, cooldown)
		cooldown = 10.0
		index = 3
		spell_bar_manager.set_spell("SnowBall", index, texture, cooldown)
	else:
		print("SpellBarManager non assigné !")
