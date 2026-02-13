extends GridContainer

@export var spell_slot_scene : PackedScene
@export var spell_count : int = 8

var spell_slots : Array = []


func _ready():
	columns = 4
	_initialize_slots()


func _initialize_slots():
	for i in range(spell_count):
		var slot = spell_slot_scene.instantiate()
		add_child(slot)
		spell_slots.append(slot)


func set_spell(index: int, texture: Texture2D, key: String, cooldown: float):
	if index >= 0 and index < spell_slots.size():
		spell_slots[index].set_spell(texture, key, cooldown)


func trigger_spell(index: int):
	if index >= 0 and index < spell_slots.size():
		spell_slots[index].trigger_cooldown()
		#print("Cooldown triggered for : ", spell_slots[index], " at index : ", index)


func get_spell_slot(index: int):
	if index >= 0 and index < spell_slots.size():
		return spell_slots[index]
	return null

func get_cooldown_remaining(index: int) -> float:
	if index >= 0 and index < spell_slots.size():
		return spell_slots[index].cooldown_remaining
	return 0.0
