extends Camera2D

# ─────────────────────────────────────────
#  PARAMÈTRES CONFIGURABLES DANS L'INSPECTEUR
# ─────────────────────────────────────────

## Référence au nœud joueur (glisse ton joueur ici dans l'inspecteur)
@export var player: Node2D

## Vitesse de déplacement de la caméra au scroll de bordure
@export var pan_speed: float = 600.0

## Épaisseur de la zone de détection en bordure d'écran (px)
@export var edge_margin: int = 20

## Zoom minimum (dézoom maximum)
@export var zoom_min: float = 0.5

## Zoom maximum (zoom maximum)
@export var zoom_max: float = 2.0

## Vitesse d'interpolation du zoom
@export var zoom_speed: float = 8.0

## Incrément de zoom par molette
@export var zoom_step: float = 0.1

## Vitesse d'interpolation lors du recentrage sur le joueur (Espace)
@export var recenter_speed: float = 10.0

## Limites de déplacement de la caméra dans le monde
## Laisser à 0 pour désactiver les limites (ou les définir selon ta carte)
@export var world_limit_left: float   = -2000.0
@export var world_limit_right: float  =  2000.0
@export var world_limit_top: float    = -2000.0
@export var world_limit_bottom: float =  2000.0

## Activer / désactiver le pan de bordure
@export var edge_pan_enabled: bool = true

## Vitesse du pan à la molette (clic molette maintenu)
@export var middle_pan_speed: float = 1.5

# ─────────────────────────────────────────
#  VARIABLES INTERNES
# ─────────────────────────────────────────

var _target_zoom: float = 1.0
var _is_recentering: bool = false
var _middle_mouse_panning: bool = false
var _middle_mouse_origin: Vector2 = Vector2.ZERO
var _camera_origin: Vector2 = Vector2.ZERO

# ─────────────────────────────────────────
#  INITIALISATION
# ─────────────────────────────────────────

func _ready() -> void:
	# On part du zoom actuel défini dans l'inspecteur
	_target_zoom = zoom.x
	# La caméra ne suit pas automatiquement le joueur
	# Elle est en position fixe et se déplace manuellement


# ─────────────────────────────────────────
#  BOUCLE PRINCIPALE
# ─────────────────────────────────────────

func _process(delta: float) -> void:
	_handle_zoom(delta)
	_handle_recenter(delta)
	_handle_middle_mouse_pan()

	# Le pan de bordure ne s'active que si on ne recentre pas activement
	# et qu'on n'est pas en train de pan à la molette
	if not _is_recentering and edge_pan_enabled and not _middle_mouse_panning:
		_handle_edge_pan(delta)

	_apply_world_limits()


# ─────────────────────────────────────────
#  GESTION DES INPUTS (molette + espace)
# ─────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	# Zoom molette
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_target_zoom = clamp(_target_zoom + zoom_step, zoom_min, zoom_max)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_target_zoom = clamp(_target_zoom - zoom_step, zoom_min, zoom_max)

		# Clic molette maintenu → pan
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_middle_mouse_panning = true
				_middle_mouse_origin = get_viewport().get_mouse_position()
				_camera_origin = global_position
				_is_recentering = false
				Input.set_default_cursor_shape(Input.CURSOR_MOVE)
			else:
				_middle_mouse_panning = false
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	# Recentrage sur le joueur (Espace)
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_SPACE:
			if player:
				_is_recentering = true


# ─────────────────────────────────────────
#  PAN À LA MOLETTE (clic molette maintenu)
# ─────────────────────────────────────────

func _handle_middle_mouse_pan() -> void:
	if not _middle_mouse_panning:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var delta_mouse: Vector2 = mouse_pos - _middle_mouse_origin

	# On déplace la caméra en sens inverse du mouvement de souris,
	# compensé par le zoom pour que la vitesse reste cohérente
	global_position = _camera_origin - delta_mouse * middle_pan_speed * (1.0 / zoom.x)


# ─────────────────────────────────────────
#  PAN DE BORDURE (style LoL)
# ─────────────────────────────────────────

func _handle_edge_pan(delta: float) -> void:
	return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var screen_size: Vector2 = get_viewport_rect().size
	var direction: Vector2 = Vector2.ZERO

	# Détection des 4 bordures
	if mouse_pos.x < edge_margin:
		direction.x = -1.0
	elif mouse_pos.x > screen_size.x - edge_margin:
		direction.x = 1.0

	if mouse_pos.y < edge_margin:
		direction.y = -1.0
	elif mouse_pos.y > screen_size.y - edge_margin:
		direction.y = 1.0

	if direction != Vector2.ZERO:
		# On normalise pour éviter une vitesse diagonale plus rapide
		# puis on compense selon le zoom actuel pour garder une vitesse visuelle constante
		global_position += direction.normalized() * pan_speed * delta * (1.0 / zoom.x)


# ─────────────────────────────────────────
#  RECENTRAGE SUR LE JOUEUR (Espace)
# ─────────────────────────────────────────

func _handle_recenter(delta: float) -> void:
	if not _is_recentering or not player:
		return

	# Interpolation fluide vers la position du joueur
	global_position = global_position.lerp(player.global_position, recenter_speed * delta)

	# On arrête le recentrage quand on est suffisamment proche
	if global_position.distance_to(player.global_position) < 2.0:
		global_position = player.global_position
		_is_recentering = false


# ─────────────────────────────────────────
#  ZOOM FLUIDE
# ─────────────────────────────────────────

func _handle_zoom(delta: float) -> void:
	var current_zoom: float = zoom.x
	var new_zoom: float = lerp(current_zoom, _target_zoom, zoom_speed * delta)
	zoom = Vector2(new_zoom, new_zoom)


# ─────────────────────────────────────────
#  LIMITES DU MONDE
# ─────────────────────────────────────────

func _apply_world_limits() -> void:
	# Optionnel : ne clamp que si les limites sont différentes de zéro sur les deux axes
	var use_limits: bool = not (
		world_limit_left == 0 and world_limit_right == 0 and
		world_limit_top == 0 and world_limit_bottom == 0
	)
	if not use_limits:
		return

	global_position.x = clamp(global_position.x, world_limit_left, world_limit_right)
	global_position.y = clamp(global_position.y, world_limit_top, world_limit_bottom)
