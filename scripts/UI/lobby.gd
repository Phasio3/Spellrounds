extends CanvasLayer

# ─────────────────────────────────────────
#  LOBBY
#  Scène : res://scenes/UI/lobby.tscn
#  Structure de la scène :
#    CanvasLayer (script = lobby.gd)
#      └─ VBoxContainer (centré)
#           ├─ Label (titre)
#           ├─ LineEdit (name="NameInput")   ← nom du joueur
#           ├─ LineEdit (name="IPInput")     ← adresse IP
#           ├─ Button  (name="HostButton")   ← "Héberger"
#           ├─ Button  (name="JoinButton")   ← "Rejoindre"
#           ├─ Button  (name="StartButton")  ← "Lancer la partie" (hôte seulement)
#           └─ Label   (name="StatusLabel")  ← feedback
# ─────────────────────────────────────────

@onready var name_input: LineEdit    = $VBoxContainer/NameInput
@onready var ip_input: LineEdit      = $VBoxContainer/IPInput
@onready var host_button: Button     = $VBoxContainer/HostButton
@onready var join_button: Button     = $VBoxContainer/JoinButton
@onready var start_button: Button    = $VBoxContainer/StartButton
@onready var status_label: Label     = $VBoxContainer/StatusLabel
@onready var players_list: VBoxContainer = $VBoxContainer/PlayersList


func _ready() -> void:
	start_button.visible = false

	# Connexion des signaux du NetworkManager
	NetworkManager.player_connected.connect(_on_player_connected)
	NetworkManager.player_disconnected.connect(_on_player_disconnected)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	NetworkManager.server_disconnected.connect(_on_server_disconnected)

	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	start_button.pressed.connect(_on_start_pressed)

	# Valeurs par défaut
	ip_input.text = "127.0.0.1"
	name_input.text = "Player"


# ─────────────────────────────────────────
#  BOUTONS
# ─────────────────────────────────────────

func _on_host_pressed() -> void:
	_apply_name()
	NetworkManager.create_server()
	status_label.text = "En attente de joueurs... (port %d)" % NetworkManager.PORT
	host_button.disabled = true
	join_button.disabled = true
	start_button.visible = true
	_refresh_players_list()


func _on_join_pressed() -> void:
	_apply_name()
	var address = ip_input.text.strip_edges()
	if address.is_empty():
		status_label.text = "Entrez une adresse IP valide."
		return
	NetworkManager.join_server(address)
	status_label.text = "Connexion à %s..." % address
	host_button.disabled = true
	join_button.disabled = true


func _on_start_pressed() -> void:
	# Seul l'hôte peut lancer
	if not multiplayer.is_server():
		return
	if NetworkManager.players.size() < 1:
		status_label.text = "Aucun joueur connecté."
		return
	NetworkManager.start_game.rpc()


# ─────────────────────────────────────────
#  CALLBACKS RÉSEAU
# ─────────────────────────────────────────

func _on_player_connected(peer_id: int, player_name: String) -> void:
	status_label.text = "%s a rejoint la partie !" % player_name
	_refresh_players_list()


func _on_player_disconnected(peer_id: int) -> void:
	status_label.text = "Un joueur s'est déconnecté."
	_refresh_players_list()


func _on_connection_failed() -> void:
	status_label.text = "Échec de la connexion."
	host_button.disabled = false
	join_button.disabled = false


func _on_server_disconnected() -> void:
	status_label.text = "Déconnecté du serveur."
	host_button.disabled = false
	join_button.disabled = false


# ─────────────────────────────────────────
#  UTILITAIRES
# ─────────────────────────────────────────

func _apply_name() -> void:
	var n = name_input.text.strip_edges()
	if not n.is_empty():
		NetworkManager.local_player_name = n


func _refresh_players_list() -> void:
	# Vide la liste et la recrée
	for child in players_list.get_children():
		child.queue_free()
	for id in NetworkManager.players:
		var lbl = Label.new()
		lbl.text = "• [%d] %s" % [id, NetworkManager.players[id]]
		players_list.add_child(lbl)
