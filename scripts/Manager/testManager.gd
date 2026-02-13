extends Node2D

@onready var spell_bar_manager = $CanvasLayer

func _ready():
	var texture: Texture2D = load("res://assets/icon.svg")
	test_set_spell(texture)

func test_set_spell(texture: Texture2D):
	if spell_bar_manager:
		var key = "A"
		var cooldown = 5.0
		var index = 0
		spell_bar_manager.set_spell(index, texture, key, cooldown)
		key = "Z"
		cooldown = 10.0
		index = 1
		spell_bar_manager.set_spell(index, texture, key, cooldown)
	else:
		print("SpellBarManager non assigné !")
