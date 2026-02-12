extends Area2D

@export var max_hp: int = 100
var current_hp: int

# Pour la barre de vie
@onready var health_bar: TextureProgressBar = $HealthBar

func _ready():
	current_hp = max_hp
	# Créons la barre si elle n'existe pas déjà
	if not health_bar:
		health_bar = TextureProgressBar.new()
		add_child(health_bar)
		health_bar.position = Vector2(0, -40)  # au-dessus de la tête
		health_bar.min_value = 0
		health_bar.max_value = max_hp
		health_bar.value = current_hp

	health_bar.visible = false  # invisible tant qu'il n'est pas touché

func take_damage(amount: int):
	current_hp -= amount
	current_hp = max(current_hp, 0)
	
	# Mettre à jour la barre
	health_bar.value = current_hp
	health_bar.visible = true
	
	if current_hp <= 0:
		queue_free()  # dummy "meurt"
