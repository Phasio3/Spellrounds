extends CharacterBody2D

@export var speed: float = 150.0
@export var fireball_scene: PackedScene

var target_position: Vector2
var moving: bool = false

@onready var direction_line: Line2D = $DirectionLine
@onready var spell_spawn_point: Marker2D = $SpellSpawnPoint

func _ready():
	target_position = global_position
	direction_line.visible = false

func _process(delta):
	var mouse_position = get_global_mouse_position()
	var dir = (mouse_position - global_position).normalized()
	spell_spawn_point.position = dir * 40.0


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()
			moving = true
			direction_line.visible = true
	if event.is_action_pressed("spell_a"):
		cast_fireball()

func _physics_process(delta):
	if moving:
		var direction = target_position - global_position
		var distance = direction.length()

		if distance > 5:
			var dir_norm = direction.normalized()
			velocity = dir_norm * speed
			move_and_slide()
			update_direction_line(dir_norm, distance)
		else:
			velocity = Vector2.ZERO
			moving = false
			direction_line.visible = false

func update_direction_line(direction: Vector2, distance: float):
	direction_line.clear_points()
	direction_line.add_point(Vector2.ZERO)
	direction_line.add_point(direction * distance)


func cast_fireball():
	var fireball = fireball_scene.instantiate()
	
	var mouse_position = get_global_mouse_position()
	var dir = (mouse_position - spell_spawn_point.global_position).normalized()
	
	fireball.global_position = spell_spawn_point.global_position
	fireball.direction = dir
	
	get_tree().current_scene.add_child(fireball)
