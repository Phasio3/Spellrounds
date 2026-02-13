extends CharacterBody2D

@export var speed: float = 150.0
@export var fireball_scene: PackedScene
@export var spell_bar_path: NodePath

var target_position: Vector2
var moving: bool = false
var is_holding_spell: bool = false
var spell_target_position: Vector2
var spell_keys = ["spell_a", "spell_z", "spell_e", "spell_r", "spell_q", "spell_s", "spell_d", "spell_f"]

var selected_spell_index: int = -1

@onready var direction_line: Line2D = $DirectionLine
@onready var spell_spawn_point: Marker2D = $SpellSpawnPoint
@onready var spell_indicator = $SpellIndicator
@onready var spell_bar = get_node(spell_bar_path)


func _ready():
	target_position = global_position
	direction_line.visible = false


func _process(_delta):
	var mouse_position = get_global_mouse_position()
	var dir = (mouse_position - global_position).normalized()

	spell_spawn_point.position = dir * 40.0

	if is_holding_spell:
		spell_target_position = mouse_position
		spell_indicator.global_position = global_position
		spell_indicator.rotation = dir.angle() + deg_to_rad(180)


func _input(event):

	# --- Déplacement ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()
			moving = true
			direction_line.visible = true

	# --- Sélection des spells ---
	for key in spell_keys:
		if event.is_action_pressed(key):
			select_spell(spell_keys.find(key))
		if event.is_action_released(key):
			deselect_spell()

	# --- Confirmation du cast ---
	if spell_bar.get_cooldown_remaining(selected_spell_index) <= 0.0:
		if event.is_action_pressed("spell_cast") and is_holding_spell:
			cast_spell(selected_spell_index)
			is_holding_spell = false
			spell_indicator.visible = false
			selected_spell_index = -1


func select_spell(index: int):
	selected_spell_index = index
	is_holding_spell = true
	spell_indicator.visible = true

func deselect_spell():
	selected_spell_index = -1
	is_holding_spell = false
	spell_indicator.visible = false


func cast_spell(index: int):
	if index < 0:
		return
	
	match index:
		0:
			cast_fireball()
		_:
			print("Spell non implémenté :", index)
	
	spell_bar.trigger_spell(index)


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


func cast_fireball():
	var fireball = fireball_scene.instantiate()

	var spawn_position = spell_spawn_point.global_position
	fireball.global_position = spawn_position

	var dir = (spell_target_position - spawn_position).normalized()
	fireball.direction = dir

	get_tree().current_scene.add_child(fireball)
