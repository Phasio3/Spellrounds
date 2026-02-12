extends Area2D

@export var speed: float = 500.0
@export var lifetime: float = 1.0
@export var damage: int = 10  # dégâts infligés

var direction: Vector2 = Vector2.ZERO

func _ready():
	direction = direction.normalized()
	connect("area_entered", Callable(self, "_on_area_entered"))
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
		queue_free()  # la fireball disparaît après le hit

func _physics_process(delta):
	position += direction * speed * delta
