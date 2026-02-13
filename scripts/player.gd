extends CharacterBody2D

@export var speed: float = 150.0
@export var fireball_scene: PackedScene

var target_position: Vector2
var moving: bool = false
var is_holding_spell: bool = false
var spell_target_position: Vector2

@onready var direction_line: Line2D = $DirectionLine
@onready var spell_spawn_point: Marker2D = $SpellSpawnPoint
@onready var spell_indicator = $SpellIndicator

func _ready():
	target_position = global_position
	direction_line.visible = false

func _process(_delta):
	var mouse_position = get_global_mouse_position()
	var dir = (mouse_position - global_position).normalized()
	
	# Déplacer le point de spawn devant le joueur
	spell_spawn_point.position = dir * 40.0
	
	if is_holding_spell:
		spell_target_position = mouse_position
		
		# L'indicateur reste centré sur le joueur
		spell_indicator.global_position = global_position
		
		# Il tourne vers la souris
		spell_indicator.rotation = dir.angle() + deg_to_rad(180)



func _input(event):
	# --- Déplacement clic droit (inchangé) ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()
			moving = true
			direction_line.visible = true

	# --- Début du maintien ---
	if event.is_action_pressed("spell_a"):
		is_holding_spell = true
		spell_indicator.visible = true

	# --- Relâchement → annulation ---
	if event.is_action_released("spell_a"):
		is_holding_spell = false
		spell_indicator.visible = false

	# --- Confirmation du cast ---
	if event.is_action_pressed("spell_cast") and is_holding_spell:
		cast_fireball()
		is_holding_spell = false
		spell_indicator.visible = false


func _physics_process(_delta):
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

func show_spell_preview():
	spell_indicator.visible = true

func hide_spell_preview():
	spell_indicator.visible = false


func cast_fireball():
	var fireball = fireball_scene.instantiate()
	
	var spawn_position = spell_spawn_point.global_position
	fireball.global_position = spawn_position
	
	var dir = (spell_target_position - spawn_position).normalized()
	fireball.direction = dir
	
	get_tree().current_scene.add_child(fireball)
