extends CanvasLayer

@onready var grid = $RootUI/MarginContainer/SpellBar

func trigger_spell(index: int):
	grid.trigger_spell(index)

func set_spell(spn: String, index: int, texture: Texture2D, cooldown: float):
	grid.set_spell(spn, index, texture, cooldown)

func get_cooldown_remaining(index: int) -> float:
	return grid.get_cooldown_remaining(index)

func get_spell_name(index: int):
	return grid.get_spell_name(index)
