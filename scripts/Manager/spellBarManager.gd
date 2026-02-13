extends CanvasLayer

@onready var grid = $RootUI/MarginContainer/SpellBar

func trigger_spell(index: int):
	grid.trigger_spell(index)

func set_spell(index: int, texture: Texture2D, key: String, cooldown: float):
	grid.set_spell(index, texture, key, cooldown)

func get_cooldown_remaining(index: int) -> float:
	return grid.get_cooldown_remaining(index)
