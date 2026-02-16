extends Node

# ─────────────────────────────────────────
#  NETWORK MANAGER — Autoload Singleton
#  À enregistrer dans Projet > Paramètres du projet > Autoload
#  Nom : NetworkManager   Chemin : res://scripts/network_manager.gd
# ─────────────────────────────────────────

const PORT = 7777
const MAX_PLAYERS = 4

# Dictionnaire { peer_id: player_name }
var players: Dictionary = {}
var local_player_name: String = "Player"

signal player_connected(peer_id: int, player_name: String)
signal player_disconnected(peer_id: int)
signal server_disconnected
signal connection_failed
signal all_players_loaded


# ─────────────────────────────────────────
#  INITIALISATION
# ─────────────────────────────────────────

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ─────────────────────────────────────────
#  CRÉER UNE PARTIE (HÔTE)
# ─────────────────────────────────────────

func create_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		push_error("Impossible de créer le serveur : " + str(error))
		return

	multiplayer.multiplayer_peer = peer
	# L'hôte s'ajoute lui-même dans le dictionnaire (peer_id = 1)
	players[1] = local_player_name
	player_connected.emit(1, local_player_name)
	print("[NetworkManager] Serveur créé sur le port ", PORT)


# ─────────────────────────────────────────
#  REJOINDRE UNE PARTIE (CLIENT)
# ─────────────────────────────────────────

func join_server(address: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error != OK:
		push_error("Impossible de se connecter à " + address + " : " + str(error))
		return

	multiplayer.multiplayer_peer = peer
	print("[NetworkManager] Connexion à ", address, ":", PORT, "...")


# ─────────────────────────────────────────
#  DÉCONNEXION
# ─────────────────────────────────────────

func disconnect_from_game() -> void:
	players.clear()
	multiplayer.multiplayer_peer = null


# ─────────────────────────────────────────
#  CALLBACKS MULTIPLAYER
# ─────────────────────────────────────────

# Un nouveau peer vient de se connecter (appelé sur TOUS les pairs)
func _on_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] Peer connecté : ", peer_id)
	# On lui envoie notre nom pour qu'il nous connaisse
	_send_player_info.rpc_id(peer_id, local_player_name)


# Un peer s'est déconnecté
func _on_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] Peer déconnecté : ", peer_id)
	players.erase(peer_id)
	player_disconnected.emit(peer_id)


# Appelé côté CLIENT quand la connexion au serveur réussit
func _on_connected_to_server() -> void:
	print("[NetworkManager] Connecté au serveur ! Mon ID : ", multiplayer.get_unique_id())
	# On s'envoie nous-mêmes au serveur
	_send_player_info.rpc_id(1, local_player_name)


func _on_connection_failed() -> void:
	print("[NetworkManager] Échec de la connexion.")
	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("[NetworkManager] Serveur déconnecté.")
	players.clear()
	server_disconnected.emit()


# ─────────────────────────────────────────
#  RPCS INTERNES
# ─────────────────────────────────────────

# Échange de nom de joueur entre pairs
@rpc("any_peer", "reliable")
func _send_player_info(player_name: String) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	players[sender_id] = player_name
	player_connected.emit(sender_id, player_name)
	print("[NetworkManager] Joueur enregistré : ", sender_id, " -> ", player_name)


# L'hôte ordonne à tout le monde de charger la scène de jeu
@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	get_tree().change_scene_to_file("res://scenes/world.tscn")
