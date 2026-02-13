extends Control

@onready var icon = $Icon
@onready var cooldown_overlay = $CooldownOverlay
@onready var cooldown_text = $CooldownText

var cooldown_max : float = 0.0
var cooldown_remaining : float = 0.0


func _ready():
	custom_minimum_size = Vector2(50, 50)


func set_spell(texture: Texture2D, key: String, cooldown: float):
	icon.texture = texture
	$KeyLabel.text = key
	cooldown_max = cooldown
	cooldown_overlay.max_value = cooldown
	cooldown_overlay.value = 0
	cooldown_text.visible = false


func trigger_cooldown():
	cooldown_remaining = cooldown_max
	cooldown_overlay.value = cooldown_max
	cooldown_text.visible = true
	#print("I am ", self.name, " and I'm currently in a cooldown of ", cooldown_remaining, "s")


func _process(delta):
	if cooldown_remaining > 0:
		cooldown_remaining -= delta
		cooldown_overlay.value = cooldown_remaining
		cooldown_text.text = str(ceil(cooldown_remaining)) + "s"
		
		if cooldown_remaining <= 0:
			cooldown_remaining = 0
			cooldown_overlay.value = 0
			cooldown_text.visible = false
