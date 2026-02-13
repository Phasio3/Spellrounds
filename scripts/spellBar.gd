extends GridContainer

@export var spell_slot_scene : PackedScene
@export var spell_count : int = 8

var spell_slots : Array = []
var slots_key: Array = ["A","Z","E","R","Q","S","D","F"]

func _ready():
	columns = 4
	_initialize_slots()


func _initialize_slots():
	for i in range(spell_count):
		var slot = spell_slot_scene.instantiate()
		add_child(slot)
		slot.key = slots_key[i]
		spell_slots.append(slot)


func set_spell(spn: String, index: int, texture: Texture2D, cooldown: float):
	if index >= 0 and index < spell_slots.size():
		spell_slots[index].set_spell(spn, texture, cooldown)

func get_spell_name(index: int):
	return spell_slots[index].get_spell_name()

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
