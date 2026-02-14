extends CharacterBody2D

# ─────────────────────────────────────────
#  PLAYER — Multijoueur High-Level Godot 4
# ─────────────────────────────────────────

@export var speed: float = 150.0
@export var fireball_scene: PackedScene

var spell_bar = null

var target_position: Vector2
var moving: bool = false
var is_holding_spell: bool = false
var spell_target_position: Vector2
var spell_keys = ["spell_a", "spell_z", "spell_e", "spell_r", "spell_q", "spell_s", "spell_d", "spell_f"]
var spells: Dictionary = {}
var selected_spell_index: int = -1

@onready var direction_line: Line2D              = $DirectionLine
@onready var spell_spawn_point: Marker2D         = $SpellSpawnPoint
@onready var spell_indicator                     = $SpellIndicator
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


# ─────────────────────────────────────────
#  INITIALISATION
# ─────────────────────────────────────────

func _ready() -> void:
	target_position = global_position
	direction_line.visible = false
	spell_indicator.visible = false
	_load_spells_from_json("res://data/spells.json")

	# Le synchronizer doit avoir la même autorité que son joueur parent
	synchronizer.set_multiplayer_authority(get_multiplayer_authority())

	print("[Player] _ready()  name=%s  authority=%d  my_peer=%d  is_local=%s" % [
		name,
		get_multiplayer_authority(),
		multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1,
		str(is_local_player())
	])


# ─────────────────────────────────────────
#  HELPER : suis-je le joueur local ?
# ─────────────────────────────────────────

func is_local_player() -> bool:
	# Sans réseau : toujours local
	if not multiplayer.has_multiplayer_peer():
		return true
	# Avec réseau : vrai si ce nœud m'appartient
	return is_multiplayer_authority()


# ─────────────────────────────────────────
#  SETTER spell_bar (appelé par world.gd)
# ─────────────────────────────────────────

func set_spell_bar(bar) -> void:
	spell_bar = bar
	print("[Player] spell_bar assignée à peer=%s" % name)


# ─────────────────────────────────────────
#  PROCESS (local seulement)
# ─────────────────────────────────────────

func _process(_delta):
	if not is_local_player():
		return

	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	spell_spawn_point.position = dir * 40.0

	if is_holding_spell:
		spell_target_position = mouse_pos
		spell_indicator.global_position = global_position
		spell_indicator.rotation = dir.angle() + deg_to_rad(180)


# ─────────────────────────────────────────
#  INPUT (local seulement)
# ─────────────────────────────────────────

func _input(event):
	if not is_local_player():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()
			moving = true
			direction_line.visible = true

	for key in spell_keys:
		if event.is_action_pressed(key):
			select_spell(spell_keys.find(key))
		if event.is_action_released(key):
			deselect_spell()

	if spell_bar == null:
		return
	if spell_bar.get_cooldown_remaining(selected_spell_index) <= 0.0:
		if event.is_action_pressed("spell_cast") and is_holding_spell:
			cast_spell(selected_spell_index)
			is_holding_spell = false
			spell_indicator.visible = false
			selected_spell_index = -1


# ─────────────────────────────────────────
#  PHYSIQUE (local seulement)
# ─────────────────────────────────────────

func _physics_process(_delta):
	if not is_local_player():
		return

	if moving:
		var direction = target_position - global_position
		var distance = direction.length()
		if distance > 5:
			velocity = direction.normalized() * speed
			move_and_slide()
			_update_direction_line(direction.normalized(), distance)
		else:
			velocity = Vector2.ZERO
			moving = false
			direction_line.visible = false


func _update_direction_line(direction: Vector2, distance: float) -> void:
	direction_line.clear_points()
	direction_line.add_point(Vector2.ZERO)
	direction_line.add_point(direction * distance)


# ─────────────────────────────────────────
#  SPELLS
# ─────────────────────────────────────────

func select_spell(index: int) -> void:
	if spell_bar == null:
		return
	var spell_name = spell_bar.get_spell_name(index)
	if spell_name == "" or spell_name not in spells:
		return
	selected_spell_index = index
	is_holding_spell = true
	spell_indicator.visible = true
	if spells[spell_name].has("indicator_texture"):
		spell_indicator.texture = spells[spell_name]["indicator_texture"]


func deselect_spell() -> void:
	selected_spell_index = -1
	is_holding_spell = false
	spell_indicator.visible = false


func cast_spell(index: int) -> void:
	if spell_bar == null:
		return
	var spell_name = spell_bar.get_spell_name(index)
	if spell_name == "" or spell_name not in spells:
		return
	var spell = spells[spell_name]
	if spell.has("cast_func"):
		spell["cast_func"].call()
	spell_bar.trigger_spell(index)


# ─────────────────────────────────────────
#  CAST FIREBALL
#  Délégation à world.gd (authority=serveur).
#  Les RPCs sur un nœud dont l'authority est un client posent
#  des problèmes de permissions → on délègue au nœud world
#  qui appartient toujours au serveur.
# ─────────────────────────────────────────

func cast_fireball() -> void:
	var spawn_pos = spell_spawn_point.global_position
	var dir = (spell_target_position - spawn_pos).normalized()
	var world = get_tree().current_scene
	if world and world.has_method("spawn_projectile"):
		world.spawn_projectile(fireball_scene, spawn_pos, dir)
	else:
		push_error("[Player] spawn_projectile() introuvable dans world !")


# ─────────────────────────────────────────
#  CHARGEMENT JSON
# ─────────────────────────────────────────

func _load_spells_from_json(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Impossible d'ouvrir spells.json")
		return
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("Erreur parsing spells.json")
		return
	for entry in data:
		spells[entry["name"]] = {
			"scene":               load(entry["scene_path"]),
			"indicator_texture":   load(entry["indicator_texture_path"]),
			"cast_func":           Callable(self, entry["cast_func"])
		}
