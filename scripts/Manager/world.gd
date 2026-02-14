extends Node2D

# ─────────────────────────────────────────
#  WORLD MANAGER
#  Scène : res://scenes/world.tscn
#
#  Structure de la scène :
#    Node2D  (script = world.gd)
#      ├─ Camera2D    (script = camera_manager.gd)
#      ├─ CanvasLayer (spellBar.tscn)
#      └─ Dummy       (instance dummy.tscn, placé dans l'éditeur)
#
#  FLUX DE SPAWN (un seul chemin, pas de double logique) :
#
#  Serveur (ready)  → _spawn_player() pour chaque peer connu
#                   → _rpc_do_spawn.rpc() pour broadcaster à tous les clients
#
#  Client (ready)   → attend passivement
#                   → reçoit _rpc_do_spawn() → spawne le joueur indiqué
#
#  Le serveur est la SEULE source de vérité pour les spawns.
# ─────────────────────────────────────────

@export var player_scene: PackedScene
@export var spawn_points: Array[NodePath] = []

const DEFAULT_SPAWN_POSITIONS = [
	Vector2(200, 300),
	Vector2(800, 300),
	Vector2(200, 500),
	Vector2(800, 500),
]


func _ready() -> void:
	# ── Solo ──────────────────────────────────────────────────────────────────
	if not multiplayer.has_multiplayer_peer():
		_spawn_player(1, 0)
		return

	# ── Multijoueur ───────────────────────────────────────────────────────────
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	if multiplayer.is_server():
		# Le serveur spawn tout le monde (lui compris) et l'annonce à tous
		var keys = NetworkManager.players.keys()
		for i in keys.size():
			var pid = keys[i]
			_spawn_player(pid, i)
			# Broadcaster à tous les clients (call_local=false donc serveur exclu)
			_rpc_do_spawn.rpc(pid, i)
	# Les clients n'font RIEN dans _ready() — ils attendent les RPC du serveur


# ─────────────────────────────────────────
#  RPC UNIQUE DE SPAWN : Serveur → Clients
# ─────────────────────────────────────────

# "authority" = seul le serveur peut émettre ce RPC
# "call_remote" = n'est PAS exécuté sur le serveur (il spawne déjà dans _ready)
# "reliable" = garanti, dans l'ordre
@rpc("authority", "call_remote", "reliable")
func _rpc_do_spawn(peer_id: int, spawn_index: int) -> void:
	_spawn_player(peer_id, spawn_index)


# ─────────────────────────────────────────
#  SPAWN LOCAL
# ─────────────────────────────────────────

func _spawn_player(peer_id: int, spawn_index: int) -> void:
	if get_node_or_null(str(peer_id)) != null:
		push_warning("[World] Double-spawn ignoré pour peer %d" % peer_id)
		return

	var player = player_scene.instantiate()
	player.name = str(peer_id)

	# CRITIQUE : autorité assignée AVANT add_child
	# → _ready() du joueur verra is_multiplayer_authority() correct
	player.set_multiplayer_authority(peer_id)
	player.global_position = _get_spawn_position(spawn_index)

	add_child(player)

	# Déterminer si c'est le joueur local
	var my_id: int = multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else 1
	var is_local: bool = (peer_id == my_id)

	print("[World] Spawné peer=%d  authority=%d  my_id=%d  is_local=%s" % [
		peer_id,
		player.get_multiplayer_authority(),
		my_id,
		str(is_local)
	])

	if is_local:
		# call_deferred pour garantir que le nœud est dans le tree avant setup
		call_deferred("_setup_local_player", player)


func _get_spawn_position(index: int) -> Vector2:
	if index < spawn_points.size():
		var m = get_node_or_null(spawn_points[index])
		if m:
			return m.global_position
	if index < DEFAULT_SPAWN_POSITIONS.size():
		return DEFAULT_SPAWN_POSITIONS[index]
	return Vector2(400, 400)


# ─────────────────────────────────────────
#  SETUP JOUEUR LOCAL (caméra + spellbar)
# ─────────────────────────────────────────

func _setup_local_player(player: Node2D) -> void:
	print("[World] _setup_local_player() pour peer=%s" % player.name)

	# ── SpellBar ──────────────────────────────────────────────────────────────
	var spell_bar = get_node_or_null("CanvasLayer")
	if spell_bar:
		if player.has_method("set_spell_bar"):
			player.set_spell_bar(spell_bar)
		var texture: Texture2D = load("res://assets/icon.svg")
		spell_bar.set_spell("Fireball", 0, texture, 5.0)
		spell_bar.set_spell("SnowBall", 3, texture, 10.0)
	else:
		push_warning("[World] CanvasLayer (spellBar) introuvable !")

	# ── Caméra ────────────────────────────────────────────────────────────────
	var camera = get_node_or_null("Camera2D")
	if camera:
		camera.player = player
		print("[World] Caméra assignée à peer=%s" % player.name)
	else:
		push_warning("[World] Camera2D introuvable !")


# ─────────────────────────────────────────
#  SPAWN PROJECTILES
#  Appelé par player.gd (local ou distant).
#  World a toujours authority=1 (serveur) → pas de problème de permissions RPC.
# ─────────────────────────────────────────

# Point d'entrée appelé par le joueur LOCAL (hôte ou client)
func spawn_projectile(scene: PackedScene, spawn_pos: Vector2, dir: Vector2) -> void:
	if not multiplayer.has_multiplayer_peer():
		# Solo
		_do_spawn_projectile(scene.resource_path, spawn_pos, dir)
	elif multiplayer.is_server():
		# Hôte : spawn local + broadcast aux clients
		_do_spawn_projectile(scene.resource_path, spawn_pos, dir)
		_rpc_spawn_projectile.rpc(scene.resource_path, spawn_pos, dir)
	else:
		# Client : demander au serveur via RPC
		_rpc_request_projectile.rpc_id(1, scene.resource_path, spawn_pos, dir)


# Client → Serveur : demande de spawn
@rpc("any_peer", "call_remote", "reliable")
func _rpc_request_projectile(scene_path: String, spawn_pos: Vector2, dir: Vector2) -> void:
	# Spawn côté serveur
	_do_spawn_projectile(scene_path, spawn_pos, dir)
	# Broadcast à tous les clients
	_rpc_spawn_projectile.rpc(scene_path, spawn_pos, dir)


# Serveur → Tous les clients
@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_projectile(scene_path: String, spawn_pos: Vector2, dir: Vector2) -> void:
	_do_spawn_projectile(scene_path, spawn_pos, dir)


# Spawn effectif, exécuté sur chaque machine
func _do_spawn_projectile(scene_path: String, spawn_pos: Vector2, dir: Vector2) -> void:
	var scene = load(scene_path) as PackedScene
	if scene == null:
		push_error("[World] Impossible de charger la scène : " + scene_path)
		return
	var projectile = scene.instantiate()
	projectile.global_position = spawn_pos
	projectile.direction = dir
	add_child(projectile)


# ─────────────────────────────────────────
#  DÉCONNEXION
# ─────────────────────────────────────────

func _on_peer_disconnected(peer_id: int) -> void:
	var node = get_node_or_null(str(peer_id))
	if node:
		node.queue_free()
		print("[World] Joueur supprimé : peer=%d" % peer_id)
