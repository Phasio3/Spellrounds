extends CharacterBody2D

@export var speed: float = 300.0

var target_position: Vector2
var moving: bool = false

func _ready():
	target_position = global_position

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()
			moving = true

func _physics_process(delta):
	if moving:
		var direction = target_position - global_position
		var distance = direction.length()

		if distance > 5:
			velocity = direction.normalized() * speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			moving = false
